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
  CONSTANT BALL_X_INIT         : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(HS_DISPLAY/2, COORD_BW);
  CONSTANT BALL_Y_INIT         : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(HS_DISPLAY/2, COORD_BW);
  CONSTANT PLATE_X_INIT        : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(HS_DISPLAY/2, COORD_BW);

  SIGNAL BumpTop, BumpBottom, BumpLeft, BumpRight, BumpPlate, BumpUpLeft, BumpUpRight : std_logic;
  
  -- Current state of objects
  SIGNAL BallXxDP, BallYxDP, PlateXxDP : unsigned(COORD_BW - 1 DOWNTO 0);

  -- Future state of objects
  SIGNAL BallXxDN, BallYxDN, PlateXxDN : unsigned(COORD_BW - 1 DOWNTO 0);

  -- States of FSM
  TYPE GameControl IS (GameStart, GameEnd, BallUpLeft, BallUpRight, BallDownLeft, BallDownRight);
  SIGNAL FsmStatexDP, FsmStatexDN : GameControl;
  
   -- Calculate constants used to detect collisions
  constant HalfBallWidth   : unsigned(COORD_BW - 1 downto 0) := to_unsigned(BALL_WIDTH / 2, COORD_BW);
  constant HalfBallHeight  : unsigned(COORD_BW - 1 downto 0) := to_unsigned(BALL_HEIGHT / 2, COORD_BW);

  constant BallTopLimit    : unsigned(COORD_BW - 1 downto 0) := HalfBallHeight + to_unsigned(BALL_STEP_Y, COORD_BW);
  constant BallBottomLimit : unsigned(COORD_BW - 1 downto 0) := to_unsigned(VS_DISPLAY, COORD_BW) - HalfBallHeight - to_unsigned(BALL_STEP_Y, COORD_BW);
  constant BallLeftLimit   : unsigned(COORD_BW - 1 downto 0) := HalfBallWidth + to_unsigned(BALL_STEP_X, COORD_BW);
  constant BallRightLimit  : unsigned(COORD_BW - 1 downto 0) := to_unsigned(HS_DISPLAY, COORD_BW) - HalfBallWidth - to_unsigned(BALL_STEP_X, COORD_BW);
  
  constant PlateYPosition  : unsigned(COORD_BW - 1 downto 0) := to_unsigned(VS_DISPLAY, COORD_BW) - PLATE_HEIGHT - HalfBallHeight - to_unsigned(BALL_STEP_Y, COORD_BW);
  constant PlateHalfWidth  : unsigned(COORD_BW - 1 downto 0) := to_unsigned(PLATE_WIDTH / 2, COORD_BW);

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  -- TODO: Implement your code here
  -- Bump detection signals
  BumpTop     <= '1' when (BallYxDP <= BallTopLimit) else '0';
  BumpBottom  <= '1' when (BallYxDP >= BallBottomLimit) else '0';
  BumpLeft    <= '1' when (BallXxDP <= BallLeftLimit) else '0';
  BumpRight   <= '1' when (BallXxDP >= BallRightLimit) else '0';
  BumpPlate   <= '1' when (BallYxDP >= PlateYPosition and
                           BallXxDP >= PlateXxDP - PlateHalfWidth and
                           BallXxDP <= PlateXxDP + PlateHalfWidth) else '0';
  BumpUpLeft  <= '1' when (BallXxDP = HalfBallWidth and BallYxDP = HalfBallHeight) else '0';
  BumpUpRight <= '1' when (BallXxDP = to_unsigned(HS_DISPLAY, COORD_BW) - HalfBallWidth and BallYxDP = HalfBallHeight) else '0';

  Pong : PROCESS(CLKxCI, RSTxRI, VSEdgexSI) IS
  BEGIN
    IF RSTxRI = '1' THEN
      FsmStatexDP     <= GameStart;
      BallXxDP        <= BALL_X_INIT;
      BallYxDP        <= BALL_Y_INIT;
      PlateXxDP       <= PLATE_X_INIT;
    ELSIF rising_edge(CLKxCI) THEN
      IF VSEdgexSI = '1' THEN
        FsmStatexDP   <= FsmStatexDN;
        BallXxDP      <= BallXxDN;
        BallYxDP      <= BallYxDN;
        PlateXxDP     <= PlateXxDN;
      END IF;
    END IF;
  END PROCESS Pong; 

  PongFsm : PROCESS (ALL) IS
  BEGIN
    FsmStatexDN       <= FsmStatexDP;
    BallXxDN          <= BallXxDP;
    BallYxDN          <= BallYxDP;
    PlateXxDN         <= PlateXxDP;

    -- Update paddle position
    IF (LeftxSI = '1' AND PlateXxDP > to_unsigned(PLATE_WIDTH/2, PlateXxDP'length)) THEN
      PlateXxDN <= PlateXxDP - to_unsigned(PLATE_STEP_X, PlateXxDP'length);
    ELSIF (RightxSI = '1' AND PlateXxDP < to_unsigned(HS_DISPLAY - (PLATE_WIDTH/2), PlateXxDP'length)) THEN
      PlateXxDN <= PlateXxDP + to_unsigned(PLATE_STEP_X, PlateXxDP'length);
    ELSE
      PlateXxDN <= PlateXxDP;
    END IF;

    -- State machine
    CASE FsmStatexDP IS
      WHEN GameStart =>
        BallXxDN  <= BALL_X_INIT;
        BallYxDN  <= BALL_Y_INIT;
        PlateXxDN <= PLATE_X_INIT;
        IF (RightxSI = '1' AND LeftxSI = '1') THEN
          IF (VgaXxDI(1) XOR VgaYxDI(1)) = '1' THEN
            FsmStatexDN <= BallDownRight;
          ELSE
            FsmStatexDN <= BallDownLeft;
          END IF;
        END IF;

      WHEN GameEnd =>
        FsmStatexDN <= GameStart;

      WHEN BallUpLeft =>
        BallXxDN <= BallXxDP - to_unsigned(BALL_STEP_X, BallXxDP'length);
        BallYxDN <= BallYxDP - to_unsigned(BALL_STEP_Y, BallYxDP'length);
        IF (BumpLeft = '1') THEN
      FsmStatexDN <= BallUpRight;
        ELSIF (BumpTop = '1') THEN
      FsmStatexDN <= BallDownLeft;
        ELSIF (BumpUpLeft = '1') THEN
      FsmStatexDN <= BallDownRight;
        ELSIF (BumpBottom = '1') THEN
      FsmStatexDN <= GameEnd;
        END IF;

      WHEN BallUpRight =>
        BallXxDN <= BallXxDP + to_unsigned(BALL_STEP_X, BallXxDP'length);
        BallYxDN <= BallYxDP - to_unsigned(BALL_STEP_Y, BallYxDP'length);
        IF (BumpRight = '1') THEN
      FsmStatexDN <= BallUpLeft;
        ELSIF (BumpTop = '1') THEN
      FsmStatexDN <= BallDownRight;
        ELSIF (BumpUpRight = '1') THEN
      FsmStatexDN <= BallDownLeft;
        ELSIF (BumpBottom = '1') THEN
      FsmStatexDN <= GameEnd;
        END IF;

      WHEN BallDownLeft =>
        BallXxDN <= BallXxDP - to_unsigned(BALL_STEP_X, BallXxDP'length);
        BallYxDN <= BallYxDP + to_unsigned(BALL_STEP_Y, BallYxDP'length);
        IF (BumpLeft = '1') THEN
      FsmStatexDN <= BallDownRight;
        ELSIF (BumpPlate = '1') THEN
      FsmStatexDN <= BallUpLeft;
        ELSIF (BumpBottom = '1') THEN
      FsmStatexDN <= GameEnd;
        END IF;

      WHEN BallDownRight =>
        BallXxDN <= BallXxDP + to_unsigned(BALL_STEP_X, BallXxDP'length);
        BallYxDN <= BallYxDP + to_unsigned(BALL_STEP_Y, BallYxDP'length);
        IF (BumpRight = '1') THEN
      FsmStatexDN <= BallDownLeft;
        ELSIF (BumpPlate = '1') THEN
      FsmStatexDN <= BallUpRight;
        ELSIF (BumpBottom = '1') THEN
      FsmStatexDN <= GameEnd;
        END IF;

      WHEN OTHERS =>
        NULL;
    END CASE;

  END PROCESS PongFsm;

  BallXxDO <= BallXxDP;
  BallYxDO <= BallYxDP;
  PlateXxDO <= PlateXxDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
