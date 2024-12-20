--=============================================================================
-- @file vga_controller.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- vga_controller
--
-- @brief This file specifies a VGA controller circuit
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR VGA_CONTROLLER
--=============================================================================
entity vga_controller is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    -- Data/color input
    RedxSI   : in std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSI : in std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSI  : in std_logic_vector(COLOR_BW - 1 downto 0);

    -- Coordinate output
    XCoordxDO : out unsigned(COORD_BW - 1 downto 0);
    YCoordxDO : out unsigned(COORD_BW - 1 downto 0);

    -- Timing output
    HSxSO : out std_logic;
    VSxSO : out std_logic;

    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end vga_controller;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of vga_controller is

  constant HS_TOTAL : natural := HS_PULSE + HS_BACK_PORCH + HS_DISPLAY + HS_FRONT_PORCH;
  constant VS_TOTAL : natural := VS_PULSE + VS_BACK_PORCH + VS_DISPLAY + VS_FRONT_PORCH;

  constant HS_AFTER_BACK  : natural := HS_PULSE + HS_BACK_PORCH;
  constant VS_AFTER_BACK  : natural := VS_PULSE + VS_BACK_PORCH;

  constant HS_BEFORE_FRONT : natural := HS_PULSE + HS_BACK_PORCH + HS_DISPLAY;
  constant VS_BEFORE_FRONT : natural := VS_PULSE + VS_BACK_PORCH + VS_DISPLAY;

  -- signals for counters
  signal HCntxDP : unsigned(COORD_BW - 1 downto 0) := (others => '0');
  signal VCntxDP : unsigned(COORD_BW - 1 downto 0) := (others => '0');

  -- signals for sync signals
  signal HSyncxDN : std_logic; 
  signal VSyncxDN : std_logic;
  signal HSyncxDP : std_logic := '0';
  signal VSyncxDP : std_logic := '0';

  -- signals for color output
  signal RedxDN   : std_logic_vector(COLOR_BW - 1 downto 0);
  signal GreenxDN : std_logic_vector(COLOR_BW - 1 downto 0);
  signal BluexDN  : std_logic_vector(COLOR_BW - 1 downto 0);
  signal RedxDP   : std_logic_vector(COLOR_BW - 1 downto 0) := (others => '0');
  signal GreenxDP : std_logic_vector(COLOR_BW - 1 downto 0) := (others => '0');
  signal BluexDP  : std_logic_vector(COLOR_BW - 1 downto 0) := (others => '0');

  -- signals for coordinate output
  signal XCoordxDP : unsigned(COORD_BW - 1 downto 0);
  signal YCoordxDP : unsigned(COORD_BW - 1 downto 0);

  signal active_area : std_logic := '0'; -- High during the visible area

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  -- output assignments
  HSxSO <= HSyncxDP;
  VSxSO <= VSyncxDP;

  RedxSO   <= RedxDP;
  GreenxSO <= GreenxDP;
  BluexSO  <= BluexDP;

  XCoordxDO <= XCoordxDP;
  YCoordxDO <= YCoordxDP;

  -- SYNC PULSE | BACK PORCH | DISPLAY | FRONT PORCH 
  active_area <= '1' when ((HCntxDP >= HS_AFTER_BACK and HCntxDP < HS_BEFORE_FRONT)
                            and (VCntxDP >= VS_AFTER_BACK and VCntxDP < VS_BEFORE_FRONT)) else '0';

  HSyncxDN <= HS_POLARITY when (HCntxDP < HS_PULSE) else
                          not HS_POLARITY;

  VSyncxDN <= VS_POLARITY when (VCntxDP < VS_PULSE) else
                          not VS_POLARITY;

  -- DFFs for sync signals and RGB output
  process(CLKxCI, RSTxRI)
  begin
    if RSTxRI = '1' then
      HSyncxDP  <= '0';
      VSyncxDP  <= '0';
      RedxDP    <= (others => '0');
      GreenxDP  <= (others => '0');
      BluexDP   <= (others => '0');
      XCoordxDP <= (others => '0');
      YCoordxDP <= (others => '0');
    elsif rising_edge(CLKxCI) then
      HSyncxDP  <= HSyncxDN;
      VSyncxDP  <= VSyncxDN; 
      RedxDP    <= RedxDN;
      GreenxDP  <= GreenxDN;
      BluexDP   <= BluexDN;
      XCoordxDP <= HCntxDP - HS_PULSE - HS_BACK_PORCH;
      YCoordxDP <= VCntxDP - VS_PULSE - VS_BACK_PORCH;
    end if;
  end process;

  -- Horizontal and vertical counters
  process(CLKxCI, RSTxRI)
  begin
    if RSTxRI = '1' then
      HCntxDP <= (others => '0');
      VCntxDP <= (others => '0');
    elsif rising_edge(CLKxCI) then
      -- Horizontal counter == column
      if HCntxDP = HS_TOTAL - 1 then
        HCntxDP <= (others => '0'); -- Loop around
        -- Vertical counter == row
        if VCntxDP = VS_TOTAL - 1 then
          VCntxDP <= (others => '0'); -- Loop around
        else
          VCntxDP <= VCntxDP + 1;
        end if;
      else
        HCntxDP <= HCntxDP + 1;
      end if;
    end if;
  end process;

  -- RGB output
  process(all) 
  begin
    if active_area = '1' then
      -- Load the input colors during the active area
      RedxDN   <= RedxSI;
      GreenxDN <= GreenxSI;
      BluexDN  <= BluexSI;
    else
      -- Display black outside the visible area (front porch, back porch, sync pulse)
      RedxDN   <= (others => '0');
      GreenxDN <= (others => '0');
      BluexDN  <= (others => '0');
    end if;
  end process;
  
end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
