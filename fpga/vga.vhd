----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:28:27 12/06/2007 
-- Design Name: 
-- Module Name:    vga - rtl 
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

entity vga is
	Port(
		clock : in  STD_LOGIC;
		
		hsync : out  STD_LOGIC;
		vsync : out  STD_LOGIC;
		red : out  STD_LOGIC_VECTOR(3 downto 0);
		green : out  STD_LOGIC_VECTOR(3 downto 0);
		blue : out  STD_LOGIC_VECTOR(3 downto 0);
		
		a : in STD_LOGIC_VECTOR(11 downto 0);
		di : in STD_LOGIC_VECTOR(7 downto 0);
		do : out STD_LOGIC_VECTOR(7 downto 0);
		WE_n : STD_LOGIC;
		CE : in STD_LOGIC
	);
end vga;

architecture rtl of vga is
	signal hposition: STD_LOGIC_VECTOR(11 downto 0);
	signal vposition: STD_LOGIC_VECTOR(11 downto 0);
	signal hvalid : STD_LOGIC;
	signal vvalid : STD_LOGIC;
	signal frame_count : STD_LOGIC_VECTOR(7 downto 0);

	signal shift_pin : STD_LOGIC_VECTOR(7 downto 0);
	signal shift_load : STD_LOGIC;
	signal shift_out : STD_LOGIC;

	signal char_gen_data : STD_LOGIC_VECTOR(7 downto 0);
	
	signal video_ram_addr : STD_LOGIC_VECTOR(11 downto 0);
	signal video_ram_data : STD_LOGIC_VECTOR(7 downto 0);
	
	signal do_chargen : STD_LOGIC_VECTOR(7 downto 0);
	signal CE_chargen : STD_LOGIC;
	
	signal do_vidram : STD_LOGIC_VECTOR(7 downto 0);
	signal CE_vidram : STD_LOGIC;
begin

	Inst_vid_timer: entity work.vid_timer
		GENERIC MAP(	
			H_FRONT_BORDER_CLKS => 8,
			H_VIDEO_CLKS => 640,
			H_BACK_BORDER_CLKS => 8,
			H_FRONT_PORCH_CLKS => 8,
			H_SYNC_CLKS => 96,
			H_BACK_PORCH_CLKS => 40,
			H_SYNC_POLARITY => 0,
			V_FRONT_BORDER_CLKS => 8,
			V_VIDEO_CLKS => 480,
			V_BACK_BORDER_CLKS => 8,
			V_FRONT_PORCH_CLKS => 2,
			V_SYNC_CLKS => 2,
			V_BACK_PORCH_CLKS => 25,
			V_SYNC_POLARITY => 0
		)
		PORT MAP(
			clock => clock,
			hposition => hposition,
			vposition => vposition,
			hsync => hsync,
			vsync => vsync,
			hvalid => hvalid,
			vvalid => vvalid,
			frame_count => frame_count
		);

	Inst_vidshift: entity work.vidshift
		PORT MAP(
			clock => clock, 
			pin => shift_pin, 
			load => shift_load, 
			sout => shift_out
		);

	Inst_character_generator : entity work.character_generator
		PORT MAP(
			clock => clock, 
			hvalid => hvalid,
			vvalid => vvalid,
			hposition => hposition,
			vposition => vposition,
			frame_count => frame_count,
			vid_ram_addr => video_ram_addr,
			vid_ram_data => video_ram_data,
			data => char_gen_data,
			
			a => a(1 downto 0),
			di => di,
			do => do_chargen,
			CE => CE_chargen,
			WE_n => WE_n
		);

	Inst_video_ram : entity work.video_ram
		PORT MAP(
			CLK => clock, 
			ADDR => video_ram_addr, 
			DATA => video_ram_data,
			
			CLK2 => clock,
			ADDR2 => a,
			do => do_vidram,
			di => di,
			CE => CE_vidram,
			WE_n => WE_n
		);

	CE_vidram <= '1' when CE = '1' and a(11 downto 2) /= "1011111111" else '0';
	CE_chargen <= '1' when CE = '1' and a(11 downto 2) = "1011111111" else '0';
	do <=	do_vidram when CE_vidram = '1' else
			do_chargen;

	shift_pin <= char_gen_data;
	shift_load <= '1' when hposition(2 downto 0) = "000" else '0';

	--red <= "0100" when (hposition(3 downto 0) = "0000" or vposition(3 downto 0) = "0000") and hvalid = '1' and vvalid = '1' else "0000";
	red <= "0000";
	green(3 downto 0) <= "1111" when shift_out = '1' and hvalid = '1' and vvalid = '1' else "0000";
	blue <= "0000";

end rtl;

