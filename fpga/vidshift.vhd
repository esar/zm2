----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:07:55 12/09/2007 
-- Design Name: 
-- Module Name:    vidshift - rtl 
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

entity vidshift is
    Port ( clock : in  STD_LOGIC;
           load : in  STD_LOGIC;
           pin : in  STD_LOGIC_VECTOR (7 downto 0);
           sout : out  STD_LOGIC);
end vidshift;

architecture rtl of vidshift is
	signal data : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
begin
	process(clock)
	begin
		if rising_edge(clock) then
			if load = '1' then
				data <= pin;
			else
				data <= data(6 downto 0) & '0';
			end if;
		end if;
	end process;
	
	sout <= data(7);
end architecture rtl;


