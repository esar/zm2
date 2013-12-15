----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:57:09 12/05/2007 
-- Design Name: 
-- Module Name:    vid_timer - rtl 
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

entity vid_timer is
	Generic (
		H_FRONT_BORDER_CLKS,
		H_VIDEO_CLKS,
		H_BACK_BORDER_CLKS,
		H_FRONT_PORCH_CLKS,
		H_SYNC_CLKS,
		H_BACK_PORCH_CLKS,
		H_SYNC_POLARITY,
		V_FRONT_BORDER_CLKS,
		V_VIDEO_CLKS,
		V_BACK_BORDER_CLKS,
		V_FRONT_PORCH_CLKS,
		V_SYNC_CLKS,
		V_BACK_PORCH_CLKS,
		V_SYNC_POLARITY : integer);
				
    Port ( clock : in  STD_LOGIC;
           hposition : out  STD_LOGIC_VECTOR (11 downto 0);
			  vposition : out STD_LOGIC_VECTOR(11 downto 0);
           hsync : out  STD_LOGIC;
			  vsync : out STD_LOGIC;
			  hvalid : out STD_LOGIC;
			  vvalid : out STD_LOGIC;
			  frame_count : out STD_LOGIC_VECTOR(7 downto 0));
end vid_timer;

architecture rtl of vid_timer is
	signal hcount_val: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal vcount_val: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal fcount_val: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

	constant H_TOTAL_CLKS : integer :=	H_FRONT_BORDER_CLKS +
													H_VIDEO_CLKS +
													H_BACK_BORDER_CLKS +
													H_FRONT_PORCH_CLKS +
													H_SYNC_CLKS +
													H_BACK_PORCH_CLKS;
	constant H_VALID_START : integer := 0;
	constant H_VALID_END : integer := H_VALID_START + H_VIDEO_CLKS;
	constant H_SYNC_START : integer :=	H_VIDEO_CLKS +
													H_BACK_BORDER_CLKS +
													H_FRONT_PORCH_CLKS;
	constant H_SYNC_END : integer :=	H_SYNC_START + H_SYNC_CLKS;
	
	constant V_TOTAL_CLKS : integer :=	V_FRONT_BORDER_CLKS +
													V_VIDEO_CLKS +
													V_BACK_BORDER_CLKS +
													V_FRONT_PORCH_CLKS +
													V_SYNC_CLKS +
													V_BACK_PORCH_CLKS;
	constant V_VALID_START : integer := 0;
	constant V_VALID_END : integer := V_VALID_START + V_VIDEO_CLKS;
	constant V_SYNC_START : integer :=	V_VIDEO_CLKS +
													V_BACK_BORDER_CLKS +
													V_FRONT_PORCH_CLKS;
	constant V_SYNC_END : integer :=	V_SYNC_START + V_SYNC_CLKS;
begin

	hcount: process(clock) is
	begin
			if rising_edge(clock) then
				if hcount_val = H_TOTAL_CLKS then
					hcount_val <= (others => '0');
				else
					hcount_val <= hcount_val + 1;
				end if;
			end if;
	end process hcount;
	
	vcount: process(clock) is
	begin
			if rising_edge(clock) then
				if vcount_val = V_TOTAL_CLKS then
					vcount_val <= (others => '0');
					fcount_val <= fcount_val + 1;
				elsif hcount_val = H_SYNC_START then
					vcount_val <= vcount_val + 1;
				end if;
			end if;
	end process vcount;

	hlatch: process(clock, hcount_val) is
	begin
		if rising_edge(clock) then
			if hcount_val = H_SYNC_START then
				hsync <= '1';
			elsif hcount_val = H_SYNC_END then
				hsync <= '0';
			end if;
		end if;
	end process hlatch;

	hvlatch: process(clock, hcount_val) is
	begin
		if rising_edge(clock) then
			if hcount_val = H_VALID_START then
				hvalid <= '1';
			elsif hcount_val = H_VALID_END then
				hvalid <= '0';
			end if;
		end if;
	end process hvlatch;
	
	vlatch: process(clock, vcount_val) is
	begin
		if rising_edge(clock) then
			if vcount_val = V_SYNC_START then
				vsync <= '1';
			elsif vcount_val = V_SYNC_END then
				vsync <= '0';
			end if;
		end if;
	end process vlatch;

	vvlatch: process(clock, vcount_val) is
	begin
		if rising_edge(clock) then
			if vcount_val = V_VALID_START then
				vvalid <= '1';
			elsif vcount_val = V_VALID_END then
				vvalid <= '0';
			end if;
		end if;
	end process vvlatch;

--	hsync <=	'0' when hcount_val = hsync_start else
--				'1' when hcount_val = hsync_end;
--	vsync <= '0' when vcount_val = vsync_start else
--				'1' when vcount_val = vsync_end;
--	hvalid <= '1' when hcount_val = hvalid_start else
--				'0' when hcount_val = hvalid_end;
--	vvalid <= '1' when vcount_val = vvalid_start else
--				'0' when vcount_val = vvalid_end;
	
	hposition <= hcount_val;
	vposition <= vcount_val;
	frame_count <= fcount_val;

end rtl;

