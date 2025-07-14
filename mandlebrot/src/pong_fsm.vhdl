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

    -- Obstacles
   ObstaclesxDO  : out ObstacleArrayType;

    -- Multiple balls
    BallsxDO       : out BallArrayType;

    -- Plate
    PlateXxDO : out unsigned(COORD_BW - 1 downto 0);

    -- Game State
    FsmStatexDO : out GameControl
    
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
    Collision  => '0'
  ));

  -- States of FSM
  SIGNAL FsmStatexDP, FsmStatexDN : GameControl := GameEnd;

  -- For controlling the screen
  SIGNAL VSEdgexSP, VSEdgexSN : std_logic := '0';

  -- Highscore init
  SIGNAL HighscorexDN, HighscorexDP : unsigned(8-1 DOWNTO 0) := to_unsigned(1,8);

  -- Obstacles coordinates
  SIGNAL ObstaclesxDN, ObstaclesxDP : ObstacleArrayType := (
    0 => (x => to_unsigned(70, COORD_BW), y => to_unsigned(180, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    1 => (x => to_unsigned(190, COORD_BW), y => to_unsigned(180, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    2 => (x => to_unsigned(260, COORD_BW), y => to_unsigned(260, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    3 => (x => to_unsigned(340, COORD_BW), y => to_unsigned(260, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    4 => (x => to_unsigned(400, COORD_BW), y => to_unsigned(210, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    5 => (x => to_unsigned(470, COORD_BW), y => to_unsigned(310, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    6 => (x => to_unsigned(640, COORD_BW), y => to_unsigned(310, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    7 => (x => to_unsigned(730, COORD_BW), y => to_unsigned(210, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    8 => (x => to_unsigned(850, COORD_BW), y => to_unsigned(310, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW))
    );

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
  SIGNAL FsmState     : OUT GameControl
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
    IF (PlateRight > 0 AND PlateLeft < PLATE_WIDTH) THEN
      IF (BallIn.BallYSpeed >= 0) THEN
        IF(HighscoreIn < 10) THEN
          HighscoreOut <= HighscoreIn + 1;
        END IF;
        BallOut.BallYSpeed <= -BallIn.BallYSpeed;
        BallOut.BallXSpeed <= to_signed(-1, 2) WHEN PlateRight < (PLATE_WIDTH / 3) ELSE
                              to_signed(0, 2)  WHEN PlateRight < ((2 * PLATE_WIDTH) / 3) ELSE
                              to_signed(1, 2);
      END IF;

    --Obstacle collision
    for i in 0 to 9-1 loop
      if (BallIn.BallX + BALL_WIDTH >= ObstaclesxDP(i).x and
          BallIn.BallX <= ObstaclesxDP(i).x + ObstaclesxDP(i).Width and
          BallIn.BallY + BALL_HEIGHT >= ObstaclesxDP(i).y and
          BallIn.BallY <= ObstaclesxDP(i).y + ObstaclesxDP(i).Height) then
            
          BallOut.Collision <= '1';
        -- Determine collision side and adjust speed
        if (BallIn.BallX + BALL_WIDTH/2 < ObstaclesxDP(i).x + ObstaclesxDP(i).Width/3) then
          BallOut.BallXSpeed <= to_signed(-1, 2);
        elsif (BallIn.BallX + BALL_WIDTH/2 < ObstaclesxDP(i).x + 2*ObstaclesxDP(i).Width/3) then
          BallOut.BallXSpeed <= to_signed(0, 2);
        else
          BallOut.BallXSpeed <= to_signed(1, 2);
        end if;
        
        -- Reverse Y speed to bounce and adjust position
        BallOut.BallYSpeed <= -BallIn.BallYSpeed;
--        BallOut.BallY <= BallIn.BallY + BallOut.BallYSpeed * BALL_STEP_Y;
        
      end if;
    end loop;
    --------------------
    ELSE
      FsmState <= GameEnd;
    END IF;
  END IF;

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
      if PlateIn <= PLATE_STEP_X then
          PlateOut <= PlateIn + HS_DISPLAY - PLATE_STEP_X;
      else
        PlateOut <= PlateIn - PLATE_STEP_X;
      end if;
  end if;
  
  -- Check motion of plate right
  if(RightxSI = '1') then
    PlateOut <= PlateIn + PLATE_STEP_X;
    if PlateIn >= HS_DISPLAY - PLATE_STEP_X then
      PlateOut <= PlateIn - HS_DISPLAY + PLATE_STEP_X;
    else
      PlateOut <= PlateIn + PLATE_STEP_X;
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
        Collision  => '0'
      ));

        ObstaclesxDP <= (
          0 => (x => to_unsigned(70, COORD_BW), y => to_unsigned(80, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
          1 => (x => to_unsigned(190, COORD_BW), y => to_unsigned(80, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
          2 => (x => to_unsigned(260, COORD_BW), y => to_unsigned(160, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
          3 => (x => to_unsigned(340, COORD_BW), y => to_unsigned(160, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
          4 => (x => to_unsigned(400, COORD_BW), y => to_unsigned(110, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
          5 => (x => to_unsigned(470, COORD_BW), y => to_unsigned(210, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
          6 => (x => to_unsigned(540, COORD_BW), y => to_unsigned(210, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
          7 => (x => to_unsigned(610, COORD_BW), y => to_unsigned(110, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
          8 => (x => to_unsigned(670, COORD_BW), y => to_unsigned(210, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW))
          );
      
    ELSIF rising_edge(CLKxCI) THEN
      -- udate fsm informations
      FsmStatexDP   <= FsmStatexDN;
      HighscorexDP  <= HighscorexDN;
      VSEdgexSP     <= VSEdgexSN;

      -- Update Balls
      BallsxDP      <= BallsxDN;

      -- Update plate
      PlateXxDP     <= PlateXxDN;
      
      -- update obstacles
      ObstaclesxDP <= ObstaclesxDN;

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

    ObstaclesxDN <= ObstaclesxDP;

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
          Collision  => '0'
        ));
        
        -- Update Plate
        PlateXxDN          <= PLATE_X_INIT;

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
         UpdateBall(BallsxDP(0), BallsxDN(0), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN);
      END IF;

      -- logic for ball 2
      WHEN Game2Ball =>
        IF(VSEdgexSP = '0' and VSEdgexSN = '1') then
          -- Check switching condition
          IF HighscorexDP > to_unsigned(5, 8) THEN
            BallsxDN(2).IsActive <= to_unsigned(1,2);
            BallsxDN(2).BallYSpeed <= to_signed(1,2);
            BallsxDN(2).BallX <= BALL_X_INIT;
            BallsxDN(2).BallY <= BALL_Y_INIT;
            FsmStatexDN <= Game3Ball;
          END IF;

          MovePlate(PlateXxDP, PlateXxDN);       
          UpdateBall(BallsxDP(0), BallsxDN(0), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN);
          UpdateBall(BallsxDP(1), BallsxDN(1), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN);
        END IF;

      -- logic for ball 3
      WHEN Game3Ball =>
      IF(VSEdgexSP = '0' and VSEdgexSN = '1') then
        MovePlate(PlateXxDP, PlateXxDN);       
        UpdateBall(BallsxDP(0), BallsxDN(0), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN);
        UpdateBall(BallsxDP(1), BallsxDN(1), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN);
        UpdateBall(BallsxDP(2), BallsxDN(2), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN);
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
  ObstaclesxDO <= ObstaclesxDP;
  FsmStatexDO <= FsmStatexDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================