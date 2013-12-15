----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:50:29 12/30/2007 
-- Design Name: 
-- Module Name:    zm - rtl 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity zm is
	Port(
		clock : in  STD_LOGIC;

		hsync : out  STD_LOGIC;
		vsync : out  STD_LOGIC;
		red : out  STD_LOGIC_VECTOR(3 downto 0);
		green : out  STD_LOGIC_VECTOR(3 downto 0);
		blue : out  STD_LOGIC_VECTOR(3 downto 0);

		ps2_data : in STD_LOGIC;
		ps2_clock : in STD_LOGIC
	);
end zm;

architecture rtl of zm is

	signal reset : STD_LOGIC := '1';
	signal reset_count : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	
	signal data_bus : STD_LOGIC_VECTOR(7 downto 0);
	signal addr_bus : STD_LOGIC_VECTOR(15 downto 0);
	signal irq_n : STD_LOGIC;
	
	signal addr_cpu : STD_LOGIC_VECTOR(23 downto 0);
	signal data_cpu : STD_LOGIC_VECTOR(7 downto 0);
	
	signal int_ps2 : STD_LOGIC;
	signal data_ps2 : STD_LOGIC_VECTOR(7 downto 0);
	
	signal addr_vga : STD_LOGIC_VECTOR(11 downto 0);
	signal data_vga : STD_LOGIC_VECTOR(7 downto 0);
	
	signal addr_ram : STD_LOGIC_VECTOR(14 downto 0);
	signal data_ram : STD_LOGIC_VECTOR(7 downto 0);

	signal addr_rom : STD_LOGIC_VECTOR(13 downto 0);
	signal data_rom : STD_LOGIC_VECTOR(7 downto 0);

	signal RW_n : STD_LOGIC;
	signal CE : STD_LOGIC_VECTOR(3 downto 0);
	
	signal cpu_clk_count : STD_LOGIC_VECTOR(3 downto 0) := "0000";

begin

	Inst_vga : entity work.vga 
		PORT MAP(
			hsync => hsync,
			vsync => vsync,
			red => red,
			green => green,
			blue => blue,
		
			clock => clock, 
			di => data_bus,
			do => data_vga,
			a => addr_vga,
			WE_n => RW_n,
			CE => CE(0)
		);
		
	Inst_ps2 : entity work.ps2kb_controller
		PORT MAP(
			ps2_clock => ps2_clock,
			ps2_data => ps2_data,
		
			clock => clock,
			di => data_bus,
			do => data_ps2,
			a => addr_bus,
			WE_n => RW_n,
			CE => CE(1),
			int => int_ps2
		);

	Inst_ram : entity work.main_ram
		PORT MAP(
			clock => clock,
			addr => addr_ram,
			di => data_bus,
			do => data_ram,
			WE_n => RW_n,
			CE => CE(3)
		);
		
	Inst_rom : entity work.zm2_rom
		PORT MAP(
			CLK => clock,
			ADDR => addr_rom,
			DATA => data_rom,
			ENA => CE(2)
		);
		
	Inst_cpu : entity work.T65
		PORT MAP(
			Mode => "00", -- plain 6502
			Res_n => reset,
			Enable => '1',
			Clk => cpu_clk_count(1), --clock,
			Rdy => '1',
			Abort_n => '1',
			IRQ_n => irq_n,
			NMI_n => '1',
			SO_n => '1',
			R_W_n => RW_n,
			A => addr_cpu,
			DI => data_bus,
			DO => data_cpu
		);


	CE <= "1000" when addr_bus(15) = '0' else                   -- 0 -> 32kb RAM
	      "0100" when addr_bus(15 downto 14) = "10" else        -- 32kb -> 48kb Bank Switched ROM
	      "0010" when addr_bus(15 downto 10) = "110011" else    -- 51kb -> 52kb Keyboard
	      "0001" when addr_bus(15 downto 12) = "1100" else      -- 48kb -> 51kb VGA
	      "0100";                                               -- 52kb -> 64kb System ROM

	data_bus <= data_cpu when RW_n = '0' else
	            data_ram when CE = "1000" else
	            data_rom when CE = "0100" else
	            data_ps2 when CE = "0010" else
	            data_vga;
	
	addr_bus <= addr_cpu(15 downto 0);
	addr_vga <= addr_bus(11 downto 0);
	addr_ram <= addr_bus(14 downto 0);
	addr_rom <= addr_bus(13 downto 0);

	irq_n <= not int_ps2;

	process(clock)
	begin
		if rising_edge(clock) then
			if reset_count = "0001" then
				reset <= '0';
			end if;
			
			if reset_count /= "0100" then
				reset_count <= reset_count + 1;
			else
				reset <= '1';
			end if;
		end if;
	end process;

	process(clock)
	begin
		if rising_edge(clock) then
			cpu_clk_count <= cpu_clk_count + 1;
		end if;
	end process;

end rtl;

