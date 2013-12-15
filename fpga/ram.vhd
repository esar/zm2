----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:49:31 12/16/2007 
-- Design Name: 
-- Module Name:    dp_video_ram - rtl 
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
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main_ram is
	Port(
		clock : in STD_LOGIC;
		addr : in STD_LOGIC_VECTOR(14 downto 0);
		di : in STD_LOGIC_VECTOR(7 downto 0);
		do : out STD_LOGIC_VECTOR(7 downto 0);
		WE_n : in STD_LOGIC;
		CE : in STD_LOGIC
	);
end main_ram;

architecture rtl of main_ram is
	type ram_array is array(0 to 32767) of std_logic_vector(7 downto 0);
	signal ram : ram_array;
begin

	process(clock)
	begin
		if rising_edge(clock) then
			if CE = '1' then
				if WE_n = '1' then
					do <= ram(to_integer(unsigned(addr)));
				else
					ram(to_integer(unsigned(addr))) <= di;
				end if;
			end if;
		end if;
	end process;

end rtl;

