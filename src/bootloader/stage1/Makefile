BUILD_DIR ?= build
ASM ?= nasm
SRC ?= boot.asm

.PHONY: all clean

all: $(BUILD_DIR)/stage1.bin

$(BUILD_DIR)/stage1.bin: $(SRC)
	mkdir -p $(BUILD_DIR)
	$(ASM) $< -f bin -o $@

clean:
	rm -f $(BUILD_DIR)/stage1.bin
