BUILD_DIR ?= $(abspath ../../../build)

ASM = nasm
CC = gcc
LD = ld

TARGET = $(BUILD_DIR)/kernel.bin

# Source files
ASM_SOURCES = entry.asm kernel.asm
C_SOURCES = $(wildcard *.c)

# Object files
ASM_OBJECTS = $(patsubst %.asm, $(BUILD_DIR)/kernel_%.o, $(ASM_SOURCES))
C_OBJECTS = $(patsubst %.c, $(BUILD_DIR)/kernel_%.o, $(C_SOURCES))

ALL_OBJECTS = $(ASM_OBJECTS) $(C_OBJECTS)

# Compiler flags for 32-bit kernel
CFLAGS = -m32 -ffreestanding -fno-pie -fno-stack-protector -nostdlib -O2 -Wall -Wextra

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(ALL_OBJECTS) linker.ld | $(BUILD_DIR)
	@echo "Linking kernel..."
	$(LD) -m elf_i386 -T linker.ld -o $@ $(ALL_OBJECTS)
	@echo "Kernel built: $@"

$(BUILD_DIR)/kernel_%.o: %.asm | $(BUILD_DIR)
	@echo "Assembling $<..."
	$(ASM) -f elf32 $< -o $@

$(BUILD_DIR)/kernel_%.o: %.c | $(BUILD_DIR)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

clean:
	@echo "Cleaning kernel objects..."
	rm -f $(BUILD_DIR)/kernel_*.o $(TARGET)
