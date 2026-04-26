BUILD_DIR ?= $(abspath ../../../../build)
ASM       = nasm
CC16      = /usr/bin/watcom/binl/wcc
LD16      = /opt/open-watcom/binl/wlink

ASM_EXT   = asm
C_EXT     = c
OBJ_EXT   = obj

LINKER_SCRIPT = $(BUILD_DIR)/linker.lnk

# --- CAMBIO CRÍTICO: Forzar orden de archivos ---
# Separamos crt0 de los demás para que sea el punto de entrada real
ENTRY_ASM  = crt0.asm
SOURCES_ASM = $(filter-out $(ENTRY_ASM), $(wildcard *.$(ASM_EXT)))
SOURCES_C   = $(wildcard *.$(C_EXT))

# El objeto de entrada siempre va primero
ENTRY_OBJ   = $(BUILD_DIR)/crt0.obj
OBJECTS_ASM = $(patsubst %.$(ASM_EXT), $(BUILD_DIR)/%.obj, $(SOURCES_ASM))
OBJECTS_C   = $(patsubst %.$(C_EXT),   $(BUILD_DIR)/%.obj, $(SOURCES_C))

# Lista completa de objetos empezando por la entrada
ALL_OBJECTS = $(ENTRY_OBJ) $(OBJECTS_ASM) $(OBJECTS_C)

TARGET = $(BUILD_DIR)/stage2.bin
MAP    = $(BUILD_DIR)/stage2.map

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(ALL_OBJECTS) $(LINKER_SCRIPT)
	@echo "Linking $@ ..."
	$(LD16) @$(LINKER_SCRIPT)

$(LINKER_SCRIPT): $(ALL_OBJECTS) | $(BUILD_DIR)
	@echo "Generating linker script..."
	@echo "FORMAT RAW BIN" > $@
	@echo "OPTION QUIET, NODEFAULTLIBS" >> $@
	@echo "OPTION MAP=$(MAP), VERBOSE" >> $@
	@echo "ORDER" >> $@
	@echo "    SECTION _ENTRY" >> $@
	@echo "    SECTION _TEXT" >> $@
	@echo "    SECTION _DATA" >> $@
	@for f in $(ALL_OBJECTS); do echo "FILE $$f" >> $@; done
	@echo "NAME $(TARGET)" >> $@

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.obj: %.$(ASM_EXT) | $(BUILD_DIR)
	@echo "Assembling $< ..."
	$(ASM) -f obj $< -o $@

$(BUILD_DIR)/%.obj: %.$(C_EXT) | $(BUILD_DIR)
	@echo "Compiling $< ..."
	# -0: 8086 code, -ms: Small Model, -s: Remove stack checks
	$(CC16) -q -0 -ms -s -fo=$@ $<

clean:
	@echo "Cleaning build files ..."
	rm -f $(BUILD_DIR)/*.obj $(TARGET) $(MAP) $(LINKER_SCRIPT)
