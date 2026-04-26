
BUILD_DIR ?= build
ASM       ?= nasm
SRC       ?= boot.asm
TARGET    = $(BUILD_DIR)/stage1.bin

.PHONY: all clean


all: $(TARGET)

$(TARGET): $(SRC)
	@mkdir -p $(BUILD_DIR)
	@echo "Assembling $< -> $@"
	$(ASM) -f bin $< -o $@

clean:
	@echo "Cleaning..."
	@rm -f $(TARGET)
