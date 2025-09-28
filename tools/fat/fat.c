#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

typedef struct __attribute__((packed)) {
    uint8_t  BootJumpInstruction[3];
    uint8_t  OemIdentifier[8];
    uint16_t BytesPerSector;
    uint8_t  SectorsPerCluster;
    uint16_t ReservedSectors;
    uint8_t  FatCount;
    uint16_t DirEntryCount;
    uint16_t TotalSectors;
    uint8_t  MediaDescriptorType;
    uint16_t SectorsPerFat;
    uint16_t SectorsPerTrack;
    uint16_t Heads;
    uint32_t HiddenSectors;
    uint32_t LargeSectorCount;

    // extended boot record
    uint8_t  DriveNumber;
    uint8_t  _Reserved;
    uint8_t  Signature;
    uint32_t VolumeId;
    uint8_t  VolumeLabel[11];
    uint8_t  SystemId[8];

} BootSector;

typedef struct __attribute__((packed)) {
    uint8_t  Name[11];
    uint8_t  Attributes;
    uint8_t  _Reserved;
    uint8_t  CreatedTimeTenths;
    uint16_t CreatedTime;
    uint16_t CreatedDate;
    uint16_t AccessedDate;
    uint16_t FirstClusterHigh;
    uint16_t ModifiedTime;
    uint16_t ModifiedDate;
    uint16_t FirstClusterLow;
    uint32_t Size;
} DirectoryEntry;

static BootSector g_BootSector;
static uint8_t* g_Fat = NULL;
static DirectoryEntry* g_RootDirectory = NULL;
static uint32_t g_RootDirectoryEnd = 0;

static bool readBootSector(FILE* disk) {
    return fread(&g_BootSector, sizeof(g_BootSector), 1, disk) == 1;
}

static bool readSectors(FILE* disk, uint32_t lba, uint32_t count, void* bufferOut) {
    if (fseek(disk, (long)(lba * g_BootSector.BytesPerSector), SEEK_SET) != 0)
        return false;
    return fread(bufferOut, g_BootSector.BytesPerSector, count, disk) == count;
}

static bool readFat(FILE* disk) {
    size_t fatSize = (size_t) g_BootSector.SectorsPerFat * g_BootSector.BytesPerSector;
    g_Fat = malloc(fatSize);
    if (!g_Fat) return false;
    if (!readSectors(disk, g_BootSector.ReservedSectors, g_BootSector.SectorsPerFat, g_Fat)) {
        free(g_Fat);
        g_Fat = NULL;
        return false;
    }
    return true;
}

static bool readRootDirectory(FILE* disk) {
    uint32_t lba = g_BootSector.ReservedSectors + g_BootSector.SectorsPerFat * g_BootSector.FatCount;
    uint32_t size = (uint32_t)sizeof(DirectoryEntry) * g_BootSector.DirEntryCount;
    uint32_t sectors = (size + g_BootSector.BytesPerSector - 1) / g_BootSector.BytesPerSector;

    g_RootDirectoryEnd = lba + sectors;
    g_RootDirectory = malloc(sectors * g_BootSector.BytesPerSector);
    if (!g_RootDirectory) return false;

    if (!readSectors(disk, lba, sectors, g_RootDirectory)) {
        free(g_RootDirectory);
        g_RootDirectory = NULL;
        return false;
    }
    return true;
}

static void formatName(const char* input, char out[11]) {
    memset(out, ' ', 11);
    size_t len = strlen(input);
    size_t i = 0, j = 0;
    while (i < len && j < 11) {
        if (input[i] == '.') {
            j = 8; // salto a la parte de extensión
            i++;
            continue;
        }
        out[j++] = (char) toupper((unsigned char)input[i++]);
    }
}

static DirectoryEntry* findFile(const char* name) {
    char formatted[11];
    formatName(name, formatted);

    for (uint32_t i = 0; i < g_BootSector.DirEntryCount; i++) {
        if (memcmp(formatted, g_RootDirectory[i].Name, 11) == 0)
            return &g_RootDirectory[i];
    }
    return NULL;
}

static uint16_t getNextCluster(uint16_t cluster) {
    uint32_t fatIndex = cluster * 3 / 2;
    uint16_t entry = g_Fat[fatIndex] | (g_Fat[fatIndex+1] << 8);

    if (cluster % 2 == 0)
        return entry & 0x0FFF;
    else
        return entry >> 4;
}

static bool readFile(DirectoryEntry* fileEntry, FILE* disk) {
    uint16_t currentCluster = fileEntry->FirstClusterLow;
    size_t remaining = fileEntry->Size;

    size_t clusterSize = (size_t) g_BootSector.SectorsPerCluster * g_BootSector.BytesPerSector;
    uint8_t* buffer = malloc(clusterSize);
    if (!buffer) return false;

    bool ok = true;
    while (ok && currentCluster < 0x0FF8 && remaining > 0) {
        uint32_t lba = g_RootDirectoryEnd + (currentCluster - 2) * g_BootSector.SectorsPerCluster;
        ok = readSectors(disk, lba, g_BootSector.SectorsPerCluster, buffer);
        if (!ok) break;

        size_t toPrint = (remaining < clusterSize) ? remaining : clusterSize;
        for (size_t i = 0; i < toPrint; i++) {
            if (isprint(buffer[i])) fputc(buffer[i], stdout);
            else printf("<%02x>", buffer[i]);
        }
        remaining -= toPrint;
        currentCluster = getNextCluster(currentCluster);
    }

    free(buffer);
    return ok;
}

int main(int argc, char** argv) {
    if (argc < 3) {
        printf("Usage: %s <disk image> <file name>\n", argv[0]);
        return 1;
    }

    FILE* disk = fopen(argv[1], "rb");
    if (!disk) {
        fprintf(stderr, "Cannot open disk image %s!\n", argv[1]);
        return 2;
    }

    if (!readBootSector(disk)) {
        fprintf(stderr, "Could not read boot sector!\n");
        fclose(disk);
        return 3;
    }

    if (!readFat(disk)) {
        fprintf(stderr, "Could not read FAT!\n");
        fclose(disk);
        return 4;
    }

    if (!readRootDirectory(disk)) {
        fprintf(stderr, "Could not read root directory!\n");
        free(g_Fat);
        fclose(disk);
        return 5;
    }

    DirectoryEntry* fileEntry = findFile(argv[2]);
    if (!fileEntry) {
        fprintf(stderr, "File not found: %s\n", argv[2]);
        free(g_Fat);
        free(g_RootDirectory);
        fclose(disk);
        return 6;
    }

    if (!readFile(fileEntry, disk)) {
        fprintf(stderr, "Error reading file %s!\n", argv[2]);
        free(g_Fat);
        free(g_RootDirectory);
        fclose(disk);
        return 7;
    }

    printf("\n");

    free(g_Fat);
    free(g_RootDirectory);
    fclose(disk);
    return 0;
}
