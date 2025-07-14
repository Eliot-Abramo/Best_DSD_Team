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
-- from the upper left corner of the screen.z
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
    PlateXxDO : out unsigned(COORD_BW - 1 downto 0);

    -- Highscore Values
    HighscorexDO : out unsigned(5 - 1 downto 0);

    -- State
    FsmStatexDO  : out std_logic
  );
end pong_fsm;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_fsm is

-- TODO: Implement your code here
  CONSTANT BALL_X_INIT         : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(HS_DISPLAY/2 - BALL_WIDTH/2, COORD_BW);
  CONSTANT BALL_Y_INIT         : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(VS_DISPLAY/2 - BALL_HEIGHT/2, COORD_BW);
  CONSTANT PLATE_X_INIT        : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(HS_DISPLAY/2 - PLATE_WIDTH/2, COORD_BW);

  -- Signals
  -- SIGNAL BumpTop, BumpBottom, BumpLeft, BumpRight, BumpPlate, BumpUpLeft, BumpUpRight : std_logic;
  
  -- State of Ball
  SIGNAL BallXxDP, BallXxDN             : unsigned(COORD_BW - 1 DOWNTO 0) := BALL_X_INIT;
  SIGNAL BallYxDP, BallYxDN             : unsigned(COORD_BW - 1 DOWNTO 0) := BALL_Y_INIT;
  SIGNAL BallXSpeedxDN, BallXSpeedxDP   : signed(2 - 1 DOWNTO 0) := to_signed(0,2);
  SIGNAL BallYSpeedxDN, BallYSpeedxDP   : signed(2 - 1 DOWNTO 0) := to_signed(0,2);
  
  -- State of Plate
  SIGNAL PlateXxDP, PlateXxDN           : unsigned(COORD_BW - 1 DOWNTO 0) := PLATE_X_INIT;

  -- States of FSM
  TYPE GameControl IS (GameStart, GameEnd);
  SIGNAL FsmStatexDP, FsmStatexDN : GameControl := GameEnd;

  -- For controlling the screen
  signal VSEdgexSN, VSEdgexSP : std_logic := '0';

  -- Highscore init
  signal HighscorexDN, HighscorexDP : unsigned(5 - 1 downto 0) := to_unsigned(0, 5);


  -- Additional precalculated signals
  signal PlateBallLeftDeltaXxD  : signed(COORD_BW - 1 downto 0) := resize(signed(resize(BallXxDP, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW); -- Bottom corner left
  signal PlateBallRightDeltaXxD : signed(COORD_BW - 1 downto 0) := resize(signed(resize(BallXxDP, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW); -- Bottom corner right

  -- Number of balls
  SIGNAL NumBalls : unsigned(3-1 downto 0) := to_unsigned(1,3);
  TYPE BallArray IS ARRAY (4-1 downto 0) of unsigned;



--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  PlateBallLeftDeltaXxD  <= resize(signed(resize(BallXxDP, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
  PlateBallRightDeltaXxD <= resize(signed(resize(BallXxDP, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);

  -- TODO: Implement your code here

  PROCESS(CLKxCI, RSTxRI, VSEdgexSI)
  BEGIN
    IF (RSTxRI = '1') THEN
      -- Reset
      FsmStatexDP     <= GameStart;
      BallXxDP        <= BALL_X_INIT;
      BallYxDP        <= BALL_Y_INIT;
      PlateXxDP       <= PLATE_X_INIT;
      BallXSpeedxDP   <= to_signed(0,2);
      BallYSpeedxDP   <= to_signed(0,2);
      HighscorexDP     <= to_unsigned(0,5);
      VSEdgexSP       <= '0';

    ELSIF rising_edge(CLKxCI) THEN
      -- Make game evolve to next state
      FsmStatexDP   <= FsmStatexDN;
      BallXxDP      <= BallXxDN;
      BallYxDP      <= BallYxDN;
      PlateXxDP     <= PlateXxDN;
      BallXSpeedxDP <= BallXSpeedxDN;
      BallYSpeedxDP <= BallYSpeedxDN;  -- Update this line
      HighscorexDP  <= HighscorexDN;
      VSEdgexSP     <= VSEdgexSN;
    END IF;

  END PROCESS; 

  --=============================================================================
  -- Game Evolution logic
  --=============================================================================
  PROCESS (ALL)
  BEGIN
    -- Default states
    FsmStatexDN       <= FsmStatexDP;
    BallXxDN          <= BallXxDP;
    BallYxDN          <= BallYxDP;
    PlateXxDN         <= PlateXxDP;
    BallXSpeedxDN     <= BallXSpeedxDP;
    BallYSpeedxDN     <= BallYSpeedxDP;
    HighscorexDN      <= HighscorexDP;
    VSEdgexSN         <= VSEdgexSI;

    -- State machine
    CASE FsmStatexDP IS

      WHEN GameEnd =>
        FsmStatexDN     <= GameEnd;
        BallXxDN        <= BALL_X_INIT;
        BallYxDN        <= BALL_Y_INIT;
        PlateXxDN       <= PLATE_X_INIT;
        BallXSpeedxDN   <= to_signed(0,2);
        BallYSpeedxDN   <= to_signed(1,2);

        -- Check if player starts game:
        if(LeftxSI = '1' and RightxSI = '1') then
          FsmStatexDN <= GameStart;
          HighScorexDN <= to_unsigned(0,5);

          -- Initial value of ball
          BallXxDN <= BALL_X_INIT;
          BallYxDN <= BALL_Y_INIT;
        end if;

      WHEN GameStart =>
        -- Update frames of game
        if(VSEdgexSP = '0' and VSEdgexSN = '1') then
          -- If left button pressed
          if(LeftxSI = '1') then
            -- check plate is moving correctly
            if PlateXxDP <= PLATE_STEP_X then
              PlateXxDN <= PlateXxDP + HS_DISPLAY - PLATE_STEP_X;
            else
              PlateXxDN <= PlateXxDP - PLATE_STEP_X;
            end if;
          end if;
          
          -- If right button pressed
          if(RightxSI = '1') then
            PlateXxDN <= PlateXxDP + PLATE_STEP_X;
            -- check plate is moving correctly
            if PlateXxDP >= HS_DISPLAY - PLATE_STEP_X then
              PlateXxDN <= PlateXxDP - HS_DISPLAY + PLATE_STEP_X;
            else
              PlateXxDN <= PlateXxDP + PLATE_STEP_X;
            end if;
          end if;

          -- check if ball hits the sides of the map
          if(BallXxDP <= 2*BALL_STEP_X and BallXSpeedxDP < 0) or (BallXxDP >= HS_DISPLAY - BALL_WIDTH - BALL_STEP_X and BallXSpeedxDP > 0) then
            BallXSpeedxDN   <= - BallXSpeedxDP;
          end if;

          if(BallYxDP <= 2*BALL_STEP_Y and BallYSpeedxDP < 0) then
            BallYSpeedxDN   <= - BallYSpeedxDP;
          end if;
      
          -- check collisions with plate
          if(BallYxDP >= VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT) then
            if(PlateBallRightDeltaXxD > 0 and PlateBallLeftDeltaXxD < PLATE_WIDTH) then 
              if(BallYSpeedxDP >= 0) then
                HighscorexDN <= HighscorexDP + 1;
                BallYSpeedxDN <= - BallYSpeedxDP;
                BallXSpeedxDN <= BallXSpeedxDP + (BallXSpeedxDP / 2); -- *1.5 times
              end if;
            else
              FsmStatexDN <= GameEnd;
            end if;
          end if;
          -- TODO if changing to signed coord simplify the expression
          BallXxDN <= resize(unsigned(signed(resize(BallXxDP, COORD_BW + 1)) + resize(BallXSpeedxDP, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
          BallYxDN <= resize(unsigned(signed(resize(BallYxDP, COORD_BW + 1)) + resize(BallYSpeedxDP, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);

          end if;

--     WHEN OTHERS =>
--       NULL;
    
    END CASE;

  END PROCESS;

  BallXxDO <= BallXxDP;
  BallYxDO <= BallYxDP;
  PlateXxDO <= PlateXxDP;
  FsmStatexDO <= '0' when FsmStatexDP = GameEnd else '1';
  HighscorexDO <= HighscorexDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================