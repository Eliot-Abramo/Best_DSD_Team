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

    -- State
    FsmStatexDO  : out GameControl;

    -- Multiple balls
    BallsxDO       : out BallArrayType;

    -- Plate
    PlateXxDO : out unsigned(COORD_BW - 1 downto 0)
    
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

  -- Signal containing the bump of balls with plate to control angle reaction
  SIGNAL PlateBumpxDP, PlateBumpxDN : PlateBumpArrayType := (OTHERS => (
    Left => resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) -
                   signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW),
    Right => resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - 
                    signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW)
   ));    
  
  -- Signal containing all of the balls
  SIGNAL BallsxDN, BallsxDP : BallArrayType := (OTHERS => (
    BallX      => BALL_X_INIT,
    BallY      => BALL_Y_INIT,
    BallXSpeed => to_signed(0, 2),
    BallYSpeed => to_signed(0, 2),
    IsActive   => to_unsigned(0, 2)
  ));

  -- States of FSM
  SIGNAL FsmStatexDP, FsmStatexDN : GameControl := GameEnd;

  -- For controlling the screen
  SIGNAL VSEdgexSN, VSEdgexSP : std_logic := '0';

  -- Highscore init
  SIGNAL HighscorexDN, HighscorexDP : unsigned(4-1 DOWNTO 0) := to_unsigned(1,4);

--=============================================================================
-- PROCEDURE DECLARATION
--=============================================================================
  -- Procedure to handle ball updates and collisions
 PROCEDURE UpdateBall (
    -- TODO: An InOut statement could work instead of having 2 statements, but I'm afraid of VHDL
    -- inferring Latches which the prof. doesn't want.
    SIGNAL BallIn : IN BallType;
    SIGNAL BallOut : OUT BAllType;
    
    SIGNAL PlateBumpIn : IN PlateBumpType;
    SIGNAL PlateBumpOut : OUT PlateBumpType;
    
    SIGNAL HighscoreOut : OUT unsigned(4-1 DOWNTO 0);
    
    SIGNAL FsmState : INOUT GameControl
  ) IS
  BEGIN
    -- Check for horizontal wall collisions
    IF (BallIn.BallX <= 2 * BALL_STEP_X AND BallIn.BallXSpeed < 0) OR
       (BallIn.BallX >= (HS_DISPLAY - BALL_WIDTH - BALL_STEP_X) AND BallIn.BallXSpeed > 0) THEN
      BallOut.BallXSpeed <= -BallIn.BallXSpeed;
    END IF;

    -- Check for vertical wall collisions
    IF (BallIn.BallY <= 2 * BALL_STEP_Y AND BallIn.BallYSpeed < 0) THEN
      BallOut.BallYSpeed <= -BallIn.BallYSpeed;
    END IF;

    -- Check for collisions with the plate
    IF BallIn.BallY >= (VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT) THEN
      IF (PlateBumpIn.Right > 0 AND PlateBumpIn.Left < PLATE_WIDTH) THEN
        IF BallIn.BallYSpeed >= 0 THEN
          HighscoreOut <= HighscorexDP + 1;
          BallOut.BallYSpeed <= -BallIn.BallYSpeed;
          BallOut.BallXSpeed <= to_signed(-1, 2) when PlateBumpIn.Right < (PLATE_WIDTH / 3)
                                                  else to_signed(0, 2) when PlateBumpIn.Right < ((2*PLATE_WIDTH)/ 3) 
                                                  else to_signed(1, 2); 
        END IF;
      ELSE
        FsmState <= GameEnd;
      END IF;
    END IF;

    -- Update ball position
    BallOut.BallX <= resize(unsigned(signed(resize(BallIn.BallX, COORD_BW + 1)) + resize(BallIn.BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
    BallOut.BallY <= resize(unsigned(signed(resize(BallIn.BallY, COORD_BW + 1)) + resize(BallIn.BallYSpeed, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);

    PlateBumpOut.Left  <= resize(signed(resize(BallOut.BallX, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
    PlateBumpOut.Right <= resize(signed(resize(BallOut.BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);

END PROCEDURE;

PROCEDURE MovePlate(
    SIGNAL PlateIn : IN unsigned(COORD_BW - 1 DOWNTO 0);
    SIGNAL PlateOut : OUT unsigned(COORD_BW - 1 DOWNTO 0)
) IS 
BEGIN
  -- Check motion of plate
  if(LeftxSI = '1') then
      if PlateIn <= PLATE_STEP_X then
          PlateOut <= PlateIn + HS_DISPLAY - PLATE_STEP_X;
      else
      PlateOut <= PlateIn - PLATE_STEP_X;
      end if;
  end if;
        
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
    IF (RSTxRI = '1') THEN
      FsmStatexDP        <= Game1Ball;
      VSEdgexSP          <= '0';

      PlateXxDP          <= PLATE_X_INIT;
      HighscorexDP       <= to_unsigned(1,4);

      PlateBumpxDP <=(OTHERS => (
       Left => resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) -
                        signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW),
       Right => resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - 
                        signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW)
      ));    

      BallsxDP <= (OTHERS => (
        BallX      => BALL_X_INIT,
        BallY      => BALL_Y_INIT,
        BallXSpeed => to_signed(0, 2),
        BallYSpeed => to_signed(0, 2),
        IsActive   => to_unsigned(0,2)
      ));

    ELSIF rising_edge(CLKxCI) THEN
      FsmStatexDP   <= FsmStatexDN;
      HighscorexDP  <= HighscorexDN;
      VSEdgexSP     <= VSEdgexSN;

      -- Update Balls
      BallsxDP      <= BallsxDN;

      -- Update plate
      PlateXxDP     <= PlateXxDN;
      PlateBumpxDP  <= PlateBumpxDN;
        
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
    PlateBumpxDN      <= PlateBumpxDP;

    -- State machine
    CASE FsmStatexDP IS
      --=========================================================================
      -- Game End Logic
      --=========================================================================
      WHEN GameEnd =>
        FsmStatexDN        <= GameEnd;
        VSEdgexSN          <= '0';
        HighScorexDN       <= to_unsigned(1,4);

        -- Update Balls
        BallsxDN <= (OTHERS => (
          BallX      => BALL_X_INIT,
          BallY      => BALL_Y_INIT,
          BallXSpeed => to_signed(0, 2),
          BallYSpeed => to_signed(0, 2),
          IsActive   => to_unsigned(0,2)
        ));
        
        -- Update Plate
        PlateXxDN          <= PLATE_X_INIT;

        -- Check if player starts game
        if(LeftxSI = '1' and RightxSI = '1') then
          FsmStatexDN  <= Game1Ball;
          VSEdgexSN <= '0';
          HighScorexDN <= to_unsigned(1,4);

--           BallsxDN <= (OTHERS => (
--             BallX      => BALL_X_INIT,
--             BallY      => BALL_Y_INIT,
--             BallXSpeed => to_signed(0, 2),
--             BallYSpeed => to_signed(1, 2),
--             IsActive   => to_unsigned(0,2)
--           ));
         BallsxDN(0).BallYSpeed <= to_signed(1,2);
         BallsxDN(0).IsActive <= to_unsigned(1,2);
        end if;

      WHEN Game1Ball =>
        IF(VSEdgexSP = '0' and VSEdgexSN = '1') then
          -- Check switching condition
          IF HighscorexDP > to_unsigned(3, 4) THEN
            BallsxDN(1).IsActive <= to_unsigned(1,2);
            BallsxDN(1).BallYSpeed <= to_signed(1,2);
            FsmStatexDN <= Game2Ball;
          END IF;
          
         MovePlate(PlateXxDP, PlateXxDN);
         UpdateBall(BallsxDP(0), BallsxDN(0), PlateBumpxDP(0), PlateBumpxDN(0), HighscorexDN, FsmStatexDN);

        END IF;

      WHEN Game2Ball =>
        IF(VSEdgexSP = '0' and VSEdgexSN = '1') then
          -- Check switching condition
          IF HighscorexDP > to_unsigned(5, 4) THEN
            BallsxDN(2).IsActive <= to_unsigned(1,2);
            BallsxDN(2).BallYSpeed <= to_signed(1,2);
            FsmStatexDN <= Game3Ball;
          END IF;
        
          MovePlate(PlateXxDP, PlateXxDN);       
          UpdateBall(BallsxDP(0), BallsxDN(0), PlateBumpxDP(0), PlateBumpxDN(0), HighscorexDN, FsmStatexDN);    
          UpdateBall(BallsxDP(1), BallsxDN(1), PlateBumpxDP(1), PlateBumpxDN(1), HighscorexDN, FsmStatexDN);

        END IF;

      WHEN Game3Ball =>
      IF(VSEdgexSP = '0' and VSEdgexSN = '1') then
       MovePlate(PlateXxDP, PlateXxDN);       UpdateBall(BallsxDP(0), BallsxDN(0), PlateBumpxDP(0), PlateBumpxDN(0), HighscorexDN, FsmStatexDN);  
       UpdateBall(BallsxDP(1), BallsxDN(1), PlateBumpxDP(1), PlateBumpxDN(1), HighscorexDN, FsmStatexDN);
       UpdateBall(BallsxDP(2), BallsxDN(2), PlateBumpxDP(2), PlateBumpxDN(2), HighscorexDN, FsmStatexDN);
      END IF;
      
      WHEN OTHERS =>
        FsmStatexDN <= GameEnd;

    END CASE;

  END PROCESS;

  FsmStatexDO <= FsmStatexDP;
  BallsxDO <= BallsxDP;
  PlateXxDO <= PlateXxDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================