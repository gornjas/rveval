TOOLCHAIN_PREFIX := riscv32-elf-
PYTHON := python

FIRMWARE_OBJS := start.o prog.o

firmware.hex: firmware.bin makehex.py
	$(PYTHON) makehex.py $< 1024 > $@

firmware.bin: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@

firmware.elf: $(FIRMWARE_OBJS) $(TEST_OBJS) sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -mabi=ilp32 -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,sections.lds,--strip-debug \
		$(FIRMWARE_OBJS) $(TEST_OBJS)
	
start.o:
	$(TOOLCHAIN_PREFIX)gcc -c start.s -ffreestanding -nostdlib -mabi=ilp32 -march=rv32i 
	
prog.o:
	$(TOOLCHAIN_PREFIX)gcc -c prog.c -ffreestanding -nostdlib -mabi=ilp32 -march=rv32i 
	
decomp:
	$(TOOLCHAIN_PREFIX)objdump firmware.elf -h > sects
	$(TOOLCHAIN_PREFIX)objdump firmware.elf -D > decomp
	
clear:
	rm -f *.o
	rm -f *.hex
	rm -f *.elf
	rm -f *.bin
