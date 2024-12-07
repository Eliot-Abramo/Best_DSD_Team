--=============================================================================
-- @file pong_fsm.vhdl
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
-- pong_fsm
--
-- @brief This file specifies a basic circuit for the pong game. Note that coordinates are counted
-- from the upper left corner of the screen.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR PONG_FSM
--=============================================================================
entity pong_fsm is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    -- Controls from push buttons
    LeftxSI  : in std_logic;
    RightxSI : in std_logic;

    -- Coordinate from VGA
    VgaXxDI : in unsigned(COORD_BW - 1 downto 0);
    VgaYxDI : in unsigned(COORD_BW - 1 downto 0);

    -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
    VSEdgexSI : in std_logic;

    -- Ball and plate coordinates
    BallXxDO  : out unsigned(COORD_BW - 1 downto 0);
    BallYxDO  : out unsigned(COORD_BW - 1 downto 0);
    PlateXxDO : out unsigned(COORD_BW - 1 downto 0)
  );
end pong_fsm;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_fsm is

-- TODO: Implement your code here
  CONSTANT BALL_X         : unsigned(COORD_BW - 1 DOWN TO 0) := to_unsigned(HS_DISPLAY/2, COORD_BW);
  CONSTANT BALL_Y         : unsigned(COORD_BW - 1 DOWN TO 0) := to_unsigned(HS_DISPLAY/2, COORD_BW);
  CONSTANT PLATE_INIT_X   : unsigned(COORD_BW - 1 DOWN TO 0) := to_unsigned(HS_DISPLAY/2, COORD_BW);

  SIGNAL BumpTop, BumpBottom, BumpLeft, BumpRight, BumpPlate, BumpUpLeft, BumpUpRight : std_vector;
  
  -- Current state of objects
  SIGNAL BallXxDP, BallYxDP, PlateXxDP : unsigned(COORD_BW - 1 DOWNTO 0);

  -- Future state of objects
  SIGNAL BallXxDN, BallYxDN            : unsigned(COORD_BW - 1 DOWNTO 0);

  -- States of FSM
  TYPE GameControl IS (GameStart, GameEnd, BallUpLeft, BallUpRight, BallDownLeft, BallDownRight);
  SIGNAL FsmStatexDP, FsmStatexDN : GameControl;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

-- TODO: Implement your code here

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
