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
use work.pong_types_pkg.all;

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

-- entity ball is
--   port(
--     CLKxCI          : in std_logic;
--     RSTxRI          : in std_logic;

--     BallXxDO        : out unsigned(COORD_BW - 1 DOWNTO 0);
--     BallYxDO        : out unsigned(COORD_BW - 1 DOWNTO 0) := ;
--     BallXSpeedxDO   : out signed(2 - 1 DOWNTO 0) := to_signed(0,2);
--     BallYSpeedxDO   : out signed(2 - 1 DOWNTO 0) := to_signed(0,2);

--     BallActivexDO   : out std_logic;
--   );
-- end ball;

-- architecture Behavior of Ball is
--   CONSTANT BALL_X_INIT         : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(HS_DISPLAY/2 - BALL_WIDTH/2, COORD_BW);
--   CONSTANT BALL_Y_INIT         : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(VS_DISPLAY/2 - BALL_HEIGHT/2, COORD_BW);

--   signal BallXxDP, BallXxDN    : unsigned(COORD_BW - 1 downto 0) := BALL_X_INIT;
--   signal BallYxDP, BallYxDN    : unsigned(COORD_BW - 1 downto 0) := BALL_Y_INIT;

--   signal BallXSpeedxDP, BallXSpeedxDN   : signed(2 - 1 downto 0) := to_signed(0,2);
--   SIGNAL BallYSpeedxDN, BallYSpeedxDP   : signed(2 - 1 DOWNTO 0) := to_signed(1,2);

-- end Behavior;

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
--    BallXxDO  : out unsigned(COORD_BW - 1 downto 0);
--    BallYxDO  : out unsigned(COORD_BW - 1 downto 0);

    -- Highscore Values
    HighscorexDO : out natural;

    -- State
    FsmStatexDO  : out std_logic;

    -- Multiple balls
    BallsxDO : out BallArrayType;
    ActiveBallCountxDO : out natural;

    PlateXxDO : out unsigned(COORD_BW - 1 downto 0)

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
  
  -- -- State of Ball
  -- SIGNAL BallXxDP, BallXxDN             : unsigned(COORD_BW - 1 DOWNTO 0) := BALL_X_INIT;
  -- SIGNAL BallYxDP, BallYxDN             : unsigned(COORD_BW - 1 DOWNTO 0) := BALL_Y_INIT;
  -- SIGNAL BallXSpeedxDN, BallXSpeedxDP   : signed(2 - 1 DOWNTO 0) := to_signed(0,2);
  -- SIGNAL BallYSpeedxDN, BallYSpeedxDP   : signed(2 - 1 DOWNTO 0) := to_signed(0,2);
  
  -- State of Plate
  SIGNAL PlateXxDP, PlateXxDN           : unsigned(COORD_BW - 1 DOWNTO 0) := PLATE_X_INIT;

  -- States of FSM
  TYPE GameControl IS (GameStart, GameEnd);
  SIGNAL FsmStatexDP, FsmStatexDN : GameControl := GameEnd;

  -- For controlling the screen
  signal VSEdgexSN, VSEdgexSP : std_logic := '0';

  -- Highscore init
  signal HighscorexDN, HighscorexDP : natural := 0;


  -- Additional precalculated signals
  signal PlateBallLeftDeltaXxD  : signed(COORD_BW - 1 downto 0) := resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW); -- Bottom corner left
  signal PlateBallRightDeltaXxD : signed(COORD_BW - 1 downto 0) := resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW); -- Bottom corner right

  -- Number of balls
  -- SIGNAL NumBalls : unsigned(3-1 downto 0) := to_unsigned(1,3);
  -- TYPE BallArray IS ARRAY (4-1 downto 0) of unsigned;
--  TYPE BallType IS RECORD
--    BallX     : unsigned(COORD_BW - 1 DOWNTO 0);
--    BallY     : unsigned(COORD_BW - 1 DOWNTO 0);
--    BallXSpeed: signed(1 DOWNTO 0);
--    BallYSpeed: signed(1 DOWNTO 0);
--  END RECORD;

--  TYPE BallArrayType IS ARRAY (0 TO 3-1) OF BallType;

  SIGNAL BallsxDN, BallsxDP : BallArrayType := (OTHERS => (
    BallX      => BALL_X_INIT,
    BallY      => BALL_Y_INIT,
    BallXSpeed => to_signed(0, 2),
    BallYSpeed => to_signed(0, 2)
  ));

  SIGNAL ActiveBallCountxDP, ActiveBallCountxDN : natural := 1;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  -- PlateBallLeftDeltaXxD  <= resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
  -- PlateBallRightDeltaXxD <= resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);

  -- TODO: Implement your code here

  PROCESS(CLKxCI, RSTxRI, VSEdgexSI)
  BEGIN
    IF (RSTxRI = '1') THEN
      -- Reset
      FsmStatexDP     <= GameStart;
--      BallXxDP        <= BALL_X_INIT;
--      BallYxDP        <= BALL_Y_INIT;
      PlateXxDP       <= PLATE_X_INIT;
--      BallXSpeedxDP   <= to_signed(0,2);
--      BallYSpeedxDP   <= to_signed(0,2);
      HighscorexDP     <= 0;
      VSEdgexSP       <= '0';

      BallsxDP <= (OTHERS => (
        BallX      => BALL_X_INIT,
        BallY      => BALL_Y_INIT,
        BallXSpeed => to_signed(0, 2),
        BallYSpeed => to_signed(0, 2)
      ));
      ActiveBallCountxDP <= 1;

    ELSIF rising_edge(CLKxCI) THEN
      -- Make game evolve to next state
      FsmStatexDP   <= FsmStatexDN;
--      BallXxDP      <= BallXxDN;
--      BallYxDP      <= BallYxDN;
      PlateXxDP     <= PlateXxDN;
--      BallXSpeedxDP <= BallXSpeedxDN;
--      BallYSpeedxDP <= BallYSpeedxDN;

      BallsxDP <= BallsxDN;
      ActiveBallCountxDP <= ActiveBallCountxDN;

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
--    BallXxDN          <= BallXxDP;
--    BallYxDN          <= BallYxDP;

    BallsxDN <= BallsxDP;
    ActiveBallCountxDN <= ActiveBallCountxDP;

    PlateXxDN         <= PlateXxDP;
--    BallXSpeedxDN     <= BallXSpeedxDP;
--    BallYSpeedxDN     <= BallYSpeedxDP;
    HighscorexDN      <= HighscorexDP;
    VSEdgexSN         <= VSEdgexSI;

    -- State machine
    CASE FsmStatexDP IS

      WHEN GameEnd =>
        FsmStatexDN     <= GameEnd;
--        BallXxDN        <= BALL_X_INIT;
--        BallYxDN        <= BALL_Y_INIT;
        PlateXxDN       <= PLATE_X_INIT;
--        BallXSpeedxDN   <= to_signed(0,2);
--        BallYSpeedxDN   <= to_signed(1,2);

        BallsxDN <= (OTHERS => (
          BallX      => BALL_X_INIT,
          BallY      => BALL_Y_INIT,
          BallXSpeed => to_signed(0, 2),
          BallYSpeed => to_signed(0, 2)
        ));
        ActiveBallCountxDN <= 1;

        -- Check if player starts game:
        if(LeftxSI = '1' and RightxSI = '1') then
          FsmStatexDN <= GameStart;
          HighScorexDN <= 0;

            -- Initial value of ball
            -- BallXxDN <= BALL_X_INIT;
            --BallYxDN <= BALL_Y_INIT;
          
            BallsxDN <= (OTHERS => (
            BallX => BALL_X_INIT,
            BallY => BALL_Y_INIT,
            BallXSpeed => to_signed(0, 2),
            BallYSpeed => to_signed(1, 2)
            ));

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

          FOR i IN 0 TO (MaxBallCount)-1 LOOP
            IF(i < ActiveBallCountxDP) THEN
          
              PlateBallLeftDeltaXxD  <= resize(signed(resize(BallsxDP(i).BallX, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
              PlateBallRightDeltaXxD <= resize(signed(resize(BallsxDP(i).BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
          
              -- check if ball hits the sides of the map
              if(BallsxDP(i).BallX <= 2*BALL_STEP_X and BallsxDP(i).BallXSpeed < 0) or (BallsxDP(i).BallX >= HS_DISPLAY - BALL_WIDTH - BALL_STEP_X and BallsxDP(i).BallXSpeed  > 0) then
                BallsxDN(i).BallXSpeed <= - BallsxDP(i).BallXSpeed;
              end if;

              if(BallsxDP(i).BallY <= 2*BALL_STEP_Y and BallsxDP(i).BallYSpeed  < 0) then
                BallsxDN(i).BallYSpeed <= - BallsxDP(i).BallYSpeed;
              end if;
      
              -- check collisions with plate
              if(BallsxDP(i).BallY >= VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT) then
                if(PlateBallRightDeltaXxD > 0 and PlateBallLeftDeltaXxD < PLATE_WIDTH) then 
                  if(BallsxDP(i).BallYSpeed >= 0) then
                    HighscorexDN <= HighscorexDP + 1;
                    BallsxDN(i).BallYSpeed <= - BallsxDP(i).BallYSpeed;
                    BallsxDN(i).BallXSpeed <= to_signed(-1, 2) when PlateBallRightDeltaXxD < PLATE_WIDTH / 3 
                                                               else to_signed(0, 2) when PlateBallRightDeltaXxD < PLATE_WIDTH / 3 * 2 
                                                               else to_signed(1, 2);
                    
                  end if;
                else
                  FsmStatexDN <= GameEnd;
                end if;
              end if;

              BallsxDN(i).BallX <= resize(unsigned(signed(resize(BallsxDP(i).BallX, COORD_BW + 1)) + resize(BallsxDP(i).BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
              BallsxDN(i).BallY <= resize(unsigned(signed(resize(BallsxDP(i).BallY, COORD_BW + 1)) + resize(BallsxDP(i).BallYSPeed, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);
            end if;
          END LOOP;
        
          -- Check if HighscorexDN reaches thresholds to increase ball count
          if ActiveBallCountxDP < MaxBallCount then
            if (HighscorexDN >= ActiveBallCountxDP * 2) then
              ActiveBallCountxDN <= ActiveBallCountxDP + 1;
        
              -- Initialize new ball
              BallsxDN(ActiveBallCountxDN).BallY <= resize(unsigned(signed(resize(BallsxDP(ActiveBallCountxDP).BallX, COORD_BW + 1)) + resize(BallsxDP(ActiveBallCountxDP).BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X*2, COORD_BW + 1)), COORD_BW);
              BallsxDN(ActiveBallCountxDN).BallX <= resize(unsigned(signed(resize(BallsxDP(ActiveBallCountxDP).BallY, COORD_BW + 1)) + resize(BallsxDP(ActiveBallCountxDP).BallYSPeed, COORD_BW + 1) * to_signed(BALL_STEP_Y*2, COORD_BW + 1)), COORD_BW);

              BallsxDN(ActiveBallCountxDN).BallYSpeed <= BallsxDP(ActiveBallCountxDP).BallYSpeed + BallsxDP(ActiveBallCountxDP).BallYSpeed;
              BallsxDN(ActiveBallCountxDN).BallXSpeed <= to_signed(-1, 2) when ActiveBallCountxDP <= 1
                                                               else to_signed(0, 2) when ActiveBallCountxDP <= 2 
                                                               else to_signed(1, 2);
            end if;
          end if;
        
        
        end if;

--     WHEN OTHERS =>
--       NULL;
    
    END CASE;

  END PROCESS;

  BallsxDO <= BallsxDP;
  ActiveBallCountxDO <= ActiveBallCountxDP;
  -- BallXxDO <= BallXxDP;
  -- BallYxDO <= BallYxDP;
  PlateXxDO <= PlateXxDP;
  FsmStatexDO <= '0' when FsmStatexDP = GameEnd else '1';
  HighscorexDO <= HighscorexDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
