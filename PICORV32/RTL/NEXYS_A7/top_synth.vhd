library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.f32c_pack.all;

entity top_synth is
    port(
        CLK100MHZ : in std_logic;
        
        CPU_RESETN : in std_logic;
        
        UART_TXD_IN : in std_logic;
        UART_RXD_OUT : out std_logic;
        
        BTNC : in std_logic;
        BTNU : in std_logic;
        BTNL : in std_logic;
        BTNR : in std_logic;
        BTND : in std_logic;
        
        SW : in std_logic_vector(15 downto 0);
        
        LED : out std_logic_vector(15 downto 0)
        );
end top_synth;

architecture structural of top_synth is
    constant BRAM_ADDR_TOP: std_logic_vector := x"0";
    constant SDRAM_ADDR_TOP: std_logic_vector := x"8";
    constant MMIO_ADDR_TOP: std_logic_vector := x"F";

    component sdrc_top
	port(
			sdram_clk: in std_logic; --SDRAM Clock 
			sdram_resetn: in std_logic; --Reset Signal
			cfg_sdr_width: in std_logic_vector(1 downto 0); -- 2'b00 - 32 Bit SDR, 2'b01 - 16 Bit SDR, 2'b1x - 8 Bit
			cfg_colbits: in std_logic_vector(1 downto 0); -- 2'b00 - 8 Bit column address, 
														 -- 2'b01 - 9 Bit, 10 - 10 bit, 11 - 11Bits

			--------------------------------------
			--Wish Bone Interface
			-------------------------------------      
			wb_rst_i: in std_logic;
			wb_clk_i: in std_logic;

			wb_stb_i: in std_logic;
			wb_ack_o: out std_logic;
			wb_addr_i: in std_logic_vector(25 downto 0);
			wb_we_i: in std_logic; -- 1 - Write, 0 - Read
			wb_dat_i: in std_logic_vector(31 downto 0);
			wb_sel_i: in std_logic_vector(3 downto 0); -- Byte enable
			wb_dat_o: out std_logic_vector(31 downto 0);
			wb_cyc_i: in std_logic;
			wb_cti_i: in std_logic_vector(2 downto 0);

			------------------------------------------------
			-- Interface to SDRAMs
			------------------------------------------------
			sdr_cke: out std_logic; -- SDRAM CKE
			sdr_cs_n: out std_logic;            -- SDRAM Chip Select
			sdr_ras_n: out std_logic; -- SDRAM ras
			sdr_cas_n: out std_logic; -- SDRAM cas
			sdr_we_n: out std_logic; -- SDRAM write enable
			sdr_dqm: out std_logic_vector(1 downto 0); -- SDRAM Data Mask
			sdr_ba: out std_logic_vector(1 downto 0); -- SDRAM Bank Enable
			sdr_addr: out std_logic_vector(12 downto 0); -- SDRAM Address
			sdr_dq: inout std_logic_vector(15 downto 0); -- SDRA Data Input/output

			------------------------------------------------
			-- Configuration Parameter
			------------------------------------------------
			sdr_init_done: out std_logic; -- Indicate SDRAM Initialisation Done
			cfg_sdr_tras_d: in std_logic_vector(3 downto 0); -- Active to precharge delay
			cfg_sdr_trp_d: in std_logic_vector(3 downto 0); -- Precharge to active delay
			cfg_sdr_trcd_d: in std_logic_vector(3 downto 0); -- Active to R/W delay
			cfg_sdr_en: in std_logic; -- Enable SDRAM controller
			cfg_req_depth: in std_logic_vector(1 downto 0); --Maximum Request accepted by SDRAM controller
			cfg_sdr_mode_reg: in std_logic_vector(12 downto 0);
			cfg_sdr_cas: in std_logic_vector(2 downto 0); -- SDRAM CAS Latency
			cfg_sdr_trcar_d: in std_logic_vector(3 downto 0); -- Auto-refresh period
			cfg_sdr_twr_d: in std_logic_vector(3 downto 0); -- Write recovery delay
			cfg_sdr_rfsh: in std_logic_vector(11 downto 0);
			cfg_sdr_rfmax: in std_logic_vector(2 downto 0)

	);
	end component;

    component clk_wiz_0_clk_wiz
    port
        (-- Clock in ports
        -- Clock out ports
        clk_out1          : out    std_logic;
        clk_out2          : out    std_logic;
        clk_out3          : out    std_logic;
        clk_out4          : out    std_logic;
        -- Status and control signals
        locked             : out     std_logic;
        clk_in1           : in     std_logic
     );
    end component;
    
    component picorv32
		generic(
			STACKADDR : std_logic_vector(31 downto 0) := X"8000_4000";
			PROGADDR_RESET : std_logic_vector(31 downto 0) := X"0000_0000";
			ENABLE_COUNTERS : boolean := true;
			ENABLE_COUNTERS64 : boolean := true;
			ENABLE_REGS_16_31 : boolean := true;
			ENABLE_REGS_DUALPORT : boolean := true;
			LATCHED_MEM_RDATA : boolean := false;
			TWO_STAGE_SHIFT : boolean := true;
			BARREL_SHIFTER : boolean := true;
			TWO_CYCLE_COMPARE : boolean := false;
			TWO_CYCLE_ALU : boolean := false;
			COMPRESSED_ISA : boolean := false;
			CATCH_ILLINSN : boolean := true;
			ENABLE_PCPI : boolean := false;
			ENABLE_MUL : boolean := true;
			ENABLE_DIV : boolean := true;
			ENABLE_FAST_MUL : boolean := true;
			ENABLE_IRQ : boolean := false;
			ENABLE_IRQ_QREGS : boolean := true;
			ENABLE_IRQ_TIMER : boolean := true;
			ENABLE_TRACE : boolean := false;
			REGS_INIT_ZERO : boolean := false;
			MASKED_IRQ : std_logic_vector(31 downto 0) := (others => '0');
			LATCHED_IRQ : std_logic_vector(31 downto 0) := (others => '0');
			PROGADDR_IRQ : std_logic_vector(31 downto 0) := (others => '0')
		);
		port(
			mem_valid : out std_logic;
			mem_instr : out std_logic;
			mem_ready : in std_logic;
			mem_addr : out std_logic_vector(31 downto 0);
			mem_wdata : out std_logic_vector(31 downto 0);
			mem_wstrb : out std_logic_vector(3 downto 0);
			mem_rdata : in std_logic_vector(31 downto 0);
			
			pcpi_wr : in std_logic;
			pcpi_rd : in std_logic_vector(31 downto 0);
			pcpi_ready : in std_logic;
			pcpi_wait : in std_logic;
			
			mem_la_read : out std_logic;
			mem_la_write : out std_logic;
			mem_la_addr : out std_logic_vector(31 downto 0);
			mem_la_wdata : out std_logic_vector(31 downto 0);
			mem_la_wstrb : out std_logic_vector(3 downto 0);
			
			pcpi_valid : out std_logic;
			pcpi_insn : out std_logic_vector(31 downto 0);
			pcpi_rs1 : out std_logic_vector(31 downto 0);
			pcpi_rs2 : out std_logic_vector(31 downto 0);
			
			irq : in std_logic_vector(31 downto 0);
			eoi : out std_logic_vector(31 downto 0);
			
			trace_valid : out std_logic;
			trace_data : out std_logic_vector(35 downto 0);
			
			trap : out std_logic;
			clk : in std_logic;
			resetn : in std_logic
		);
	end component;
    
    component simpleuart
		port(
			clk : in std_logic;
			resetn : in std_logic;
			
			ser_tx : out std_logic;
			ser_rx : in std_logic;
			
			reg_div_we : in std_logic_vector(3 downto 0);
			reg_div_di : in std_logic_vector(31 downto 0);
			reg_div_do : out std_logic_vector(31 downto 0);
			
			reg_dat_we : in std_logic;
			reg_dat_re : in std_logic;
			
			reg_dat_di : in std_logic_vector(31 downto 0);
			reg_dat_do : out std_logic_vector(31 downto 0);
			reg_dat_wait : out std_logic
		);
	end component;

    -- Top 8 bits of the address that are used in address decoding. For ex. if SDRAM_ADDR_TOP has a value of 0x30 then accessing addresses whose top 8 bits
    -- are 0x30 will access SDRAM
    
    -- NOTE: XILINX boards do not have built-in SDRAM, so it has been replaced with a large BRAM
    signal bus_valid, bus_instr, bus_write, bus_ready: std_logic;
    signal bus_addr, bus_wdata, bus_rdata: std_logic_vector(31 downto 0);
    signal bus_wstrb: std_logic_vector(3 downto 0);
    
    signal irq: std_logic_vector(31 downto 0) := (others => '0');
    
    signal clk, clk_locked, resetn, reset: std_logic;
    
    signal rom_bus_rdata: std_logic_vector(31 downto 0);
    signal rom_bus_ready, rom_cs: std_logic;
	
    signal ram_bus_rdata: std_logic_vector(31 downto 0);
    signal ram_bus_ready, ram_cs: std_logic;
	
    signal sdram_bus_rdata: std_logic_vector(31 downto 0);
    signal sdram_bus_ready, sdram_cs, sdram_ack: std_logic;
    signal sdram_cs_read: std_logic;

    signal sio_cs, sio_break: std_logic;
    signal sio_bus_rdata: std_logic_vector(31 downto 0);
    signal sio_byte_sel: std_logic_vector(3 downto 0);

    signal simple_out_cs: std_logic;
    signal R_simple_in, R_simple_out: std_logic_vector(31 downto 0);

    signal mmio_bus_ready: std_logic;
    signal unmapped_bus_ready: std_logic;
begin
    clk_wiz : clk_wiz_0_clk_wiz
              port map(clk_in1 => CLK100MHZ,
                       locked => clk_locked,
                       clk_out1 => clk,
                       clk_out2 => open,
                       clk_out3 => open,
                       clk_out4 => open);


    resetn <= CPU_RESETN and not sio_break and clk_locked;
    --resetn <= CPU_RESETN;
    reset <= not resetn;

    picorv32_inst: picorv32
    port map (
	clk => clk,
	resetn => resetn,
	mem_valid => bus_valid,
	mem_instr => bus_instr,
	mem_ready => bus_ready,
	mem_addr => bus_addr,
	mem_wdata => bus_wdata,
	mem_wstrb => bus_wstrb,
	mem_rdata => bus_rdata,

	irq => irq,

	pcpi_wr => '0',
	pcpi_rd => X"0000_0000",
	pcpi_ready => '0',
	pcpi_wait => '0'
    );
    bus_write <= bus_valid when bus_wstrb /= "0000" else '0';

    rom: entity work.rom
    generic map (
	C_arch => ARCH_RV32,
	C_big_endian => false,
	C_boot_spi => false
    )
    port map (
	clk => clk,
	strobe => rom_cs,
	addr => bus_addr(31 downto 2),
	data_out => rom_bus_rdata,
	data_ready => rom_bus_ready
    );
					
    ram: entity work.ram_memory(rtl)
    generic map (
	SIZE_BYTES => 32768
    )
    port map(
	bus_addr => bus_addr(14 downto 0),
	bus_wdata => bus_wdata,
	bus_rdata => ram_bus_rdata,
	bus_wstrb => bus_wstrb,
	bus_ready => ram_bus_ready,
	en => ram_cs,
	clk => clk,
	resetn => resetn
    );
    
    sdram_replacement: entity work.ram_memory(rtl)
    generic map (
	SIZE_BYTES => 524288       -- 512KB RAM
    )
    port map(
	bus_addr => bus_addr(18 downto 0),
	bus_wdata => bus_wdata,
	bus_rdata => sdram_bus_rdata,
	bus_wstrb => bus_wstrb,
	bus_ready => sdram_bus_ready,
	en => sdram_cs,
	clk => clk,
	resetn => resetn
    );

    -- ADDRESS DECODING
    process(bus_valid, bus_addr, bus_wstrb, sdram_bus_rdata, rom_bus_rdata,
      ram_bus_rdata, sio_bus_rdata, R_simple_in, R_simple_out)
    begin
	bus_rdata <= (others => '0');
	rom_cs <= '0';
	ram_cs <= '0';
	sio_cs <= '0';
	sdram_cs <= '0';
	simple_out_cs <= '0';
	mmio_bus_ready <= '0';
	unmapped_bus_ready <= '0';

	if bus_valid = '1' then
	    case bus_addr(31 downto 28) is
	    when BRAM_ADDR_TOP =>
		-- 0x0 to 0x3ff maps to f32c ROM bootloader (1 K)
		if bus_addr(27 downto 10) = x"0000" & "00" then
		    bus_rdata <= rom_bus_rdata;
		    rom_cs <= '1';
		else
		    bus_rdata <= ram_bus_rdata;
		    ram_cs <= '1';
		end if;
	    when SDRAM_ADDR_TOP =>
            bus_rdata <= sdram_bus_rdata;
            sdram_cs <= bus_valid;
	    when MMIO_ADDR_TOP =>
		-- IO devices map to 0xfffff000 to 0xffffffff
		mmio_bus_ready <= '1';
		case bus_addr(11 downto 4) is
		when x"B0" =>
		    bus_rdata <= sio_bus_rdata;
		    sio_cs <= '1';
		when x"F0" =>
		    bus_rdata <= R_simple_in;
		when x"F1" =>
		    bus_rdata <= R_simple_out;
		    simple_out_cs <= '1';
		when others =>
		end case;
	    when others =>
		-- do not block on unmapped bus cycles
		unmapped_bus_ready <= '1';
	    end case;
	end if;
    end process;

    bus_ready <= rom_bus_ready or sdram_bus_ready or ram_bus_ready
      or mmio_bus_ready or unmapped_bus_ready;

    -- f32c SIO
    sio_instance: entity work.sio
    generic map (
	C_clk_freq => 100,
	C_break_detect => true
    )
    port map (
	clk => clk,
	ce => sio_cs,
	txd => UART_RXD_OUT,
	rxd => UART_TXD_IN,
	bus_write => bus_write,
	byte_sel => sio_byte_sel,
	bus_in => bus_wdata,
	bus_out => sio_bus_rdata,
	break => sio_break
    );
    sio_byte_sel <= bus_wstrb when bus_wstrb /= x"0" else x"f";

    -- simple in & out (LEDs, buttons, switches...)
    R_simple_in <= x"000" & SW(3 downto 0) & x"00" & '0' & not BTNC & BTNU & BTND
      & BTNL & BTND & '0' & '0' when rising_edge(clk);
    R_simple_out <= bus_wdata when rising_edge(clk) and bus_write = '1' and
      simple_out_cs = '1';
      
    LED(7 downto 0) <= R_simple_out(7 downto 0);
    LED(15 downto 8) <= (others => '0');

end structural;
