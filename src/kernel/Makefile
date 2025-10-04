BUILD_DIR ?= build
ASM ?= nasm
SRC ?= main.asm

.PHONY: all clean

all: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: $(SRC)
	mkdir -p $(BUILD_DIR)
	$(ASM) $< -f bin -o $@

clean:
	rm -f $(BUILD_DIR)/kernel.bin
