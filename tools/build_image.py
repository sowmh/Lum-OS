from __future__ import annotations
import argparse
import math
import struct
from pathlib import Path
BYTES_PER_SECTOR = 512
TOTAL_SECTORS = 2880
RESERVED_SECTORS = 1
FAT_COUNT = 2
SECTORS_PER_FAT = 9
ROOT_DIR_ENTRIES = 224
ROOT_DIR_SECTORS = math.ceil(ROOT_DIR_ENTRIES * 32 / BYTES_PER_SECTOR)
DATA_START_SECTOR = RESERVED_SECTORS + (FAT_COUNT * SECTORS_PER_FAT) + ROOT_DIR_SECTORS
EXTRA_TEXT_FILES = {
    "README.TXT": (
        "Lum-OS cached README\n"
        "This text file is loaded by stage2 into RAM so the protected-mode shell can read it.\n"
        "Try: files, cat README.TXT, cat STATUS.TXT\n"
    ).encode("ascii"),
    "STATUS.TXT": (
        "Lum-OS status\n"
        "Boot, interrupts, paging, heap, and shell diagnostics are online.\n"
        "Next big areas are richer filesystem support, user-space foundations, and scheduling.\n"
    ).encode("ascii"),
}
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create a bootable FAT12 floppy image for Lum-OS.")
    parser.add_argument("--boot", required=True, type=Path, help="512-byte stage1 boot sector")
    parser.add_argument("--stage2", required=True, type=Path, help="stage2 binary")
    parser.add_argument("--kernel", required=True, type=Path, help="kernel binary")
    parser.add_argument("--output", required=True, type=Path, help="output floppy image path")
    return parser.parse_args()
def read_file(path: Path) -> bytes:
    data = path.read_bytes()
    if not data:
        raise ValueError(f"{path} is empty")
    return data
def to_fat_name(filename: str) -> bytes:
    path = Path(filename)
    stem = path.stem.upper().encode("ascii")
    suffix = path.suffix.upper().lstrip(".").encode("ascii")
    if len(stem) > 8 or len(suffix) > 3:
        raise ValueError(f"{filename} does not fit FAT12 8.3 naming")
    return stem.ljust(8, b" ") + suffix.ljust(3, b" ")
def set_fat12_entry(fat: bytearray, cluster: int, value: int) -> None:
    offset = (cluster * 3) // 2
    if cluster & 1:
        fat[offset] = (fat[offset] & 0x0F) | ((value << 4) & 0xF0)
        fat[offset + 1] = (value >> 4) & 0xFF
    else:
        fat[offset] = value & 0xFF
        fat[offset + 1] = (fat[offset + 1] & 0xF0) | ((value >> 8) & 0x0F)
def write_root_entry(directory: bytearray, slot: int, name: str, start_cluster: int, size: int) -> None:
    entry = bytearray(32)
    entry[0:11] = to_fat_name(name)
    entry[11] = 0x20
    struct.pack_into("<H", entry, 26, start_cluster)
    struct.pack_into("<I", entry, 28, size)
    offset = slot * 32
    directory[offset : offset + 32] = entry
def allocate_file(
    image: bytearray,
    fat: bytearray,
    directory: bytearray,
    slot: int,
    name: str,
    data: bytes,
    next_cluster: int,
) -> int:
    clusters_needed = math.ceil(len(data) / BYTES_PER_SECTOR)
    start_cluster = next_cluster
    current_cluster = start_cluster
    for index in range(clusters_needed):
        chunk = data[index * BYTES_PER_SECTOR : (index + 1) * BYTES_PER_SECTOR]
        sector = DATA_START_SECTOR + (current_cluster - 2)
        offset = sector * BYTES_PER_SECTOR
        image[offset : offset + BYTES_PER_SECTOR] = chunk.ljust(BYTES_PER_SECTOR, b"\x00")
        is_last = index == clusters_needed - 1
        set_fat12_entry(fat, current_cluster, 0x0FFF if is_last else current_cluster + 1)
        current_cluster += 1
    write_root_entry(directory, slot, name, start_cluster, len(data))
    return next_cluster + clusters_needed
def build_image(boot_sector: bytes, stage2: bytes, kernel: bytes) -> bytearray:
    if len(boot_sector) != BYTES_PER_SECTOR:
        raise ValueError("stage1 boot sector must be exactly 512 bytes")
    if boot_sector[510:512] != b"\x55\xAA":
        raise ValueError("stage1 boot sector does not end with 0x55AA")
    image = bytearray(BYTES_PER_SECTOR * TOTAL_SECTORS)
    image[:BYTES_PER_SECTOR] = boot_sector
    fat = bytearray(BYTES_PER_SECTOR * SECTORS_PER_FAT)
    fat[0:3] = b"\xF0\xFF\xFF"
    directory = bytearray(ROOT_DIR_SECTORS * BYTES_PER_SECTOR)
    next_cluster = 2
    next_cluster = allocate_file(image, fat, directory, 0, "STAGE2.BIN", stage2, next_cluster)
    next_cluster = allocate_file(image, fat, directory, 1, "KERNEL.BIN", kernel, next_cluster)
    for slot, (name, data) in enumerate(EXTRA_TEXT_FILES.items(), start=2):
        next_cluster = allocate_file(image, fat, directory, slot, name, data, next_cluster)
    fat_area_offset = RESERVED_SECTORS * BYTES_PER_SECTOR
    for copy_index in range(FAT_COUNT):
        start = fat_area_offset + (copy_index * len(fat))
        image[start : start + len(fat)] = fat
    root_dir_offset = (RESERVED_SECTORS + FAT_COUNT * SECTORS_PER_FAT) * BYTES_PER_SECTOR
    image[root_dir_offset : root_dir_offset + len(directory)] = directory
    return image
def main() -> int:
    args = parse_args()
    boot_sector = read_file(args.boot)
    stage2 = read_file(args.stage2)
    kernel = read_file(args.kernel)
    image = build_image(boot_sector, stage2, kernel)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(image)
    print(f"[image] wrote {args.output}")
    return 0
if __name__ == "__main__":
    raise SystemExit(main())
