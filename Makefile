TARGET = kernel.elf
ISO = lumos.iso
OBJS = src/impl/x86_64/boot/header.o \
       src/impl/x86_64/boot/main.o \
       src/impl/x86_64/boot/entry.o \
       src/impl/x86_64/boot/kernel.o

CC = gcc
AS = nasm
LD = ld

CFLAGS = -m32 -c -ffreestanding -O2 -fno-stack-protector -fno-pic
ASFLAGS = -f elf32
LDFLAGS = -m elf_i386 -T targets/x86_64/linker.ld

all: $(TARGET)

src/impl/x86_64/boot/%.o: src/impl/x86_64/boot/%.asm
	$(AS) $(ASFLAGS) $< -o $@

src/impl/x86_64/boot/%.o: src/impl/x86_64/boot/%.c
	$(CC) $(CFLAGS) $< -o $@

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $(TARGET) $(OBJS)

iso: $(TARGET)
	mkdir -p iso/boot/grub
	cp $(TARGET) iso/boot/
	cp targets/x86_64/iso/boot/grub/grub.cfg iso/boot/grub/
	grub-mkrescue -o $(ISO) iso

run: iso
	qemu-system-i386 -cdrom $(ISO)

clean:
	rm -rf $(OBJS) $(TARGET) $(ISO) iso
