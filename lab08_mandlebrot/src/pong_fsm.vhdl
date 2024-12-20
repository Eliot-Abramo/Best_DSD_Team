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

entity pong_fsm is
  port (
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
    BallsxDO    : out BallArrayType;

    -- Plate
    PlateXxDO   : out unsigned(COORD_BW - 1 downto 0);

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
  constant BALL_X_INIT  : unsigned(COORD_BW - 1 downto 0) := to_unsigned(HS_DISPLAY/2 - BALL_WIDTH/2, COORD_BW);
  constant BALL_Y_INIT  : unsigned(COORD_BW - 1 downto 0) := to_unsigned(VS_DISPLAY/2 - BALL_HEIGHT/2, COORD_BW);
  constant PLATE_X_INIT : unsigned(COORD_BW - 1 downto 0) := to_unsigned(HS_DISPLAY/2 - PLATE_WIDTH/2, COORD_BW);
  
  -- State of Plate
  signal PlateXxDP, PlateXxDN : unsigned(COORD_BW - 1 downto 0) := PLATE_X_INIT;
  
  -- Signal containing all of the balls
  signal BallsxDN, BallsxDP : BallArrayType := (others => (
    BallX      => BALL_X_INIT,
    BallY      => BALL_Y_INIT,
    BallXSpeed => to_signed(0, 2),
    BallYSpeed => to_signed(0, 2),
    IsActive   => to_unsigned(0, 2),
    Color      => BALL_RGB,
    Counter    => to_unsigned(0, 3)
  ));

  -- States of FSM
  signal FsmStatexDP, FsmStatexDN : GameControl := GameEnd;

  -- For controlling the screen
  signal VSEdgexSP, VSEdgexSN : std_logic := '0';

  -- Highscore init
  signal HighscorexDN, HighscorexDP : unsigned(HIGH_SCORE_WIDTH-1 downto 0) := to_unsigned(1, HIGH_SCORE_WIDTH);

  signal PlateWidthxDN, PlateWidthxDP : natural := PLATE_WIDTH;
  signal PlateStepXxDN, PlateStepXxDP : natural := PLATE_STEP_X;

--=============================================================================
-- PROCEDURE DECLARATION
--=============================================================================
-- Procedure to handle ball updates and collisions
procedure UpdateBall (
  signal BallIn        : in BallType;
  signal BallOut       : out BallType;
  signal PlateX        : in unsigned(COORD_BW - 1 downto 0);
  signal HighScoreIn   : in unsigned(HIGH_SCORE_WIDTH-1 downto 0);
  signal HighscoreOut  : out unsigned(HIGH_SCORE_WIDTH - 1 downto 0);
  signal FsmState      : out GameControl;
  signal PlateWidthIn  : in natural;
  signal PlateWidthOut : out natural;
  signal PlateSpeedIn  : in natural;
  signal PlateSpeedOut : out natural
) is
  -- Local variables for PlateBump
  variable PlateLeft  : signed(COORD_BW - 1 downto 0);
  variable PlateRight : signed(COORD_BW - 1 downto 0);

begin
  -- Calculate PlateBump values based on the current ball and plate positions
  PlateLeft  := resize(signed(resize(BallIn.BallX, COORD_BW + 1)) - signed(resize(PlateX, COORD_BW + 1)), COORD_BW);
  PlateRight := resize(signed(resize(BallIn.BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateX, COORD_BW + 1)), COORD_BW);

  -- Check for horizontal wall collisions
  if (BallIn.BallX <= 2 * BALL_STEP_X and BallIn.BallXSpeed < 0) or
      (BallIn.BallX >= (HS_DISPLAY - BALL_WIDTH - BALL_STEP_X) and BallIn.BallXSpeed > 0) then
    BallOut.BallXSpeed <= -BallIn.BallXSpeed;
  else
    BallOut.BallXSpeed <= BallIn.BallXSpeed;
  end if;

  -- Check for vertical wall collisions
  if (BallIn.BallY <= 2 * BALL_STEP_Y and BallIn.BallYSpeed < 0) then
    BallOut.BallYSpeed <= -BallIn.BallYSpeed;
  else
    BallOut.BallYSpeed <= BallIn.BallYSpeed;
  end if;

  -- Check for collisions with the plate
  if (BallIn.BallY >= VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT) then
    if (PlateRight > 0 and PlateLeft < PlateWidthIn) then
      if (BallIn.BallYSpeed >= 0) then
        if (HighscoreIn < 10) then
          HighscoreOut <= HighscoreIn + 1;
          PlateWidthOut <= PlateWidthIn - 10;
        end if;

        BallOut.BallYSpeed <= -BallIn.BallYSpeed;
        if PlateRight < (PlateWidthIn / 3) then
            BallOut.BallXSpeed <= to_signed(-1, 2);
        elsif PlateRight < ((2 * PlateWidthIn) / 3) then
            BallOut.BallXSpeed <= to_signed(0, 2);
        else
            BallOut.BallXSpeed <= to_signed(1, 2);
        end if;

        case (BallIn.Counter) is 
          when to_unsigned(0, 3) => BallOut.Color <= x"F00";
          when to_unsigned(1, 3) => BallOut.Color <= x"0F0";
          when to_unsigned(2, 3) => BallOut.Color <= x"F0F";
          when to_unsigned(3, 3) => BallOut.Color <= x"FF0";
          when others            => BallOut.Color <= BALL_RGB;
        end case;

        BallOut.Counter <= to_unsigned((to_integer(BallIn.Counter) + 1) mod MAX_BALL_COUNT, BallIn.Counter'length);

        PlateSpeedOut <= PlateSpeedIn + 1;

      end if;
    --------------------
    else
      FsmState <= GameEnd;
    end if;
  end if;

  -- Update ball position
  BallOut.BallX <= resize(unsigned(signed(resize(BallIn.BallX, COORD_BW + 1)) + resize(BallIn.BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
  BallOut.BallY <= resize(unsigned(signed(resize(BallIn.BallY, COORD_BW + 1)) + resize(BallIn.BallYSpeed, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);

end procedure;

--=============================================================================

-- Procedure to handle plate movement
procedure MovePlate(
    signal PlateIn  : in unsigned(COORD_BW - 1 downto 0);
    signal PlateOut : out unsigned(COORD_BW - 1 downto 0)
) is 
begin
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

end procedure;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin
  --===========================================================================
  -- Clock and Reset Process
  --===========================================================================
  process(CLKxCI, RSTxRI)
  begin
    -- Asynchronous reset
    if (RSTxRI = '1') then
      FsmStatexDP        <= GameEnd;
      VSEdgexSP          <= '0';

      PlateXxDP          <= PLATE_X_INIT;
      HighscorexDP       <= to_unsigned(1, HIGH_SCORE_WIDTH);

      BallsxDP <= (others => (
        BallX      => BALL_X_INIT,
        BallY      => BALL_Y_INIT,
        BallXSpeed => to_signed(0, 2),
        BallYSpeed => to_signed(0, 2),
        IsActive   => to_unsigned(0, 2),
        Color      => BALL_RGB,
        Counter    => to_unsigned(0, 3)
      ));

      PlateWidthxDP <= PLATE_WIDTH;
      PlateStepXxDP <= PLATE_STEP_X;
      
    elsif rising_edge(CLKxCI) then
      -- Update FSM information
      FsmStatexDP   <= FsmStatexDN;
      HighscorexDP  <= HighscorexDN;
      VSEdgexSP     <= VSEdgexSN;

      -- Update Balls
      BallsxDP      <= BallsxDN;

      -- Update plate
      PlateXxDP     <= PlateXxDN;

      PlateWidthxDP <= PlateWidthxDN;
      PlateStepXxDP <= PlateStepXxDN;
    end if;

  end process;

  --===========================================================================
  -- Game Evolution logic
  --===========================================================================
  process (all)
  begin
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
    case FsmStatexDP is
      --=========================================================================
      -- Game End Logic
      --=========================================================================

      -- Game over logic
      when GameEnd =>
        FsmStatexDN        <= GameEnd;
        VSEdgexSN          <= '0';
        HighScorexDN       <= to_unsigned(1, HIGH_SCORE_WIDTH);

        -- Update Balls
        BallsxDN <= (others => (
          BallX      => BALL_X_INIT,
          BallY      => BALL_Y_INIT,
          BallXSpeed => to_signed(0, 2),
          BallYSpeed => to_signed(0, 2),
          IsActive   => to_unsigned(0, 2),
          Color      => BALL_RGB,
          Counter    => to_unsigned(0, 3)
        ));
        
        -- Update Plate
        PlateXxDN          <= PLATE_X_INIT;
        PlateWidthxDN      <= PLATE_WIDTH;
        PlateStepXxDN      <= PLATE_STEP_X;

        -- Check if player starts game
        if (LeftxSI = '1' and RightxSI = '1') then
          FsmStatexDN  <= Game1Ball;
          HighScorexDN <= to_unsigned(1, HIGH_SCORE_WIDTH);
          BallsxDN(0).BallYSpeed <= to_signed(1, 2);
          BallsxDN(0).BallX <= BALL_X_INIT;
          BallsxDN(0).BallY <= BALL_Y_INIT;
          BallsxDN(0).IsActive <= to_unsigned(1, 2);
        end if;
      
      -- Logic for ball 1
      when Game1Ball =>
        if (VSEdgexSP = '0' and VSEdgexSN = '1') then
          -- Check switching condition
          if HighscorexDP > HIGH_SCORE_1_THRESHOLD then
            BallsxDN(1).IsActive <= to_unsigned(1, 2);
            BallsxDN(1).BallYSpeed <= to_signed(1, 2);
            BallsxDN(1).BallX <= BALL_X_INIT;
            BallsxDN(1).BallY <= BALL_Y_INIT;
            FsmStatexDN <= Game2Ball;
          end if;
          
          MovePlate(PlateXxDP, PlateXxDN);
          UpdateBall(BallsxDP(0), BallsxDN(0), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
        end if;

      -- Logic for ball 2
      when Game2Ball =>
        if (VSEdgexSP = '0' and VSEdgexSN = '1') then
          -- Check switching condition
          if HighscorexDP > HIGH_SCORE_2_THRESHOLD then
            BallsxDN(2).IsActive <= to_unsigned(1, 2);
            BallsxDN(2).BallYSpeed <= to_signed(-1, 2);
            BallsxDN(2).BallX <= BALL_X_INIT;
            BallsxDN(2).BallY <= BALL_Y_INIT;
            FsmStatexDN <= Game3Ball;
          end if;

          MovePlate(PlateXxDP, PlateXxDN);       
          UpdateBall(BallsxDP(0), BallsxDN(0), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
          UpdateBall(BallsxDP(1), BallsxDN(1), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
        end if;

      -- Logic for ball 3
      when Game3Ball =>
        if (VSEdgexSP = '0' and VSEdgexSN = '1') then
          MovePlate(PlateXxDP, PlateXxDN);       
          UpdateBall(BallsxDP(0), BallsxDN(0), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
          UpdateBall(BallsxDP(1), BallsxDN(1), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
          UpdateBall(BallsxDP(2), BallsxDN(2), PlateXxDP, HighscorexDP, HighscorexDN, FsmStatexDN, PlateWidthxDP, PlateWidthxDN, PlateStepXxDP, PlateStepXxDN);
        end if;
      
      when others =>
        FsmStatexDN  <= GameEnd;
        VSEdgexSN    <= '0';
        HighScorexDN <= to_unsigned(1, HIGH_SCORE_WIDTH);

    end case;

  end process;

  -- Update game informations in process
  BallsxDO  <= BallsxDP;
  PlateXxDO <= PlateXxDP;
  FsmStatexDO   <= FsmStatexDP;
  PlateWidthxDO <= PlateWidthxDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================