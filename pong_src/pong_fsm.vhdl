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
  CONSTANT BALL_X_INIT                : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(HS_DISPLAY/2 - BALL_WIDTH/2, COORD_BW);
  CONSTANT BALL_Y_INIT                : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(VS_DISPLAY/2 - BALL_HEIGHT/2, COORD_BW);
  CONSTANT PLATE_X_INIT               : unsigned(COORD_BW - 1 DOWNTO 0) := to_unsigned(HS_DISPLAY/2 - PLATE_WIDTH/2, COORD_BW);
  
  -- State of Plate
  SIGNAL PlateXxDP, PlateXxDN         : unsigned(COORD_BW - 1 DOWNTO 0) := PLATE_X_INIT;
  -- Bottom left corner
  SIGNAL PlateLeft0xDP, PlateLeft0xDN   : signed(COORD_BW-1 downto 0) := resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
  -- Bottom right corner 
  SIGNAL PlateRight0xDP, PlateRight0xDN : signed(COORD_BW - 1 downto 0) := resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW); 

  -- Bottom left corner
  SIGNAL PlateLeft1xDP, PlateLeft1xDN   : signed(COORD_BW-1 downto 0) := resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
  -- Bottom right corner 
  SIGNAL PlateRight1xDP, PlateRight1xDN : signed(COORD_BW - 1 downto 0) := resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW); 

  -- Bottom left corner
  SIGNAL PlateLeft2xDP, PlateLeft2xDN   : signed(COORD_BW-1 downto 0) := resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
  -- Bottom right corner 
  SIGNAL PlateRight2xDP, PlateRight2xDN : signed(COORD_BW - 1 downto 0) := resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW); 

  -- Signal containing all of the balls
  SIGNAL BallsxDN, BallsxDP : BallArrayType := (OTHERS => (
    BallX      => BALL_X_INIT,
    BallY      => BALL_Y_INIT,
    BallXSpeed => to_signed(0, 2),
    BallYSpeed => to_signed(0, 2)
  ));

  -- Number of active balls
  SIGNAL ActiveBallsxDP, ActiveBallsxDN : unsigned(4-1 DOWNTO 0) := to_unsigned(1,4);

  -- States of FSM
  SIGNAL FsmStatexDP, FsmStatexDN : GameControl := GameEnd;

  -- For controlling the screen
  SIGNAL VSEdgexSN, VSEdgexSP : std_logic := '0';

  -- Highscore init
  SIGNAL HighscorexDN, HighscorexDP : unsigned(4-1 DOWNTO 0) := to_unsigned(1,4);

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
      ActiveBallsxDP     <= to_unsigned(1,4);

      PlateLeft0xDP       <= resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
      PlateRight0xDP      <= resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);

      PlateLeft1xDP       <= resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
      PlateRight1xDP      <= resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);

      PlateLeft2xDP       <= resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
      PlateRight2xDP      <= resize(signed(resize(Ball_X_INIT, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);

      BallsxDP <= (OTHERS => (
        BallX      => BALL_X_INIT,
        BallY      => BALL_Y_INIT,
        BallXSpeed => to_signed(0, 2),
        BallYSpeed => to_signed(0, 2)
      ));

    ELSIF rising_edge(CLKxCI) THEN
      FsmStatexDP   <= FsmStatexDN;
      HighscorexDP  <= HighscorexDN;
      VSEdgexSP     <= VSEdgexSN;

      -- Update Balls
      BallsxDP      <= BallsxDN;
      ActiveBallsxDP <= ActiveBallsxDN;

      -- Update plate
      PlateXxDP     <= PlateXxDN;

      PlateLeft0xDP  <= PlateLeft0xDN;
      PlateRight0xDP <= PlateRight0xDN;

      PlateLeft1xDP  <= PlateLeft1xDN;
      PlateRight1xDP <= PlateRight1xDN;

      PlateLeft2xDP  <= PlateLeft2xDN;
      PlateRight2xDP <= PlateRight2xDN;

      
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
    ActiveBallsxDN    <= ActiveBallsxDP;

    -- Update Plate
    PlateXxDN         <= PlateXxDP;

    PlateLeft0xDN      <= PlateLeft0xDP;
    PlateRight0xDN     <= PlateRight0xDP;

    PlateLeft1xDN      <= PlateLeft1xDP;
    PlateRight1xDN     <= PlateRight1xDP;

    PlateLeft2xDN      <= PlateLeft2xDP;
    PlateRight2xDN     <= PlateRight2xDP;

    
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
          BallYSpeed => to_signed(0, 2)
        ));
        ActiveBallsxDN     <= to_unsigned(1,4);

        -- Update Plate
        PlateXxDN          <= PLATE_X_INIT;

        -- Check if player starts game:
        if(LeftxSI = '1' and RightxSI = '1') then
          FsmStatexDN  <= Game2Ball;
          VSEdgexSN <= '0';
          HighScorexDN <= to_unsigned(1,4);

          ActiveBallsxDN <= to_unsigned(1,4);          
          BallsxDN <= (OTHERS => (
            BallX      => BALL_X_INIT,
            BallY      => BALL_Y_INIT,
            BallXSpeed => to_signed(0, 2),
            BallYSpeed => to_signed(1, 2)
            ));

        end if;

      --=========================================================================
      -- Game One Ball Logic
      --=========================================================================
      WHEN Game1Ball =>
        -- Update frames of game
        if(VSEdgexSP = '0' and VSEdgexSN = '1') then
          -- Conditions to make FSM evolve to future states
          if((HighscorexDP > to_unsigned(3,4))) then
            FsmStatexDN    <= Game2Ball;
            ActiveBallsxDN <= to_unsigned(2,4);
          end if;
          
          -- Check motion of plate
          if(LeftxSI = '1') then
            if PlateXxDP <= PLATE_STEP_X then
              PlateXxDN <= PlateXxDP + HS_DISPLAY - PLATE_STEP_X;
            else
              PlateXxDN <= PlateXxDP - PLATE_STEP_X;
            end if;
          end if;
        
          if(RightxSI = '1') then
            PlateXxDN <= PlateXxDP + PLATE_STEP_X;
            if PlateXxDP >= HS_DISPLAY - PLATE_STEP_X then
              PlateXxDN <= PlateXxDP - HS_DISPLAY + PLATE_STEP_X;
            else
              PlateXxDN <= PlateXxDP + PLATE_STEP_X;
            end if;
          end if;

          --=====================================================================
          -- Make Ball One Evolve
          --=====================================================================
          -- check if ball hits the sides of the map
          if((BallsxDP(0).BallX <= 2*BALL_STEP_X) and (BallsxDP(0).BallXSpeed < 0)) or ((BallsxDP(0).BallX >= (HS_DISPLAY - BALL_WIDTH - BALL_STEP_X)) and (BallsxDP(0).BallXSpeed  > 0)) then
            BallsxDN(0).BallXSpeed <= - BallsxDP(0).BallXSpeed;
            end if;

            if((BallsxDP(0).BallY <= 2*BALL_STEP_Y) and (BallsxDP(0).BallYSpeed < 0)) then
              BallsxDN(0).BallYSpeed <= - BallsxDP(0).BallYSpeed;
            end if;
      
            -- check collisions with plate
            if(BallsxDP(0).BallY >= (VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT)) then
              if((PlateRight0xDP > 0) and (PlateLeft0xDP < PLATE_WIDTH)) then 
                if(BallsxDP(0).BallYSpeed >= 0) then
                  HighscorexDN <= HighscorexDP + 1;
                  
                  BallsxDN(0).BallYSpeed <= - BallsxDP(0).BallYSpeed;
                  BallsxDN(0).BallXSpeed <= to_signed(-1, 2) when PlateRight0xDP < (PLATE_WIDTH / 3)
                                                             else to_signed(0, 2) when PlateRight0xDP < ((2*PLATE_WIDTH)/ 3) 
                                                             else to_signed(1, 2);                    
                end if;
              else
                FsmStatexDN <= GameEnd;
              end if;
          end if;

          BallsxDN(0).BallX <= resize(unsigned(signed(resize(BallsxDP(0).BallX, COORD_BW + 1)) + resize(BallsxDP(0).BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
          BallsxDN(0).BallY <= resize(unsigned(signed(resize(BallsxDP(0).BallY, COORD_BW + 1)) + resize(BallsxDP(0).BallYSPeed, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);
              
          PlateLeft0xDN <= resize(signed(resize(BallsxDN(0).BallX, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
          PlateRight0xDN <= resize(signed(resize(BallsxDN(0).BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);  
        end if;



      --=========================================================================
      -- Game Two Ball Logic
      --=========================================================================
      WHEN Game2Ball =>
        -- Update frames of game
        if(VSEdgexSP = '0' and VSEdgexSN = '1') then
          if ((HighscorexDP > to_unsigned(5,4))) then
            FsmStatexDN <= Game3Ball;
            ActiveBallsxDN <= to_unsigned(3,4);
          end if;
          
          -- Check motion of plate
          if(LeftxSI = '1') then
            if PlateXxDP <= PLATE_STEP_X then
              PlateXxDN <= PlateXxDP + HS_DISPLAY - PLATE_STEP_X;
            else
              PlateXxDN <= PlateXxDP - PLATE_STEP_X;
            end if;
          end if;
        
          if(RightxSI = '1') then
            PlateXxDN <= PlateXxDP + PLATE_STEP_X;
            if PlateXxDP >= HS_DISPLAY - PLATE_STEP_X then
              PlateXxDN <= PlateXxDP - HS_DISPLAY + PLATE_STEP_X;
            else
              PlateXxDN <= PlateXxDP + PLATE_STEP_X;
            end if;
          end if;

          --=====================================================================
          -- Make Ball One Evolve
          --=====================================================================
          -- check if ball hits the sides of the map
          if((BallsxDP(0).BallX <= 2*BALL_STEP_X) and (BallsxDP(0).BallXSpeed < 0)) or ((BallsxDP(0).BallX >= (HS_DISPLAY - BALL_WIDTH - BALL_STEP_X)) and (BallsxDP(0).BallXSpeed  > 0)) then
            BallsxDN(0).BallXSpeed <= - BallsxDP(0).BallXSpeed;
            end if;

            if((BallsxDP(0).BallY <= 2*BALL_STEP_Y) and (BallsxDP(0).BallYSpeed < 0)) then
              BallsxDN(0).BallYSpeed <= - BallsxDP(0).BallYSpeed;
            end if;
      
            -- check collisions with plate
            if(BallsxDP(0).BallY >= (VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT)) then
              if((PlateRight0xDP > 0) and (PlateLeft0xDP < PLATE_WIDTH)) then 
                if(BallsxDP(0).BallYSpeed >= 0) then
                  HighscorexDN <= HighscorexDP + 1;
                  
                  BallsxDN(0).BallYSpeed <= - BallsxDP(0).BallYSpeed;
                  BallsxDN(0).BallXSpeed <= to_signed(-1, 2) when PlateRight0xDP < (PLATE_WIDTH / 3)
                                                             else to_signed(0, 2) when PlateRight0xDP < ((2*PLATE_WIDTH)/ 3) 
                                                             else to_signed(1, 2);                    
                end if;
              else
                FsmStatexDN <= GameEnd;
              end if;
          end if;

          BallsxDN(0).BallX <= resize(unsigned(signed(resize(BallsxDP(0).BallX, COORD_BW + 1)) + resize(BallsxDP(0).BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
          BallsxDN(0).BallY <= resize(unsigned(signed(resize(BallsxDP(0).BallY, COORD_BW + 1)) + resize(BallsxDP(0).BallYSPeed, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);
              
          PlateLeft0xDN <= resize(signed(resize(BallsxDN(0).BallX, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
          PlateRight0xDN <= resize(signed(resize(BallsxDN(0).BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
          
          --=====================================================================
          -- Make Ball Two Evolve
          --=====================================================================
          -- check if ball hits the sides of the map
          if((BallsxDP(1).BallX <= 2*BALL_STEP_X) and (BallsxDP(1).BallXSpeed < 1)) or ((BallsxDP(1).BallX >= (HS_DISPLAY - BALL_WIDTH - BALL_STEP_X)) and (BallsxDP(1).BallXSpeed  > 0)) then
            BallsxDN(1).BallXSpeed <= - BallsxDP(1).BallXSpeed;
            end if;

            if((BallsxDP(1).BallY <= 2*BALL_STEP_Y) and (BallsxDP(1).BallYSpeed < 0)) then
              BallsxDN(1).BallYSpeed <= - BallsxDP(1).BallYSpeed;
            end if;
      
            -- check collisions with plate
            if(BallsxDP(1).BallY >= (VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT)) then
              if((PlateRight1xDP > 0) and (PlateLeft1xDP < PLATE_WIDTH)) then 
                if(BallsxDP(1).BallYSpeed >= 0) then
                  HighscorexDN <= HighscorexDP + 1;
                  
                  BallsxDN(1).BallYSpeed <= - BallsxDP(0).BallYSpeed;
                  BallsxDN(1).BallXSpeed <= to_signed(-1, 2) when PlateRight1xDP < (PLATE_WIDTH / 3)
                                                             else to_signed(0, 2) when PlateRight1xDP < ((2*PLATE_WIDTH)/ 3) 
                                                             else to_signed(1, 2);                    
                end if;
              else
                FsmStatexDN <= GameEnd;
              end if;
          end if;

          BallsxDN(1).BallX <= resize(unsigned(signed(resize(BallsxDP(0).BallX, COORD_BW + 1)) + resize(BallsxDP(0).BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
          BallsxDN(1).BallY <= resize(unsigned(signed(resize(BallsxDP(0).BallY, COORD_BW + 1)) + resize(BallsxDP(0).BallYSPeed, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);
              
          PlateLeft1xDN <= resize(signed(resize(BallsxDN(1).BallX, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
          PlateRight1xDN <= resize(signed(resize(BallsxDN(1).BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
        end if;
    
      --=========================================================================
      -- Game Three Ball Logic
      --=========================================================================
      WHEN Game3Ball =>
        -- Update frames of game
        if(VSEdgexSP = '0' and VSEdgexSN = '1') then
          -- Check motion of plate
          if(LeftxSI = '1') then
            if PlateXxDP <= PLATE_STEP_X then
              PlateXxDN <= PlateXxDP + HS_DISPLAY - PLATE_STEP_X;
            else
              PlateXxDN <= PlateXxDP - PLATE_STEP_X;
            end if;
          end if;
        
          if(RightxSI = '1') then
            PlateXxDN <= PlateXxDP + PLATE_STEP_X;
            if PlateXxDP >= HS_DISPLAY - PLATE_STEP_X then
              PlateXxDN <= PlateXxDP - HS_DISPLAY + PLATE_STEP_X;
            else
              PlateXxDN <= PlateXxDP + PLATE_STEP_X;
            end if;
          end if;

          --=====================================================================
          -- Make Ball One Evolve
          --=====================================================================
          -- check if ball hits the sides of the map
          if((BallsxDP(0).BallX <= 2*BALL_STEP_X) and (BallsxDP(0).BallXSpeed < 0)) or ((BallsxDP(0).BallX >= (HS_DISPLAY - BALL_WIDTH - BALL_STEP_X)) and (BallsxDP(0).BallXSpeed  > 0)) then
            BallsxDN(0).BallXSpeed <= - BallsxDP(0).BallXSpeed;
            end if;

            if((BallsxDP(0).BallY <= 2*BALL_STEP_Y) and (BallsxDP(0).BallYSpeed < 0)) then
              BallsxDN(0).BallYSpeed <= - BallsxDP(0).BallYSpeed;
            end if;
      
            -- check collisions with plate
            if(BallsxDP(0).BallY >= (VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT)) then
              if((PlateRight0xDP > 0) and (PlateLeft0xDP < PLATE_WIDTH)) then 
                if(BallsxDP(0).BallYSpeed >= 0) then
                  
                  BallsxDN(0).BallYSpeed <= - BallsxDP(0).BallYSpeed;
                  BallsxDN(0).BallXSpeed <= to_signed(-1, 2) when PlateRight0xDP < (PLATE_WIDTH / 3)
                                                             else to_signed(0, 2) when PlateRight0xDP < ((2*PLATE_WIDTH)/ 3) 
                                                             else to_signed(1, 2);                    
                end if;
              else
                FsmStatexDN <= GameEnd;
              end if;
          end if;

          BallsxDN(0).BallX <= resize(unsigned(signed(resize(BallsxDP(0).BallX, COORD_BW + 1)) + resize(BallsxDP(0).BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
          BallsxDN(0).BallY <= resize(unsigned(signed(resize(BallsxDP(0).BallY, COORD_BW + 1)) + resize(BallsxDP(0).BallYSPeed, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);
              
          PlateLeft0xDN <= resize(signed(resize(BallsxDN(0).BallX, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
          PlateRight0xDN <= resize(signed(resize(BallsxDN(0).BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
          
          --=====================================================================
          -- Make Ball Two Evolve
          --=====================================================================
          -- check if ball hits the sides of the map
          if((BallsxDP(1).BallX <= 2*BALL_STEP_X) and (BallsxDP(1).BallXSpeed < 1)) or ((BallsxDP(1).BallX >= (HS_DISPLAY - BALL_WIDTH - BALL_STEP_X)) and (BallsxDP(1).BallXSpeed  > 0)) then
            BallsxDN(1).BallXSpeed <= - BallsxDP(1).BallXSpeed;
            end if;

            if((BallsxDP(1).BallY <= 2*BALL_STEP_Y) and (BallsxDP(1).BallYSpeed < 0)) then
              BallsxDN(1).BallYSpeed <= - BallsxDP(1).BallYSpeed;
            end if;
      
            -- check collisions with plate
            if(BallsxDP(1).BallY >= (VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT)) then
              if((PlateRight1xDP > 0) and (PlateLeft1xDP < PLATE_WIDTH)) then 
                if(BallsxDP(1).BallYSpeed >= 0) then
                  
                  BallsxDN(1).BallYSpeed <= - BallsxDP(1).BallYSpeed;
                  BallsxDN(1).BallXSpeed <= to_signed(-1, 2) when PlateRight1xDP < (PLATE_WIDTH / 3)
                                                             else to_signed(0, 2) when PlateRight1xDP < ((2*PLATE_WIDTH)/ 3) 
                                                             else to_signed(1, 2);                    
                end if;
              else
                FsmStatexDN <= GameEnd;
              end if;
          end if;

          BallsxDN(1).BallX <= resize(unsigned(signed(resize(BallsxDP(1).BallX, COORD_BW + 1)) + resize(BallsxDP(1).BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
          BallsxDN(1).BallY <= resize(unsigned(signed(resize(BallsxDP(1).BallY, COORD_BW + 1)) + resize(BallsxDP(1).BallYSPeed, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);
              
          PlateLeft1xDN <= resize(signed(resize(BallsxDN(1).BallX, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
          PlateRight1xDN <= resize(signed(resize(BallsxDN(1).BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);

          --=====================================================================
          -- Make Ball Three Evolve
          --=====================================================================
          -- check if ball hits the sides of the map
          if((BallsxDP(2).BallX <= 2*BALL_STEP_X) and (BallsxDP(2).BallXSpeed < 1)) or ((BallsxDP(2).BallX >= (HS_DISPLAY - BALL_WIDTH - BALL_STEP_X)) and (BallsxDP(2).BallXSpeed  > 0)) then
            BallsxDN(2).BallXSpeed <= - BallsxDP(2).BallXSpeed;
            end if;

            if((BallsxDP(2).BallY <= 2*BALL_STEP_Y) and (BallsxDP(2).BallYSpeed < 0)) then
              BallsxDN(2).BallYSpeed <= - BallsxDP(2).BallYSpeed;
            end if;
      
            -- check collisions with plate
            if(BallsxDP(2).BallY >= (VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT)) then
              if((PlateRight2xDP > 0) and (PlateLeft2xDP < PLATE_WIDTH)) then 
                if(BallsxDP(2).BallYSpeed >= 0) then
                  HighscorexDN <= HighscorexDP + 1;
                  
                  BallsxDN(2).BallYSpeed <= - BallsxDP(2).BallYSpeed;
                  BallsxDN(2).BallXSpeed <= to_signed(-1, 2) when PlateRight2xDP < (PLATE_WIDTH / 3)
                                                             else to_signed(0, 2) when PlateRight2xDP < ((2*PLATE_WIDTH)/ 3) 
                                                             else to_signed(1, 2);                    
                end if;
              else
                FsmStatexDN <= GameEnd;
              end if;
          end if;

          BallsxDN(2).BallX <= resize(unsigned(signed(resize(BallsxDP(2).BallX, COORD_BW + 1)) + resize(BallsxDP(2).BallXSpeed, COORD_BW + 1) * to_signed(BALL_STEP_X, COORD_BW + 1)), COORD_BW);
          BallsxDN(2).BallY <= resize(unsigned(signed(resize(BallsxDP(2).BallY, COORD_BW + 1)) + resize(BallsxDP(2).BallYSPeed, COORD_BW + 1) * to_signed(BALL_STEP_Y, COORD_BW + 1)), COORD_BW);
              
          PlateLeft2xDN <= resize(signed(resize(BallsxDN(2).BallX, COORD_BW + 1)) - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
          PlateRight2xDN <= resize(signed(resize(BallsxDN(2).BallX, COORD_BW + 1)) + BALL_WIDTH - signed(resize(PlateXxDP, COORD_BW + 1)), COORD_BW);
        end if;

      -- -- Incase other cases appear, reset game
      -- WHEN OTHERS =>
      --  FsmStatexDN     <= GameEnd;
      --  PlateXxDN       <= PLATE_X_INIT;
      --  ActiveBallsxDN  <= to_unsigned(1,1);
      --  HighscorexDN    <= to_unsigned(0,1);

      --  BallsxDN <= (OTHERS => (
      --    BallX      => BALL_X_INIT,
      --    BallY      => BALL_Y_INIT,
      --    BallXSpeed => to_signed(0, 2),
      --    BallYSpeed => to_signed(0, 2)
      --  ));
    
    END CASE;

  END PROCESS;

  FsmStatexDO <= FsmStatexDP;
  PlateXxDO <= PlateXxDP;
  BallsxDO <= BallsxDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
