--=============================================================================
-- @file mandelbrot_tb.vhdl
--=============================================================================
-- Standard library
library ieee;
library std;
-- Standard packages
use std.env.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- mandelbrot_tb
--
-- @brief This file specifies the testbench of the mandelbrot block
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR MANDELBROT_TB
--=============================================================================
entity mandelbrot_tb is
end entity mandelbrot_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--===========================================================================
architecture rtl of mandelbrot_tb is

--=============================================================================
-- TYPE AND CONSTANT DECLARATIONS
--=============================================================================

  type int_file is file of integer;

  constant CLK_HIGH : time := 4 ns;
  constant CLK_LOW  : time := 4 ns;
  constant CLK_PER  : time := CLK_LOW + CLK_HIGH;
  constant CLK_STIM : time := 1 ns;

--=============================================================================
-- SIGNAL DECLARATIONS
--=============================================================================

  signal CLKxCI : std_logic := '0';
  signal RSTxRI : std_logic := '1';

  signal WExS   : std_logic;
  signal XxD    : unsigned(COORD_BW - 1 downto 0);
  signal YxD    : unsigned(COORD_BW - 1 downto 0);
  signal ITERxD : unsigned(MEM_DATA_BW - 1 downto 0);

--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
  component mandelbrot is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      WExSO   : out std_logic;
      XxDO    : out unsigned(COORD_BW - 1 downto 0);
      YxDO    : out unsigned(COORD_BW - 1 downto 0);
      ITERxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
    );
  end component mandelbrot;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- COMPONENT INSTANTIATIONS
--=============================================================================
-------------------------------------------------------------------------------
-- The design under test
-------------------------------------------------------------------------------
  dut: mandelbrot
    port map (
      CLKxCI => CLKxCI,
      RSTxRI => RSTxRI,

      WExSO   => WExS,
      XxDO    => XxD,
      YxDO    => YxD,
      ITERxDO => ITERxD
    );

--=============================================================================
-- CLOCK PROCESS
-- Process for generating the clock signal
--=============================================================================
  p_clock: process is
    begin
    CLKxCI <= '0';
    wait for CLK_LOW;
    CLKxCI <= '1';
    wait for CLK_HIGH;
  end process p_clock;

--=============================================================================
-- RESET PROCESS
-- Process for generating initial reset
--=============================================================================
  p_reset: process is
  begin
    RSTxRI <= '1';
    wait until CLKxCI'event and CLKxCI = '1'; -- Align to clock
    wait for (2*CLK_PER + CLK_STIM);
    RSTxRI <= '0';
    wait;
  end process p_reset;

--=============================================================================
-- IMAGE SAMPLING PROCESSS
-- Reads out the generated image
--=============================================================================
  p_write: process is
    file img_data_file : int_file open write_mode is "ImgDataFile";
    variable pixel_count : integer := 0;
  begin
    wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';

    L1 : loop
      exit L1 when (XxD = HS_DISPLAY - 1 and YxD = VS_DISPLAY - 1);

      wait until CLKxCI'event and CLKxCI = '1' and WExS = '1';
      pixel_count := pixel_count + 1;
      WRITE(img_data_file, to_integer(ITERxD));

    end loop;

    file_close(img_data_file);
    report "Completed Writing Image File";
    report "Mandelbrot created " & integer'image(pixel_count) & " pixel values. Expected " & integer'image(HS_DISPLAY * VS_DISPLAY);
    stop(0);
  end process p_write;

end architecture rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
