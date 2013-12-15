----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:30:04 12/09/2007 
-- Design Name: 
-- Module Name:    character_generator - rtl 
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

entity character_generator is
	Port(
		clock : in  STD_LOGIC;
		hvalid : in STD_LOGIC;
		vvalid : in STD_LOGIC;
		hposition : in  STD_LOGIC_VECTOR (11 downto 0);
		vposition : in  STD_LOGIC_VECTOR (11 downto 0);
		frame_count : in STD_LOGIC_VECTOR(7 downto 0);
		vid_ram_addr : out  STD_LOGIC_VECTOR (11 downto 0);
		vid_ram_data : in  STD_LOGIC_VECTOR (7 downto 0);
		data : out  STD_LOGIC_VECTOR (7 downto 0);
		
		a : in STD_LOGIC_VECTOR(1 downto 0);
		di : in STD_LOGIC_VECTOR(7 downto 0);
		do : out STD_LOGIC_VECTOR(7 downto 0);
		CE : in STD_LOGIC;
		WE_n : in STD_LOGIC
	);
end character_generator;

architecture rtl of character_generator is
	signal row_start_addr : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal current_addr : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal char_rom_addr : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal char_rom_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

	signal cursor_data : STD_LOGIC_VECTOR(7 downto 0);
	
	signal reg_cursor_x : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
	signal reg_cursor_y : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
	signal reg_cursor_e : STD_LOGIC_VECTOR(7 downto 0) := "11111111";
	
	signal CE_rcx : STD_LOGIC;
	signal CE_rcy : STD_LOGIC;
	signal CE_rce : STD_LOGIC;
begin

	Inst_character_rom : entity work.character_rom PORT MAP(CLK => clock, ADDR => char_rom_addr, DATA => char_rom_data);

	process(clock)
	begin
		if rising_edge(clock) then
			if vvalid = '0' then
				row_start_addr <= (others => '0');
				current_addr <= (others => '0');
			elsif hvalid = '0' then
				if vposition(3 downto 0) = "1111" then
					row_start_addr <= current_addr;
				else
					current_addr <= row_start_addr;
				end if;
			elsif hposition(2 downto 0) = "001" then
				current_addr <= current_addr + 1;
			end if;
		end if;
	end process;

	process(clock)
	begin
		if rising_edge(clock) then
			if CE_rcx = '1' then
				if WE_n = '0' then
					reg_cursor_x <= di;
				end if;
			end if;
		end if;
	end process;

	process(clock)
	begin
		if rising_edge(clock) then
			if CE_rcy = '1' then
				if WE_n = '0' then
					reg_cursor_y <= di;
				end if;
			end if;
		end if;
	end process;

	process(clock)
	begin
		if rising_edge(clock) then
			if CE_rce = '1' then
				if WE_n = '0' then
					reg_cursor_e <= di;
				end if;
			end if;
		end if;
	end process;

	CE_rcx <= '1' when CE = '1' and a = 0 else '0';
	CE_rcy <= '1' when CE = '1' and a = 1 else '0';
	CE_rce <= '1' when CE = '1' and a = 2 else '0';
	do <=	reg_cursor_x when CE_rcx = '1' else
			reg_cursor_y when CE_rcy = '1' else
			reg_cursor_e when CE_rce = '1' else
			"00000000";

	cursor_data <= "11111111" when	reg_cursor_e(1) = '1' and
												frame_count(5) = '1' and 
												vposition(3 downto 2) = "11" and 
												hposition(10 downto 3) = reg_cursor_x and 
												vposition(11 downto 4) = reg_cursor_y 
												else "00000000";

	vid_ram_addr <= current_addr;
	char_rom_addr <= vid_ram_data & vposition(3 downto 0);
	data <= char_rom_data xor cursor_data;

end rtl;

