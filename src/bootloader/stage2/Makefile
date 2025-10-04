BUILD_DIR ?= $(abspath ../../../../build)
ASM ?= nasm
SRC ?= main.asm
.PHONY: all clean

all: $(BUILD_DIR)/stage2.bin

$(BUILD_DIR)/stage2.bin: $(SRC)
	mkdir -p $(BUILD_DIR)
	$(ASM) $< -f bin -o $@

clean:
	rm -f $(BUILD_DIR)/stage2.bin
