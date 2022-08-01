-- #################################################################################################
-- # << NEORV32 - Test Setup using the UART-Bootloader to upload and run executables >>            #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2021, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32                           #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_test_setup_bootloader is
  generic (
    -- adapt these for your setup --
    CLOCK_FREQUENCY   : natural := 75000000; -- clock frequency of clk_i in Hz
    MEM_INT_IMEM_SIZE : natural := 16*1024;   -- size of processor-internal instruction memory in bytes
    MEM_INT_DMEM_SIZE : natural := 8*1024     -- size of processor-internal data memory in bytes
  );
  port (
    -- Global control --
    clk_25mhz : in std_logic;
    
    btn : in std_logic_vector(6 downto 0);
    -- GPIO --
    led : out std_ulogic_vector(7 downto 0);
    
	sdram_clk : out std_logic;
	sdram_a : out unsigned(12 downto 0);
	sdram_ba : out unsigned(1 downto 0);
	sdram_d : inout std_logic_vector(15 downto 0);
	sdram_cke : out std_logic;
	sdram_csn : out std_logic;
	sdram_rasn : out std_logic;
	sdram_casn : out std_logic;
	sdram_wen : out std_logic;
	sdram_dqm : out std_logic_vector(1 downto 0);
	
    --gpio_o      : out std_ulogic_vector(7 downto 0); -- parallel output
    -- UART0 --
    ftdi_rxd : out std_ulogic; -- UART0 send data
    ftdi_txd : in  std_ulogic  -- UART0 receive data
  );
end entity;

architecture neorv32_test_setup_bootloader_rtl of neorv32_test_setup_bootloader is

	component pll_1
    port (CLKI: in  std_logic; CLKOP: out  std_logic; 
        CLKOS: out  std_logic; CLKOS2: out  std_logic; 
        CLKOS3: out  std_logic; LOCK: out  std_logic);
end component;

	signal clk_i : std_logic;
	signal clk_lock : std_logic;

	signal con_gpio_o : std_ulogic_vector(63 downto 0);
	signal rstn_i, rst_i : std_logic;

	signal wb_tag : std_ulogic_vector(2 downto 0);
	signal wb_adr : std_ulogic_vector(31 downto 0);
	signal wb_dat_i : std_ulogic_vector(31 downto 0);
	signal wb_dat_o : std_ulogic_vector(31 downto 0);
	signal wb_we_o : std_ulogic;
	signal wb_sel_o : std_ulogic_vector(3 downto 0);
	signal wb_stb_o : std_ulogic;
	signal wb_cyc_o : std_ulogic;
	signal wb_ack_i : std_ulogic;
	signal wb_err_i : std_ulogic;
	
	signal sdram_cntrlr_addr : unsigned(22 downto 0);
	signal sdram_cntrlr_we : std_logic;
	signal sdram_cntrlr_q : std_logic_vector(31 downto 0);
	signal sdram_cntrlr_req : std_logic;
	signal sdram_cntrlr_ack : std_logic;
	signal sdram_cntrlr_valid : std_logic;
begin
  -- The Core Of The Problem ----------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
	pll_inst : pll_1
    port map (CLKI=>clk_25mhz, CLKOP=>clk_i, CLKOS=>open, CLKOS2=>open, CLKOS3=>open, 
        LOCK=>clk_lock);
  
  neorv32_top_inst: neorv32_top
  generic map (
    -- General --
    CLOCK_FREQUENCY              => CLOCK_FREQUENCY,   -- clock frequency of clk_i in Hz
    INT_BOOTLOADER_EN            => true,              -- boot configuration: true = boot explicit bootloader; false = boot from int/ext (I)MEM
    -- RISC-V CPU Extensions --
    CPU_EXTENSION_RISCV_C        => true,              -- implement compressed extension?
    CPU_EXTENSION_RISCV_M        => true,              -- implement mul/div extension?
    CPU_EXTENSION_RISCV_Zicsr    => true,              -- implement CSR system?
    CPU_EXTENSION_RISCV_Zicntr   => true,              -- implement base counters?
    -- Internal Instruction memory --
    MEM_INT_IMEM_EN              => true,              -- implement processor-internal instruction memory
    MEM_INT_IMEM_SIZE            => MEM_INT_IMEM_SIZE, -- size of processor-internal instruction memory in bytes
	-- External bus
	MEM_EXT_EN 					  => true,
	MEM_EXT_TIMEOUT				  => 1023,
    -- Internal Data memory --
    MEM_INT_DMEM_EN              => true,              -- implement processor-internal data memory
    MEM_INT_DMEM_SIZE            => MEM_INT_DMEM_SIZE, -- size of processor-internal data memory in bytes
    -- Processor peripherals --
    IO_GPIO_EN                   => true,              -- implement general purpose input/output port unit (GPIO)?
    IO_MTIME_EN                  => true,              -- implement machine system timer (MTIME)?
    IO_UART0_EN                  => true                -- implement primary universal asynchronous receiver/transmitter (UART0)?
  )
  port map (
    -- Global control --
    clk_i       => clk_i,       -- global clock, rising edge
    rstn_i      => rstn_i,      -- global reset, low-active, async
    -- GPIO (available if IO_GPIO_EN = true) --
    gpio_o      => con_gpio_o,  -- parallel output
    -- primary UART0 (available if IO_UART0_EN = true) --
    uart0_txd_o => ftdi_rxd, -- UART0 send data
    uart0_rxd_i =>  ftdi_txd, -- UART0 receive data
	
	-- Wishbone bus interface --
    wb_tag_o    => wb_tag,
    wb_adr_o    => wb_adr,
    wb_dat_i    => wb_dat_i,
    wb_dat_o    => wb_dat_o,
    wb_we_o     => wb_we_o,
    wb_sel_o    => wb_sel_o,
    wb_stb_o    => wb_stb_o,
    wb_cyc_o    => wb_cyc_o,
    wb_ack_i    => wb_ack_i,
    wb_err_i    => wb_err_i
  );
  
	sdram_controller : entity work.sdram(arch)
                       generic map(CLK_FREQ => 50.0)
                       port map(reset => rst_i,
                                clk => clk_i,
                                addr => sdram_cntrlr_addr,
                                data => std_logic_vector(wb_dat_o),
                                we => sdram_cntrlr_we,
                                req => sdram_cntrlr_req,
                                ack => sdram_cntrlr_ack,
                                valid => sdram_cntrlr_valid,
                                q => sdram_cntrlr_q,
                                
                                sdram_a => sdram_a,
                                sdram_ba => sdram_ba,
                                sdram_dq => sdram_d,
                                sdram_cke => sdram_cke,
                                sdram_cs_n => sdram_csn,
                                sdram_ras_n => sdram_rasn,
                                sdram_cas_n => sdram_casn,
                                sdram_we_n => sdram_wen,
                                sdram_dqml => sdram_dqm(0),
                                sdram_dqmh => sdram_dqm(1));

	process(wb_adr, wb_we_o, sdram_cntrlr_q)
	begin
		wb_dat_i <= (others => '0');
		sdram_cntrlr_we <= '0';
		sdram_cntrlr_req <= '0';
		if (wb_adr(31 downto 23) = X"01") then
			sdram_cntrlr_we <= wb_we_o;
			wb_dat_i <= std_ulogic_vector(sdram_cntrlr_q);
			sdram_cntrlr_req <= '1';
		end if;
	end process;
	
	sdram_cntrlr_addr <= unsigned(wb_adr(22 downto 0));
	wb_ack_i <= sdram_cntrlr_ack when sdram_cntrlr_we = '1' else sdram_cntrlr_valid;
	wb_err_i <= '0';

  -- GPIO output --
  --gpio_o <= con_gpio_o(7 downto 0);
	led <= con_gpio_o(7 downto 0);
	rstn_i <= not btn(6) and clk_lock;
	rst_i <= btn(6) and clk_lock;

end architecture;
