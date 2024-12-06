
--=============================================================================
-- @file dsd_prj_pkg.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
--
-- dsd_prj_pkg
--
-- @brief This file specifies the parameters used for the VGA controller, pong and mandelbrot circuits
--
-- The parameters are given here http://tinyvga.com/vga-timing/1024x768@70Hz
-- with a more elaborate explanation at https://projectf.io/posts/video-timings-vga-720p-1080p/
--=============================================================================

package dsd_prj_pkg is

  -- Bitwidths for screen coordinate and colors
  constant COLOR_BW : natural := 4;  -- Each colour LED is 4 bits
  constant COORD_BW : natural := 12; -- 12 bits should accommodate any screen size we can consider

  -- Horizontal timing parameters
  constant HS_DISPLAY     : natural   := 1024; -- Display width in pixels
  constant HS_FRONT_PORCH : natural   := 24;   -- Horizontal sync front porch length in number of pixels (clock-cycles)
  constant HS_PULSE       : natural   := 136;  -- Horizontal sync pulse length in number of pixels (clock-cycles)
  constant HS_BACK_PORCH  : natural   := 144;  -- Horizontal sync back porch length in number of pixels (clock-cycles)
  constant HS_POLARITY    : std_logic := '0';  -- Polarity indicates value of sync signal in sync period
                                               -- with negative polarity meaning active LOW.

  -- Vertical timing parameters
  constant VS_DISPLAY     : natural   := 768; -- Display height in pixels
  constant VS_FRONT_PORCH : natural   := 3;   -- Vertical sync front porch length in number of horizontal lines
  constant VS_PULSE       : natural   := 6;   -- Vertical sync pulse length in number of horizontal lines
  constant VS_BACK_PORCH  : natural   := 29;  -- Vertical sync back porch length in number of horizontal lines
  constant VS_POLARITY    : std_logic := '0'; -- Vertical sync polarity

  -- Memory parameters
  constant MEM_ADDR_BW : natural := 16;
  constant MEM_DATA_BW : natural := 12; -- 3 * COLOR_BW

  -- Pong parameters (in pixels)
  constant BALL_WIDTH   : natural := 10;
  constant BALL_HEIGHT  : natural := 10;
  constant BALL_STEP_X  : natural := 2;
  constant BALL_STEP_Y  : natural := 2;
  constant PLATE_WIDTH  : natural := 70;
  constant PLATE_HEIGHT : natural := 10;
  constant PLATE_STEP_X : natural := 40;

end package dsd_prj_pkg;
