library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ram_memory is
    generic(
	SIZE_BYTES: integer
    );
    port(
	-- ========== BUS SIGNALS ==========
	bus_addr: in std_logic_vector(integer(ceil(log2(real(SIZE_BYTES)))) - 1 downto 0);
	bus_wdata: in std_logic_vector(31 downto 0);
	bus_rdata: out std_logic_vector(31 downto 0);
	bus_wstrb: in std_logic_vector(3 downto 0);
	bus_ready: out std_logic;

	-- ========== CONTROL SIGNALS ==========
	en: in std_logic;
	clk: in std_logic;
	resetn: in std_logic
    );
end ram_memory;

architecture rtl of ram_memory is
    constant BUS_ADDR_BITS: integer := integer(ceil(log2(real(SIZE_BYTES))));

    type ram_type is array (0 to SIZE_BYTES / 4 - 1) of std_logic_vector(31 downto 0);
    signal ram: ram_type;

begin
    process(clk)
    begin
	if falling_edge(clk) and en = '1' then
	    bus_rdata <= ram(to_integer(unsigned(bus_addr(BUS_ADDR_BITS - 1 downto 2))));
	    for i in 0 to 3 loop
		if bus_wstrb(i) = '1' then
		    ram(to_integer(unsigned(bus_addr(BUS_ADDR_BITS - 1 downto 2))))(i * 8 + 7 downto i * 8) <= bus_wdata(i * 8 + 7 downto i * 8);
		end if;
	    end loop;
	end if;
    end process;
    bus_ready <= en and resetn;
end rtl;
