TOOLCHAIN_PREFIX := riscv32-unknown-elf-
PYTHON := python

CFLAGS := -ffreestanding -nostdlib -mabi=ilp32 -march=rv32i
CC := $(TOOLCHAIN_PREFIX)gcc

LIB_DIR := ../../lib
BUILDDIR := build

SOURCES_C := $(wildcard *.c)
SOURCES_S := $(wildcard *.s)
SOURCES_LIB := $(wildcard $(LIB_DIR)/*.c)
OBJECTS_LIB := $(patsubst ../../lib/%.c, $(BUILDDIR)/%.o, $(SOURCES_LIB))
FIRMWARE_OBJS := $(patsubst %.c, $(BUILDDIR)/%.o, $(SOURCES_C))
FIRMWARE_OBJS += $(patsubst %.s, $(BUILDDIR)/%.o, $(SOURCES_S))
FIRMWARE_OBJS += $(OBJECTS_LIB)

FIRMWARE_IMAGE := $(BUILDDIR)/firmware.elf
FIRMWARE_BIN := $(BUILDDIR)/firmware.bin
FIRMWARE_HEX := $(BUILDDIR)/firmware.hex

MAKEHEX := ../../helper/makehex.py

$(info $(SOURCES))
$(info $(FIRMWARE_OBJS))
$(info $(LIB_DIR))

.PHONY: clean

$(FIRMWARE_HEX): $(FIRMWARE_BIN)
	$(PYTHON) $(MAKEHEX) $< 1024 > firmware.hex

$(FIRMWARE_BIN): $(FIRMWARE_IMAGE)
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@

$(FIRMWARE_IMAGE): $(FIRMWARE_OBJS)
	$(CC) -Os -mabi=ilp32 -march=rv32i -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,sections.lds,--strip-debug \
		$(FIRMWARE_OBJS)
	
$(BUILDDIR)/%.o: %.c
	if [ ! -d "$(BUILDDIR)" ]; then \
		mkdir $(BUILDDIR); \
	fi
	$(CC) $(CFLAGS) -c $< -o $@ -I$(LIB_DIR)

$(BUILDDIR)/%.o: %.s
	if [ ! -d "$(BUILDDIR)" ]; then \
		mkdir $(BUILDDIR); \
	fi
	$(CC) $(CFLAGS) -c $< -o $@ -I$(LIB_DIR)

$(BUILDDIR)/%.o: $(SOURCES_LIB)
	if [ ! -d "$(BUILDDIR)" ]; then \
		mkdir $(BUILDDIR); \
	fi
	$(CC) $(CFLAGS) -c $< -o $@ -I$(LIB_DIR)

decomp:
	$(TOOLCHAIN_PREFIX)objdump $(FIRMWARE_IMAGE) -d --disassemble-all > decompiled

clean:
	rm -f $(BUILDDIR)/*.o
	rm -f *.hex
	rm -f $(BUILDDIR)/*.bin
	rm -f decomp
	rm -f sects
	rm -f -r $(BUILDDIR)
