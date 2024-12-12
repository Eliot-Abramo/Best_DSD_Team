--=============================================================================
-- @file vga_controller_tb.vhdl
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
-- vga_controller_tb
--
-- @brief This file specifies the testbench of the VGA controller
--
-- We verify the following:
--  * The width of the sync pulses
--  * The length of the horizontal line
--  * The duration of a frame
--
-- Note that until the first verticalical sync is observed, the measured length is
-- most likely not correct (but this is okay!).
--
-- We verify based on the number of clock cycles, but we also print the expected
-- and observed time in nanoseconds.
--
-- The testbench contains golden values.
--
-- For the timing parameters, see http://tinyvga.com/vga-timing/1024x768@70Hz
-- As these parameters use a negative polarity for the sync signals, we count the
-- duration from the falling-edge of the sync signals to their rising-edge
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR VGA_CONTROLLER_TB
--=============================================================================
entity vga_controller_tb is
end entity vga_controller_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of vga_controller_tb is

--=============================================================================
-- TYPE AND CONSTANT DECLARATIONS
--=============================================================================
  constant CLK_HIGH : time := 6.667 ns; -- Clock is 75 MHz, approximate with 6.667 ns, 74.996 MHz
  constant CLK_LOW  : time := 6.667 ns;
  constant CLK_PER  : time := CLK_LOW + CLK_HIGH;
  constant CLK_STIM : time := 1 ns;

  constant FRAME_WIDTH  : integer := HS_DISPLAY + HS_FRONT_PORCH + HS_PULSE + HS_BACK_PORCH; -- See http://tinyvga.com/vga-timing/1024x768@70Hz
  constant FRAME_HEIGHT : integer := (VS_DISPLAY + VS_FRONT_PORCH + VS_PULSE + VS_BACK_PORCH)*FRAME_WIDTH;

--=============================================================================
-- SIGNAL DECLARATIONS
--=============================================================================

  signal CLKxCI : std_logic := '0';
  signal RSTxRI : std_logic := '1';

  signal XCoordxDO : unsigned(COORD_BW - 1 downto 0);
  signal YCoordxDO : unsigned(COORD_BW - 1 downto 0);

  signal HSxSO : std_logic;
  signal VSxSO : std_logic;

  signal RedxSO   : std_logic_VECTOR(COLOR_BW - 1 downto 0);
  signal GreenxSO : std_logic_VECTOR(COLOR_BW - 1 downto 0);
  signal BluexSO  : std_logic_VECTOR(COLOR_BW - 1 downto 0);

--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
  component vga_controller is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      -- Data/color input
      RedxSI   : in std_logic_VECTOR(COLOR_BW - 1 downto 0);
      GreenxSI : in std_logic_VECTOR(COLOR_BW - 1 downto 0);
      BluexSI  : in std_logic_VECTOR(COLOR_BW - 1 downto 0);

      -- Coordinate output
      XCoordxDO : out unsigned(COORD_BW - 1 downto 0);
      YCoordxDO : out unsigned(COORD_BW - 1 downto 0);

      -- Timing output
      HSxSO : out std_logic;
      VSxSO : out std_logic;

      -- Data/color output
      RedxSO   : out std_logic_VECTOR(COLOR_BW - 1 downto 0);
      GreenxSO : out std_logic_VECTOR(COLOR_BW - 1 downto 0);
      BluexSO  : out std_logic_VECTOR(COLOR_BW - 1 downto 0)
    );
  end component vga_controller;

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
  dut: vga_controller
    port map (
      CLKxCI => CLKxCI,
      RSTxRI => RSTxRI,

      -- 111111111111 corresponds to white
      RedxSI   => "1111",  
      GreenxSI => "1111",
      BluexSI  => "1111",

      HSxSO => HSxSO,
      VSxSO => VSxSO,

      XCoordxDO => XCoordxDO,
      YCoordxDO => YCoordxDO,

      RedxSO   => RedxSO,
      GreenxSO => GreenxSO,
      BluexSO  => BluexSO
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
-- HSYNC VERIFICATION PROCESSS
-- Verifies the length of the pulse and line
--=============================================================================
  p_verify_hsync: process is

    variable ClockCNT : integer := 0; -- Number of clock cycles

    variable HSPrev : std_logic := '0'; -- Previous value of HSxSO

    variable HSyncCCHighPrev : integer := 0; -- Cycle where output went high
    variable HSyncCCLow      : integer := 0; -- Cycle where output went low

    variable HSyncPulseWidthCC : integer := 0; -- Horizontal sync pulse width in clock cycles
    variable HLineWidthCC      : integer := 0; -- Horizontal line width in clock cycles

    variable HSyncPulseWidthSec : time := 0 ns; -- Horizontal sync pulse width in seconds
    variable HLineWidthSec      : time := 0 ns; -- Horizontal line width in seconds

    variable HSyncPulseWidthCCGOLDEN : integer := HS_PULSE;    -- 136, See http://tinyvga.com/vga-timing/1024x768@70Hz
    variable HLineWidthCCGOLDEN      : integer := FRAME_WIDTH; -- 1328

    -- 136/(75 MHz)*1ns = 1813.333333 ns but simulation time resolution too low, so we get 136*(2*6.667 ns) = 1813.424 ns
    -- 1328/(75 MHz)*1ns = 17706.666666667 ns but simulation time resolution too low, so we get 1328*(2*6.667 ns) = 17707.552 ns
    variable HSyncPulseWidthSecGOLDEN : time := 1813.424 ns;
    variable HLineWidthSecGOLDEN      : time := 17707.552 ns;

    variable HSyncPulseWidthNumErrors : integer := 0; -- Number of errors for horizontal sync pulse widths
    variable HLineWidthNumErrors      : integer := 0; -- Number of errors for horizontal line widths

    variable HSyncPulseWidthNumCorrect : integer := 0; -- Number of correct horizontal sync pulse widths
    variable HLineWidthNumCorrect      : integer := 0; -- Number of correct horizontal line widths

  begin

    wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;

    while now < 50 ms loop

      HSPrev := HSxSO;

      -- Save prev pulse and wait 1 CC, then check if falling/rising edges since last cycle
      wait until CLKxCI'event and CLKxCI = '1';
      ClockCNT := ClockCNT + 1;
      wait for CLK_STIM;

      -- Falling edge of HSxSO
      if HSxSO = '0' and HSPrev = '1' then
        HSyncCCLow := ClockCNT;
      end if;

      -- Rising edge of HSxSO
      if HSxSO = '1' and HSPrev = '0' then

        HSyncPulseWidthCC  := ClockCNT - HSyncCCLow;      -- Polarity is negative so pulse width is from falling edge to rising edge
        HLineWidthCC       := ClockCNT - HSyncCCHighPrev; -- For line width, count from the rising edge to the rising edge of sync
        HSyncPulseWidthSec := HSyncPulseWidthCC  * CLK_PER;
        HLineWidthSec      := HLineWidthCC * CLK_PER;

        HSyncCCHighPrev := ClockCNT;

        -- Error checking
        if HSyncPulseWidthCC /= HSyncPulseWidthCCGOLDEN then
          report
            lf & "Horizontal sync pulse width is " & integer'image(HSyncPulseWidthCC) & " CC, expected " & integer'image(HSyncPulseWidthCCGOLDEN) &
            lf & "Horizontal sync pulse width is " & time'image(HSyncPulseWidthSec) & ", expected (approx) " & time'image(HSyncPulseWidthSecGOLDEN) &
            lf
          severity warning;
          HSyncPulseWidthNumErrors := HSyncPulseWidthNumErrors + 1;

        else
          HSyncPulseWidthNumCorrect := HSyncPulseWidthNumCorrect + 1;
        end if;

        if HLineWidthCC /= HLineWidthCCGOLDEN then
          report
            lf & "Horizontal line width is " & integer'image(HLineWidthCC) & " CC, expected " & integer'image(HLineWidthCCGOLDEN) &
            lf & "Horizontal line width is " & time'image(HLineWidthSec) & ", expected (approx) " & time'image(HLineWidthSecGOLDEN) &
            lf
          severity warning;
          HLineWidthNumErrors := HLineWidthNumErrors + 1;

          else
          HLineWidthNumCorrect := HLineWidthNumCorrect + 1;
        end if;
      end if;
    end loop;



    report
      lf & "********************************************************************" &
      lf & "HORIZONTAL SYNC CHECK COMPLETE" &
      lf & "    Got " & integer'image(HSyncPulseWidthNumErrors) & " errors for horizontal pulse width (1 is okay initially)" &
      lf & "    Got " & integer'image(HLineWidthNumErrors) & " errors for horizontal line width (1 is okay initially)" &
      lf & "    Got " & integer'image(HSyncPulseWidthNumCorrect) & " correct for horizontal pulse width" &
      lf & "    Got " & integer'image(HLineWidthNumCorrect) & " correct for horizontal line width" &
      lf & "********************************************************************" &
      lf;

    wait for 1 ms;
    stop(0);

  end process p_verify_hsync;

--=============================================================================
-- VSYNC VERIFICATION PROCESSS
-- Verifies the length of the pulse and frame
--=============================================================================
  p_verify_vsync: process is

    variable ClockCNT : integer := 0;

    variable VSPrev : std_logic := '0';

    variable VSyncCCHighPrev : integer := 0;
    variable VSyncCCLow      : integer := 0;

    variable VSyncPulseWidthCC : integer := 0;
    variable VFrameWidthCC     : integer := 0;

    variable VSyncPulseWidthSec : time := 0 ns;
    variable VFrameWidthSec     : time := 0 ns;

    variable VSyncPulseWidthCCGOLDEN : integer := VS_PULSE*FRAME_WIDTH; -- 7968 See http://tinyvga.com/vga-timing/1024x768@70Hz
    variable VFrameWidthCCGOLDEN     : integer := FRAME_HEIGHT;         -- 1070368

    -- 7968/(75 MHz)*1ns = 106240 ns but simulation time resolution too low, so we get 7968*(2*6.667) = 106245.312 ns
    -- 1070368/(75 MHz)*1ns = 14271573.333333 ns but simulation time resolution too low, so we get 1070368*(2*6.667 ns) = 14272286.912 ns
    variable VSyncPulseWidthSecGOLDEN : time := 106245.312 ns;
    variable VFrameWidthSecGOLDEN     : time := 14272286.912 ns;

    variable VSyncPulseWidthNumErrors : integer := 0;
    variable VFrameWidthNumErrors     : integer := 0;

    variable VSyncPulseWidthNumCorrect : integer := 0;
    variable VFrameWidthNumCorrect     : integer := 0;

  begin

    wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;

    while now < 50 ms loop

      VSPrev := VSxSO;

      -- Save prev pulse and wait 1 CC, then check if falling/rising edges since last cycle
      wait until CLKxCI'event and CLKxCI = '1';
      ClockCNT := ClockCNT + 1;
      wait for CLK_STIM;

      -- Falling edge of VSxSO
      if VSxSO = '0' and VSPrev = '1' then
        VSyncCCLow := ClockCNT;
      end if;

      -- Rising edge of VSxSO


      if VSxSO = '1' and VSPrev = '0' then

        VSyncPulseWidthCC  := ClockCNT - VSyncCCLow;      -- Polarity is negative so pulse width is from falling edge to rising edge
        VFrameWidthCC      := ClockCNT - VSyncCCHighPrev; -- For frame width, count from the rising edge to the rising edge of sync
        VSyncPulseWidthSec := VSyncPulseWidthCC  * CLK_PER;
        VFrameWidthSec     := VFrameWidthCC * CLK_PER;

        VSyncCCHighPrev := ClockCNT;

        -- Error checking
        if VSyncPulseWidthCC /= VSyncPulseWidthCCGOLDEN then
          report
            lf & "Vertical sync pulse width is " & integer'image(VSyncPulseWidthCC) & " CC, expected " & integer'image(VSyncPulseWidthCCGOLDEN) &
            lf & "Vertical sync pulse width is " & time'image(VSyncPulseWidthSec) & ", expected (approx) " & time'image(VSyncPulseWidthSecGOLDEN) &
            lf
          severity warning;
          VSyncPulseWidthNumErrors := VSyncPulseWidthNumErrors + 1;

        else
          VSyncPulseWidthNumCorrect := VSyncPulseWidthNumCorrect + 1;
        end if;

        if VFrameWidthCC /= VFrameWidthCCGOLDEN then
          report
            lf & "Vertical frame width is " & integer'image(VFrameWidthCC) & " CC, expected " & integer'image(VFrameWidthCCGOLDEN) &
            lf & "Vertical frame width is " & time'image(VFrameWidthSec) & ", expected (approx) " & time'image(VFrameWidthSecGOLDEN) &
            lf
          severity warning;
          VFrameWidthNumErrors := VFrameWidthNumErrors + 1;

        else
          VFrameWidthNumCorrect := VFrameWidthNumCorrect + 1;
        end if;
      end if;
    end loop;



    report
      lf & "********************************************************************" &
      lf & "VERTICAL SYNC CHECK COMPLETE" &
      lf & "    Got " & integer'image(VSyncPulseWidthNumErrors) & " errors for vertical pulse width (1 is okay initially)" &
      lf & "    Got " & integer'image(VFrameWidthNumErrors) & " errors for vertical frame width (1 is okay initially)" &
      lf & "    Got " & integer'image(VSyncPulseWidthNumCorrect) & " correct for vertical pulse width" &
      lf & "    Got " & integer'image(VFrameWidthNumCorrect) & " correct for vertical frame width" &
      lf & "********************************************************************" &
      lf;

    wait for 1 ms;
    stop(0);

  end process p_verify_vsync;

end architecture tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
