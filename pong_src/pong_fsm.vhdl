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

ENTITY pong_fsm is
  PORT (
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

    -- Highscore Values
    HighscorexDO : out natural;

    -- State
    FsmStatexDO  : out std_logic;

    -- Multiple balls
    BallsxDO       : out BallArrayType;
    ActiveBallsxDO : out natural;

    -- Plate
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
  
  -- State of Plate
  SIGNAL PlateXxDP, PlateXxDN  : unsigned(COORD_BW - 1 DOWNTO 0) := PLATE_X_INIT;
  -- Bottom left corner
  SIGNAL PlateLeftxD  : signed(COORD_BW-1 downto 0) := resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
  -- Bottom right corner 
  SIGNAL PlateRightxD : signed(COORD_BW - 1 downto 0) := resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW); 

  -- Signal containing all of the balls
  SIGNAL BallsxDN, BallsxDP : BallArrayType := (OTHERS => (
    BallX      => BALL_X_INIT,
    BallY      => BALL_Y_INIT,
    BallXSpeed => to_signed(0, 2),
    BallYSpeed => to_signed(0, 2)

    -- PlateLeftxD => resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW),
    -- PlateRightxD => resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW)
  ));

  -- Number of active balls
  SIGNAL ActiveBallsxDP, ActiveBallsxDN : natural := 1;

  -- States of FSM
  TYPE GameControl IS (GameStart, GameEnd);
  SIGNAL FsmStatexDP, FsmStatexDN : GameControl := GameEnd;

  -- For controlling the screen
  SIGNAL VSEdgexSN, VSEdgexSP : std_logic := '0';

  -- Highscore init
  SIGNAL HighscorexDN, HighscorexDP : natural := 0;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin
  --===========================================================================
  -- Clock and Reset Process
  --===========================================================================
  PROCESS(CLKxCI, RSTxRI, VSEdgexSI)
  BEGIN
    IF (RSTxRI = '1') THEN
      FsmStatexDP        <= GameStart;
      VSEdgexSP          <= '0';

      PlateXxDP          <= PLATE_X_INIT;
      HighscorexDP       <= 0;
      ActiveBallsxDP     <= 1;

      BallsxDP <= (OTHERS => (
        BallX      => BALL_X_INIT,
        BallY      => BALL_Y_INIT,
        BallXSpeed => to_signed(0, 2),
        BallYSpeed => to_signed(0, 2)
      ));

    ELSIF rising_edge(CLKxCI) THEN
      FsmStatexDP   <= FsmStatexDN;
      PlateXxDP     <= PlateXxDN;
      BallsxDP      <= BallsxDN;
      ActiveBallsxDP <= ActiveBallsxDN;

      HighscorexDP  <= HighscorexDN;
      VSEdgexSP     <= VSEdgexSN;
    END IF;

  END PROCESS; 

  --===========================================================================
  -- Game Evolution logic
  --===========================================================================
  PROCESS (ALL)
  BEGIN
    --===========================================================================
    -- Update Plate boundaries to ensure correct collision control
    --===========================================================================
    -- FOR i IN 0 TO (MaxBallCount)-1 LOOP
    --   IF(i < ActiveBallsxDP) THEN
        -- BallsxDN(i).PlateLeftxD <= resize(signed(resize(BallsxDP(i).BallX, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
        -- BallsxDN(i).PlateRightxD <= resize(signed(resize(BallsxDP(i).BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
    --   END IF;
    -- END LOOP;

    --===========================================================================
    -- Update system variables
    --===========================================================================
    FsmStatexDN       <= FsmStatexDP;
    VSEdgexSN         <= VSEdgexSI;
    HighscorexDN      <= HighscorexDP;
    PlateXxDN         <= PlateXxDP;
    BallsxDN          <= BallsxDP;
    ActiveBallsxDN    <= ActiveBallsxDP;

    -- if HighscorexDP >= (ActiveBallsxDP * 2) then
    --   if (ActiveBallsxDP < MaxBallCount) then
    --     ActiveBallsxDN <= ActiveBallsxDP + 1;
    --   end if;
    -- end if;
    
    -- State machine
    CASE FsmStatexDP IS
      --=========================================================================
      -- Game End Logic
      --=========================================================================
      WHEN GameEnd =>
        FsmStatexDN     <= GameEnd;
        PlateXxDN       <= PLATE_X_INIT;
        ActiveBallsxDN  <= 1;
        
        BallsxDN <= (OTHERS => (
          BallX      => BALL_X_INIT,
          BallY      => BALL_Y_INIT,
          BallXSpeed => to_signed(0, 2),
          BallYSpeed => to_signed(0, 2)
        ));

        -- Check if player starts game:
        if(LeftxSI = '1' and RightxSI = '1') then
          FsmStatexDN  <= GameStart;
          HighScorexDN <= 0;
          
          BallsxDN <= (OTHERS => (
            BallX      => BALL_X_INIT,
            BallY      => BALL_Y_INIT,
            BallXSpeed => to_signed(0, 2),
            BallYSpeed => to_signed(1, 2)
            ));

        end if;

      --=========================================================================
      -- Game Start Logic
      --=========================================================================
      WHEN GameStart =>
        -- Update frames of game
        if(VSEdgexSP = '0' and VSEdgexSN = '1') then
          FOR i IN 0 TO (MaxBallCount)-1 LOOP
            if(LeftxSI = '1') then
              -- check plate is moving correctly
              if PlateXxDP <= PLATE_STEP_X then
                PlateXxDN <= PlateXxDP + HS_DISPLAY - PLATE_STEP_X;
              else
                PlateXxDN <= PlateXxDP - PLATE_STEP_X;
              end if;
            end if;
          
            if(RightxSI = '1') then
              PlateXxDN <= PlateXxDP + PLATE_STEP_X;
              -- check plate is moving correctly
              if PlateXxDP >= HS_DISPLAY - PLATE_STEP_X then
                PlateXxDN <= PlateXxDP - HS_DISPLAY + PLATE_STEP_X;
              else
                PlateXxDN <= PlateXxDP + PLATE_STEP_X;
              end if;
            end if;

            IF(i < ActiveBallsxDP) THEN          
              -- check if ball hits the sides of the map
              if((BallsxDP(i).BallX <= 2*BALL_STEP_X) and (BallsxDP(i).BallXSpeed < 0)) or ((BallsxDP(i).BallX >= (HS_DISPLAY - BALL_WIDTH - BALL_STEP_X)) and (BallsxDP(i).BallXSpeed  > 0)) then
                BallsxDN(i).BallXSpeed <= - BallsxDP(i).BallXSpeed;
              end if;

              if((BallsxDP(i).BallY <= 2*BALL_STEP_Y) and (BallsxDP(i).BallYSpeed < 0)) then
                BallsxDN(i).BallYSpeed <= - BallsxDP(i).BallYSpeed;
              end if;
      
              -- check collisions with plate
              if(BallsxDP(i).BallY >= (VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT)) then
                if((PlateRightxD > 0) and (PlateLeftxD < PLATE_WIDTH)) then 
                  if(BallsxDP(i).BallYSpeed >= 0) then
                    HighscorexDN <= HighscorexDP + 1;
                    BallsxDN(i).BallYSpeed <= - BallsxDP(i).BallYSpeed;
                    BallsxDN(i).BallXSpeed <= to_signed(-1, 2) when PlateRightxD < (PLATE_WIDTH / 3)
                                                               else to_signed(0, 2) when PlateRightxD < ((2*PLATE_WIDTH)/ 3) 
                                                               else to_signed(1, 2);                    
                  end if;
                else
                  FsmStatexDN <= GameEnd;
                end if;
              end if;

              BallsxDN(i).BallX <= resize(unsigned(signed(resize(BallsxDP(i).BallX, COORD_BW + 1)) + resize(BallsxDP(i).BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
              BallsxDN(i).BallY <= resize(unsigned(signed(resize(BallsxDP(i).BallY, COORD_BW + 1)) + resize(BallsxDP(i).BallYSPeed, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);
              
              PlateLeftxD <= resize(signed(resize(BallsxDN(i).BallX, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
              PlateRightxD <= resize(signed(resize(BallsxDN(i).BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);  
            end if;
          END LOOP;
        end if;

      -- Incase other cases appear, reset game
      WHEN OTHERS =>
        FsmStatexDN     <= GameEnd;
        PlateXxDN       <= PLATE_X_INIT;
        ActiveBallsxDN  <= 1;

        BallsxDN <= (OTHERS => (
          BallX      => BALL_X_INIT,
          BallY      => BALL_Y_INIT,
          BallXSpeed => to_signed(0, 4),
          BallYSpeed => to_signed(0, 4)
        ));
    
    END CASE;

  END PROCESS;

  FsmStatexDO <= '0' when FsmStatexDP = GameEnd else '1';
  HighscorexDO <= HighscorexDP;
  PlateXxDO <= PlateXxDP;
  ActiveBallsxDO <= ActiveBallsxDP;
  BallsxDO <= BallsxDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
