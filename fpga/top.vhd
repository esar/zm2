----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:01:37 12/10/2013 
-- Design Name: 
-- Module Name:    top - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    Port ( CLK : in  STD_LOGIC;
           HSYNC : out  STD_LOGIC;
           VSYNC : out  STD_LOGIC;
           GREEN : out  STD_LOGIC;
           PS2_DAT : in  STD_LOGIC;
           PS2_CLK : in  STD_LOGIC);
end top;

architecture Behavioral of top is

signal zm_clock : STD_LOGIC;
signal zm_red : STD_LOGIC_VECTOR(3 downto 0);
signal zm_green : STD_LOGIC_VECTOR(3 downto 0);
signal zm_blue : STD_LOGIC_VECTOR(3 downto 0);

begin
	Inst_dcm: entity work.DCM32to25
		PORT MAP(
			CLK_IN1 => CLK,
			CLK_OUT1 => zm_clock
		);
 
	Inst_zm: entity work.zm
		PORT MAP(
			clock     => zm_clock, 
			hsync     => HSYNC, 
			vsync     => VSYNC, 
			red       => zm_red,
			green     => zm_green,
			blue      => zm_blue,
			ps2_data  => PS2_DAT,
			ps2_clock => PS2_CLK
		);
		
	GREEN <= zm_green(0) or zm_green(1) or zm_green(2) or zm_green(3);
	
end Behavioral;

