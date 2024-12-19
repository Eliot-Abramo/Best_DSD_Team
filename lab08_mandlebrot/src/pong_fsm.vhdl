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
-- from the upper left corner of the screen.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR PONG_FSM
--=============================================================================

ENTITY pong_fsm is
  PORT (
    -- CLK and RST
    CLKxCI      : in std_logic;
    RSTxRI      : in std_logic;

    -- Controls from push buttons
    LeftxSI     : in std_logic;
    RightxSI    : in std_logic;

    -- Coordinate from VGA
    VgaXxDI     : in unsigned(COORD_BW - 1 downto 0);
    VgaYxDI     : in unsigned(COORD_BW - 1 downto 0);

    -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
    VSEdgexSI   : in std_logic;

    -- Multiple balls
    BallsxDO       : out BallArrayType;

    -- Plate
    PlateXxDO : out unsigned(COORD_BW - 1 downto 0);

    -- Game State
    FsmStatexDO : out GameControl;

    PlateWidthxDO : out natural
  );
end pong_fsm;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_fsm is
  -- Init variables to start game  
  CONSTANT BALL_X_INIT  : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(HS_DISPLAY/2 - BALL_WIDTH/2, COORD_BW);
  CONSTANT BALL_Y_INIT  : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(VS_DISPLAY/2 - BALL_HEIGHT/2, COORD_BW);
  CONSTANT PLATE_X_INIT : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(HS_DISPLAY/2 - PLATE_WIDTH/2, COORD_BW);
  
  -- State of Plate
  SIGNAL PlateXxDP, PlateXxDN : unsigned(COORD_BW - 1 DOWNTO 0) := PLATE_X_INIT;
  
  -- Signal containing all of the balls
  SIGNAL BallsxDN, BallsxDP : BallArrayType := (OTHERS => (
    BallX      => BALL_X_INIT,
    BallY      => BALL_Y_INIT,
    BallXSpeed => to_signed(0, 2),
    BallYSpeed => to_signed(0, 2),
    IsActive   => to_unsigned(0, 2),
    Color  => BALL_RGB,
    Counter => to_unsigned(0,3)
  ));

  -- States of FSM
  SIGNAL FsmStatexDP, FsmStatexDN : GameControl := GameEnd;

  -- For controlling the screen
  SIGNAL VSEdgexSP, VSEdgexSN : std_logic := '0';

  -- Highscore init
  SIGNAL HighscorexDN, HighscorexDP : unsigned(8-1 DOWNTO 0) := to_unsigned(1,8);

  SIGNAL PlateWidthxDN, PlateWidthxDP : natural := PLATE_WIDTH;
  SIGNAL PlateStepXxDN, PlateStepXxDP : natural := PLATE_STEP_X;
--=============================================================================
-- PROCEDURE DECLARATION
--=============================================================================
-- Procedure to handle ball updates and collisions
PROCEDURE UpdateBall (
  SIGNAL BallIn       : IN BallType;
  SIGNAL BallOut      : OUT BallType;
  SIGNAL PlateX       : IN unsigned(COORD_BW - 1 DOWNTO 0);
  SIGNAL HighScoreIn : IN unsigned(8-1 downto 0);
  SIGNAL HighscoreOut : OUT unsigned(8 - 1 DOWNTO 0);
  SIGNAL FsmState     : OUT GameControl;
  SIGNAL PlateWidthIn : IN natural;
  SIGNAL PlateWidthOut : OUT natural;
  SIGNAL PlateSpeedIn : IN natural;
  SIGNAL PlateSpeedOut : OUT natural
) IS
  -- Local variables for PlateBump
  VARIABLE PlateLeft  : signed(COORD_BW - 1 DOWNTO 0);
  VARIABLE PlateRight : signed(COORD_BW - 1 DOWNTO 0);
BEGIN
  -- Calculate PlateBump values based on the current ball and plate positions
  PlateLeft  := resize(signed(resize(BallIn.BallX, COORD_BW + 1)) - signed(resize(PlateX, COORD_BW + 1)), COORD_BW);
  PlateRight := resize(signed(resize(BallIn.BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateX, COORD_BW + 1)), COORD_BW);

  -- Check for horizontal wall collisions
  IF (BallIn.BallX <= 2 * BALL_STEP_X AND BallIn.BallXSpeed < 0) OR
     (BallIn.BallX >= (HS_DISPLAY - BALL_WIDTH - BALL_STEP_X) AND BallIn.BallXSpeed > 0) THEN
    BallOut.BallXSpeed <= -BallIn.BallXSpeed;
  ELSE
    BallOut.BallXSpeed <= BallIn.BallXSpeed;
  END IF;

  -- Check for vertical wall collisions
  IF (BallIn.BallY <= 2 * BALL_STEP_Y AND BallIn.BallYSpeed < 0) THEN
    BallOut.BallYSpeed <= -BallIn.BallYSpeed;
  ELSE
    BallOut.BallYSpeed <= BallIn.BallYSpeed;
  END IF;

  -- Check for collisions with the plate
  IF (BallIn.BallY >= VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT) THEN
    IF (PlateRight > 0 AND PlateLeft < PlateWidthIn) THEN
      IF (BallIn.BallYSpeed >= 0) THEN
        IF(HighscoreIn < 10) THEN
          HighscoreOut <= HighscoreIn + 1;
          PlateWidthOut <= PlateWidthIn - 10;
        END IF;
        BallOut.BallYSpeed <= -BallIn.BallYSpeed;
        BallOut.BallXSpeed <= to_signed(-1, 2) WHEN PlateRight < (PlateWidthIn / 3) ELSE
                              to_signed(0, 2)  WHEN PlateRight < ((2 * PlateWidthIn) / 3) ELSE
                              to_signed(1, 2);

        CASE(BallIn.Counter) IS 
          WHEN TO_UNSIGNED(0,3) => BallOut.Color <= x"F00";
          WHEN TO_UNSIGNED(1,3) => BallOut.Color <= x"0F0";
          WHEN TO_UNSIGNED(2,3) => BallOut.Color <= x"F0F";
          WHEN TO_UNSIGNED(3,3) => BallOut.Color <= x"FF0";
          WHEN OTHERS => BallOut.Color <= BALL_RGB;
        END CASE;

        BallOut.Counter <= to_unsigned((to_integer(BallIn.Counter) + 1) mod 4, BallIn.Counter'length);

        PlateSpeedOut <= PlateSpeedIn + 1;

      END IF;
    --------------------
    ELSE
      FsmState <= GameEnd;
    END IF;
  END IF;

  --OBSTACLE COLLISION
--  FOR i IN 0 TO MAX_OBS_COUNT-1 LOOP
--    IF (BallIn.BallX + BALL_WIDTH >= OBSTACLES(i).x AND
--        BallIn.BallX <= OBSTACLES(i).x + OBSTACLES(i).Width AND
--        (BallIn.BallY + BALL_HEIGHT/2 >= OBSTACLES(i).y AND
--        BallIn.BallY - BALL_HEIGHT/2 <= OBSTACLES(i).y + OBSTACLES(i).Height)) THEN
          
--        BallOut.Collision <= '1';
--      -- DETERMINE COLLISION SIDE AND ADJUST SPEED
--      IF (BallIn.BallX + BALL_WIDTH/2 < OBSTACLES(i).x + OBSTACLES(i).Width/3) THEN
--        BallOut.BallXSpeed <= TO_SIGNED(-1, 2);
--      ELSIF (BallIn.BallX + BALL_WIDTH/2 < OBSTACLES(i).x + 2*OBSTACLES(i).Width/3) THEN
--        BallOut.BallXSpeed <= TO_SIGNED(0, 2);
--      ELSE
--        BallOut.BallXSpeed <= TO_SIGNED(1, 2);
--      END IF;
      
--      -- REVERSE Y SPEED TO BOUNCE AND ADJUST POSITION
--      IF(BallIn.BallYSpeed > 0) THEN
--        BallOut.BallYSpeed <= to_signed(-1, 2);
--      ELSIF(BallIn.BallYSpeed < 0) THEN
--        BallOut.BallYSpeed <= to_signed(1,2);
--      ELSE
--        BallOut.BallYSpeed <= to_signed(0,2);
--      END IF;
--    END IF;
--  END LOOP;

  -- Update ball position
  BallOut.BallX <= resize(unsigned(signed(resize(BallIn.BallX, COORD_BW + 1)) + resize(BallIn.BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
  BallOut.BallY <= resize(unsigned(signed(resize(BallIn.BallY, COORD_BW + 1)) + resize(BallIn.BallYSpeed, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);
END PROCEDURE;
--=============================================================================

-- Procedure to handle plate movement
PROCEDURE MovePlate(
    SIGNAL PlateIn : IN unsigned(COORD_BW - 1 DOWNTO 0);
    SIGNAL PlateOut : OUT unsigned(COORD_BW - 1 DOWNTO 0)
) IS 
BEGIN
  -- Check motion of plate left
  if(LeftxSI = '1') then
      if PlateIn <= PlateStepXxDP then
          PlateOut <= PlateIn + HS_DISPLAY - PlateStepXxDP;
      else
        PlateOut <= PlateIn - PlateStepXxDP;
      end if;
  end if;
  
  -- Check motion of plate right
  if(RightxSI = '1') then
    PlateOut <= PlateIn + PlateStepXxDP;
    if PlateIn >= HS_DISPLAY - PlateStepXxDP then
      PlateOut <= PlateIn - HS_DISPLAY + PlateStepXxDP;
    else
      PlateOut <= PlateIn + PlateStepXxDP;
    end if;
  end if;

END PROCEDURE;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin
  --===========================================================================
  -- Clock and Reset Process
  --===========================================================================
  PROCESS(CLKxCI, RSTxRI)
  BEGIN
    -- Asynchrone reset
    IF (RSTxRI = '1') THEN
      FsmStatexDP        <= GameEnd;
      VSEdgexSP          <= '0';

      PlateXxDP          <= PLATE_X_INIT;
      HighscorexDP       <= to_unsigned(1,8);

      BallsxDP <= (OTHERS => (
        BallX      => BALL_X_INIT,
        BallY      => BALL_Y_INIT,
        BallXSpeed => to_signed(0, 2),
        BallYSpeed => to_signed(0, 2),
        IsActive   => to_unsigned(0,2),
        Color  => BALL_RGB,
        Counter => to_unsigned(0,3)
      ));

      PlateWidthxDP <= PLATE_WIDTH;
      PlateStepXxDP <= PLATE_STEP_X;
      
    ELSIF rising_edge(CLKxCI) THEN
      -- udate fsm informations
      FsmStatexDP   <= FsmStatexDN;
      HighscorexDP  <= HighscorexDN;
      VSEdgexSP     <= VSEdgexSN;

      -- Update Balls
      BallsxDP      <= BallsxDN;

      -- Update plate
      PlateXxDP     <= PlateXxDN;

      PlateWidthxDP <= PlateWidthxDN;
      PlateStepXxDP <= PlateStepXxDN;
    END IF;

  END PROCESS; 

  --===========================================================================
  -- Game Evolution logic
  --===========================================================================
  PROCESS (ALL)
  BEGIN
    --===========================================================================
    -- Update system variables
    --===========================================================================
    FsmStatexDN       <= FsmStatexDP;
    VSEdgexSN         <= VSEdgexSI;
    HighscorexDN      <= HighscorexDP;

    -- Update Balls
    BallsxDN          <= BallsxDP;

    -- Update Plate
    PlateXxDN         <= PlateXxDP;
    PlateWidthxDN     <= PlateWidthxDP;
    PlateStepXxDN     <= PlateStepXxDP;

    -- State machine
    CASE FsmStatexDP IS
      --=========================================================================
      -- Game End Logic
      --=========================================================================

      -- Game over logic
      WHEN GameEnd =>
        FsmStatexDN        <= GameEnd;
        VSEdgexSN          <= '0';
        HighScorexDN       <= to_unsigned(1,8);

        -- Update Balls
        BallsxDN <= (OTHERS => (
          BallX      => BALL_X_INIT,
          BallY      => BALL_Y_INIT,
          BallXSpeed => to_signed(0, 2),
          BallYSpeed => to_signed(0, 2),
          IsActive   => to_unsigned(0,2),
          Color  => BALL_RGB,
          Counter => to_unsigned(0,3)
        ));
        
        -- Update Plate
        PlateXxDN          <= PLATE_X_INIT;
        PlateWidthxDN      <= PLATE_WIDTH;
        PlateStepXxDN      <= PLATE_STEP_X;

        -- Check if player starts game
        if(LeftxSI = '1' and RightxSI = '1') then
          FsmStatexDN  <= Game1Ball;
          HighScorexDN <= to_unsigned(1,8);
          BallsxDN(0).BallYSpeed <= to_signed(1, 2);
          BallsxDN(0).BallX <= BALL_X_INIT;
          BallsxDN(0).BallY <= BALL_Y_INIT;
          BallsxDN(0).IsActive <= to_unsigned(1,2);
        end if;
      
      -- logic for ball 1
      WHEN Game1Ball =>
        IF(VSEdgexSP = '0' and VSEdgexSN = '1') then
          -- Check switching condition
          IF HighscorexDP > to_unsigned(3, 8) THEN
            BallsxDN(1).IsActive <= to_unsigned(1,2);
            BallsxDN(1).BallYSpeed <= to_signed(1,2);
            BallsxDN(1).BallX <= BALL_X_INIT;
            BallsxDN(1).BallY <= BALL_Y_INIT;
            FsmStatexDN <= Game2Ball;
          END IF;
          
         MovePlate(PlateXxDP, PlateXxDN);
         UpdateBall(BallsxDP(0), BallsxDN(0), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
      END IF;

      -- logic for ball 2
      WHEN Game2Ball =>
        IF(VSEdgexSP = '0' and VSEdgexSN = '1') then
          -- Check switching condition
          IF HighscorexDP > to_unsigned(5, 8) THEN
            BallsxDN(2).IsActive <= to_unsigned(1,2);
            BallsxDN(2).BallYSpeed <= to_signed(-1,2);
            BallsxDN(2).BallX <= BALL_X_INIT;
            BallsxDN(2).BallY <= BALL_Y_INIT;
            FsmStatexDN <= Game3Ball;
          END IF;

          MovePlate(PlateXxDP, PlateXxDN);       
          UpdateBall(BallsxDP(0), BallsxDN(0), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
          UpdateBall(BallsxDP(1), BallsxDN(1), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
        END IF;

      -- logic for ball 3
      WHEN Game3Ball =>
      IF(VSEdgexSP = '0' and VSEdgexSN = '1') then
        MovePlate(PlateXxDP, PlateXxDN);       
        UpdateBall(BallsxDP(0), BallsxDN(0), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
        UpdateBall(BallsxDP(1), BallsxDN(1), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
        UpdateBall(BallsxDP(2), BallsxDN(2), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
      END IF;
      
      WHEN OTHERS =>
        FsmStatexDN  <= GameEnd;
        VSEdgexSN    <= '0';
        HighScorexDN <= to_unsigned(1,8);

    END CASE;

  END PROCESS;

  -- Update game informations in process
  BallsxDO <= BallsxDP;
  PlateXxDO <= PlateXxDP;
  FsmStatexDO <= FsmStatexDP;
  PlateWidthxDO <= PlateWidthxDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================