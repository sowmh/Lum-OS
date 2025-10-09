BUILD_DIR ?= $(abspath ../../../../build)
ASM       = nasm
CC16      = /usr/bin/watcom/binl/wcc
LD16 = /opt/open-watcom/binl/wlink



ASM_EXT   = asm
C_EXT     = c
OBJ_EXT   = obj

LINKER_SCRIPT = $(BUILD_DIR)/linker.lnk

SOURCES_ASM = $(wildcard *.$(ASM_EXT))
SOURCES_C   = $(wildcard *.$(C_EXT))

OBJECTS_ASM = $(patsubst %.$(ASM_EXT), $(BUILD_DIR)/%.obj, $(SOURCES_ASM))
OBJECTS_C   = $(patsubst %.$(C_EXT),   $(BUILD_DIR)/%.obj, $(SOURCES_C))

TARGET = $(BUILD_DIR)/stage2.bin
MAP    = $(BUILD_DIR)/stage2.map

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJECTS_ASM) $(OBJECTS_C) $(LINKER_SCRIPT)
	@echo "Linking $@ ..."
	$(LD16) @$(LINKER_SCRIPT)

$(LINKER_SCRIPT): $(OBJECTS_ASM) $(OBJECTS_C) | $(BUILD_DIR)
	@echo "Generating linker script..."
	@echo "FORMAT RAW BIN" > $@
	@echo "OPTION QUIET, NODEFAULTLIBS, START=entry, VERBOSE, OFFSET=0, STACK=0x200" >> $@
	@echo "ORDER" >> $@
	@echo "    CLNAME CODE" >> $@
	@echo "        SEGMENT _ENTRY" >> $@
	@echo "        SEGMENT _TEXT" >> $@
	@echo "    CLNAME DATA" >> $@
	@for f in $(OBJECTS_ASM) $(OBJECTS_C); do echo "FILE $$f" >> $@; done
	@echo "NAME $(TARGET)" >> $@
	@echo "OPTION MAP=$(MAP)" >> $@

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.obj: %.$(ASM_EXT) | $(BUILD_DIR)
	@echo "Assembling $< ..."
	$(ASM) -f obj $< -o $@

$(BUILD_DIR)/%.obj: %.$(C_EXT) | $(BUILD_DIR)
	@echo "Compiling $< ..."
	$(CC16) -q -fo=$@ $<

clean:
	@echo "Cleaning build files ..."
	rm -f $(BUILD_DIR)/*.obj $(TARGET) $(MAP) $(LINKER_SCRIPT)
