----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:46:03 12/29/2007 
-- Design Name: 
-- Module Name:    ps2kb_controller - rtl 
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

entity ps2kb_controller is
	Port(
		ps2_data : in  STD_LOGIC;
		ps2_clock : in  STD_LOGIC;
			
		clock : in STD_LOGIC;
		a : in STD_LOGIC_VECTOR(15 downto 0);
		di : in STD_LOGIC_VECTOR(7 downto 0);
		do : out  STD_LOGIC_VECTOR (7 downto 0);
		CE : in STD_LOGIC;
		WE_n : in STD_LOGIC;
		int : out  STD_LOGIC
	);
end ps2kb_controller;

architecture rtl of ps2kb_controller is
	signal shift_reg_data : STD_LOGIC_VECTOR(10 downto 0);
	signal shift_counter : STD_LOGIC_VECTOR(3 downto 0);
	
	signal key_data : STD_LOGIC_VECTOR(7 downto 0);
	
	signal recv_complete_async : STD_LOGIC;
	signal recv_complete_resync1 : STD_LOGIC;
	signal recv_complete_resync2 : STD_LOGIC;
	signal recv_complete_prev : STD_LOGIC;
	signal recv_complete : STD_LOGIC;
	
	signal recv_count_complete : STD_LOGIC := '0';
	
begin

	-- shift register to receive data from keyboard
	process(ps2_clock)
	begin
		if falling_edge(ps2_clock) then
			shift_reg_data <= ps2_data & shift_reg_data(10 downto 1);
		end if;
	end process;

	-- counter to signal when recv is complete
	process(ps2_clock, recv_complete)
	begin
		if recv_complete = '1' then
			shift_counter <= "1011";
		elsif falling_edge(ps2_clock) then
			if recv_count_complete = '0' then
				shift_counter <= shift_counter - 1;
			end if;
		end if;
	end process;

	recv_count_complete <= '1' when shift_counter = 0 else '0';
	
	recv_complete_async <= '1' when	shift_counter = 0 and				-- at least 12 bits received
												shift_reg_data(10) = '1' and		-- and stop bit is high
												shift_reg_data(0) = '0'				-- and start bit is low
									else '0';

	-- resync and one-shot recv complete signal
	process(clock)
	begin
		if rising_edge(clock) then
			recv_complete_resync1 <= recv_complete_async;
			recv_complete_resync2 <= recv_complete_resync1;
			recv_complete_prev <= recv_complete_resync2;
			if recv_complete_prev = '0' and recv_complete_resync2 = '1' then
				recv_complete <= '1';
			else
				recv_complete <= '0';
			end if;
		end if;
	end process;

	-- latch the received data
	process(clock)
	begin
		if rising_edge(clock) then
			if recv_complete = '1' then
				key_data <= shift_reg_data(8 downto 1);
			end if;
		end if;
	end process;

	-- signal interrupt when recv complete, release when read occurs
	process(clock)
	begin
		if rising_edge(clock) then
			if recv_complete = '1' then
				int <= '1';
			elsif CE = '1' and WE_n = '1' then
				int <= '0';
			end if;
		end if;
	end process;

	-- read latched data
	do <= key_data;

end rtl;

