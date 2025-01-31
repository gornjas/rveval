--
-- Copyright (c) 2013 - 2022 Marko Zec
-- Copyright (c) 2015 Davor Jadrijevic
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
-- LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
-- OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
-- SUCH DAMAGE.
--

-- BRAM block from address 0
-- contains f32c bootloader, either 512 (SIO) or 1024 (SIO + SPI) bytes long
-- BRAM is initialized with bootloader content at loading of FPGA bitstream

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity rom is
    generic(
	C_rom_size: natural := 2 -- in KBytes
    );
    port(
	clk: in std_logic;
	strobe: in std_logic;
	addr: in std_logic_vector(31 downto 2);
	data_ready: out std_logic;
	data_out: out std_logic_vector(31 downto 0)
    );
end rom;

architecture x of rom is
    type boot_block_type is array(0 to 2047) of std_logic_vector(7 downto 0);

    constant boot_sio_rv32: boot_block_type := (
	x"13", x"01", x"01", x"fe", x"23", x"2e", x"11", x"00", 
	x"23", x"2c", x"81", x"00", x"23", x"2a", x"91", x"00", 
	x"23", x"28", x"21", x"01", x"23", x"26", x"31", x"01", 
	x"23", x"24", x"41", x"01", x"23", x"22", x"51", x"01", 
	x"23", x"20", x"61", x"01", x"13", x"00", x"00", x"00", 
	x"13", x"08", x"00", x"00", x"93", x"05", x"00", x"00", 
	x"93", x"07", x"00", x"00", x"b7", x"13", x"72", x"76", 
	x"37", x"3e", x"3e", x"20", x"b7", x"0e", x"00", x"08", 
	x"93", x"08", x"30", x"00", x"13", x"0f", x"00", x"06", 
	x"93", x"0f", x"10", x"00", x"93", x"00", x"50", x"00", 
	x"13", x"04", x"00", x"04", x"93", x"04", x"30", x"05", 
	x"13", x"09", x"d0", x"00", x"93", x"09", x"f0", x"01", 
	x"93", x"0a", x"00", x"00", x"13", x"87", x"d3", x"a0", 
	x"03", x"06", x"10", x"b0", x"93", x"12", x"d6", x"01", 
	x"e3", x"cc", x"02", x"fe", x"23", x"00", x"e0", x"b0", 
	x"13", x"57", x"87", x"40", x"33", x"63", x"57", x"01", 
	x"63", x"18", x"03", x"00", x"93", x"0a", x"f0", x"ff", 
	x"13", x"07", x"3e", x"23", x"6f", x"f0", x"df", x"fd", 
	x"e3", x"1c", x"07", x"fc", x"13", x"07", x"f0", x"ff", 
	x"13", x"05", x"20", x"00", x"13", x"06", x"f0", x"0f", 
	x"13", x"03", x"05", x"00", x"13", x"0a", x"07", x"00", 
	x"93", x"da", x"85", x"40", x"63", x"5e", x"07", x"02", 
	x"f3", x"27", x"10", x"c0", x"b3", x"f6", x"d7", x"01", 
	x"33", x"3b", x"d0", x"00", x"b3", x"02", x"60", x"41", 
	x"93", x"f6", x"f2", x"0f", x"93", x"d2", x"37", x"41", 
	x"13", x"fb", x"f7", x"0f", x"93", x"f2", x"f2", x"0f", 
	x"63", x"d6", x"62", x"01", x"93", x"c6", x"f6", x"00", 
	x"6f", x"00", x"80", x"00", x"93", x"c6", x"06", x"0f", 
	x"23", x"08", x"d0", x"f0", x"6f", x"00", x"80", x"00", 
	x"23", x"08", x"50", x"f1", x"03", x"0b", x"10", x"b0", 
	x"93", x"12", x"fb", x"01", x"e3", x"dc", x"02", x"fa", 
	x"83", x"0a", x"00", x"b0", x"63", x"52", x"07", x"04", 
	x"63", x"98", x"9a", x"00", x"93", x"07", x"00", x"00", 
	x"13", x"07", x"00", x"00", x"6f", x"f0", x"df", x"f9", 
	x"63", x"98", x"4a", x"01", x"6f", x"00", x"c0", x"0d", 
	x"93", x"07", x"00", x"00", x"6f", x"f0", x"df", x"f8", 
	x"e3", x"80", x"2a", x"f5", x"93", x"07", x"00", x"00", 
	x"e3", x"d0", x"59", x"f9", x"83", x"07", x"10", x"b0", 
	x"93", x"96", x"d7", x"01", x"e3", x"cc", x"06", x"fe", 
	x"23", x"00", x"50", x"b1", x"6f", x"f0", x"df", x"fd", 
	x"93", x"86", x"6a", x"ff", x"e3", x"f8", x"d8", x"f4", 
	x"13", x"9b", x"47", x"00", x"63", x"56", x"5f", x"01", 
	x"93", x"8a", x"0a", x"fe", x"6f", x"00", x"00", x"01", 
	x"93", x"87", x"0a", x"fd", x"b3", x"e7", x"67", x"01", 
	x"63", x"56", x"54", x"01", x"93", x"82", x"9a", x"fc", 
	x"b3", x"e7", x"62", x"01", x"13", x"07", x"17", x"00", 
	x"63", x"1c", x"f7", x"03", x"13", x"8b", x"97", x"ff", 
	x"63", x"60", x"63", x"03", x"37", x"04", x"00", x"08", 
	x"b7", x"04", x"01", x"00", x"33", x"71", x"88", x"00", 
	x"33", x"61", x"91", x"00", x"93", x"00", x"00", x"00", 
	x"67", x"00", x"08", x"00", x"6f", x"f0", x"5f", x"f8", 
	x"e3", x"c0", x"f8", x"f8", x"93", x"92", x"17", x"00", 
	x"13", x"86", x"52", x"00", x"6f", x"f0", x"5f", x"f7", 
	x"63", x"18", x"17", x"01", x"93", x"96", x"17", x"00", 
	x"33", x"05", x"d5", x"00", x"6f", x"f0", x"5f", x"f6", 
	x"e3", x"d8", x"c0", x"ee", x"63", x"1c", x"c7", x"00", 
	x"93", x"85", x"07", x"00", x"13", x"06", x"07", x"00", 
	x"e3", x"10", x"08", x"ee", x"13", x"88", x"07", x"00", 
	x"6f", x"f0", x"9f", x"ed", x"e3", x"5a", x"e6", x"ec", 
	x"93", x"1a", x"f7", x"01", x"e3", x"d6", x"0a", x"ec", 
	x"e3", x"54", x"a7", x"ec", x"23", x"80", x"f5", x"00", 
	x"93", x"85", x"15", x"00", x"6f", x"f0", x"df", x"eb", 
	x"13", x"05", x"00", x"09", x"93", x"05", x"00", x"00", 
	x"93", x"06", x"00", x"00", x"93", x"07", x"00", x"00", 
	x"93", x"08", x"05", x"00", x"93", x"02", x"00", x"0a", 
	x"13", x"03", x"10", x"0b", x"93", x"03", x"10", x"09", 
	x"13", x"0e", x"00", x"08", x"93", x"0e", x"10", x"08", 
	x"73", x"27", x"10", x"c0", x"13", x"56", x"87", x"01", 
	x"23", x"08", x"c0", x"f0", x"03", x"08", x"10", x"b0", 
	x"13", x"1f", x"f8", x"01", x"e3", x"56", x"0f", x"fe", 
	x"83", x"0f", x"00", x"b0", x"13", x"f7", x"ff", x"0f", 
	x"63", x"16", x"a7", x"00", x"93", x"85", x"06", x"00", 
	x"6f", x"f0", x"9f", x"fd", x"63", x"ec", x"e8", x"00", 
	x"63", x"04", x"c7", x"03", x"63", x"16", x"d7", x"0d", 
	x"13", x"86", x"07", x"00", x"13", x"07", x"40", x"00", 
	x"6f", x"00", x"00", x"06", x"63", x"02", x"57", x"06", 
	x"63", x"00", x"67", x"0a", x"63", x"1a", x"77", x"0a", 
	x"93", x"87", x"06", x"00", x"6f", x"f0", x"df", x"fa", 
	x"13", x"07", x"40", x"00", x"93", x"96", x"86", x"00", 
	x"03", x"08", x"10", x"b0", x"13", x"1f", x"f8", x"01", 
	x"e3", x"5c", x"0f", x"fe", x"83", x"0f", x"00", x"b0", 
	x"13", x"f6", x"ff", x"0f", x"13", x"07", x"f7", x"ff", 
	x"b3", x"06", x"d6", x"00", x"e3", x"10", x"07", x"fe", 
	x"6f", x"f0", x"1f", x"f8", x"03", x"0f", x"10", x"b0", 
	x"93", x"1f", x"df", x"01", x"e3", x"cc", x"0f", x"fe", 
	x"23", x"00", x"00", x"b1", x"13", x"07", x"f7", x"ff", 
	x"13", x"16", x"86", x"00", x"e3", x"02", x"07", x"f6", 
	x"13", x"58", x"86", x"01", x"6f", x"f0", x"1f", x"fe", 
	x"93", x"07", x"00", x"00", x"13", x"06", x"00", x"00", 
	x"e3", x"08", x"b6", x"f4", x"13", x"98", x"17", x"00", 
	x"93", x"d7", x"f7", x"01", x"b3", x"ef", x"07", x"01", 
	x"03", x"0f", x"10", x"b0", x"13", x"17", x"ff", x"01", 
	x"e3", x"5c", x"07", x"fe", x"03", x"08", x"00", x"b0", 
	x"33", x"0f", x"d6", x"00", x"93", x"77", x"f8", x"0f", 
	x"23", x"00", x"0f", x"01", x"b3", x"87", x"f7", x"01", 
	x"13", x"06", x"16", x"00", x"6f", x"f0", x"df", x"fc", 
	x"37", x"04", x"00", x"08", x"b7", x"04", x"01", x"00", 
	x"33", x"f1", x"86", x"00", x"33", x"61", x"91", x"00", 
	x"93", x"00", x"00", x"00", x"67", x"80", x"06", x"00", 
	x"67", x"00", x"00", x"00", x"6f", x"f0", x"df", x"ef", 
	others => (others => '0')
    );

    type rom_type is array(0 to (C_rom_size * 256 - 1))
      of std_logic_vector(7 downto 0);

    function boot_block_to_rom(x: boot_block_type; n: natural)
      return rom_type is
	variable y: rom_type;
	variable i, l: natural;
    begin
	y := (others => (others => '0'));
	i := n;
	l := x'length;
	while i < l loop
	    y(i / 4) := x(i);
	    i := i + 4;
	end loop;
	return y;
    end boot_block_to_rom;

    signal rom_0: rom_type := boot_block_to_rom(boot_sio_rv32, 0);
    signal rom_1: rom_type := boot_block_to_rom(boot_sio_rv32, 1);
    signal rom_2: rom_type := boot_block_to_rom(boot_sio_rv32, 2);
    signal rom_3: rom_type := boot_block_to_rom(boot_sio_rv32, 3);

    signal R_ack: std_logic;

begin

    process(clk)
    begin
	if rising_edge(clk) then
	    data_out <= rom_3(conv_integer(addr)) & rom_2(conv_integer(addr))
	      & rom_1(conv_integer(addr)) & rom_0(conv_integer(addr));

	    if strobe = '1' and R_ack = '0' then
		R_ack <= '1';
	    else
		R_ack <= '0';
	    end if;
	end if;
    end process;
    
	data_ready <= R_ack;
end x;
