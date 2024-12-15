--=============================================================================
-- @file pong_fsm_tb.vhdl
--=============================================================================
-- Standard library
LIBRARY ieee;
LIBRARY std;
USE std.env.ALL;
-- Standard packages
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
-- Packages
LIBRARY work;
USE work.dsd_prj_pkg.ALL;


ENTITY pong_fsm_tb IS
  
END ENTITY pong_fsm_tb;

ARCHITECTURE tb OF pong_fsm_tb IS

  --=============================================================================
-- TYPE AND CONSTANT DECLARATIONS
--=============================================================================
  constant CLK_HIGH   : time := 6.66ns;
  constant CLK_LOW    : time := 6.66ns;
  constant CLK_PERIOD : time := CLK_LOW + CLK_HIGH;
  constant CLK_STIM   : time := 1ns; -- Used to push us a little bit after the clock edge

--=============================================================================
-- SIGNAL DECLARATIONS
--=============================================================================

  SIGNAL CLKxCI    : std_logic := '0';
  SIGNAL RSTxRI    : std_logic := '0';
  SIGNAL LeftxSI   : std_logic;
  SIGNAL RightxSI  : std_logic;
  SIGNAL VgaXxDI   : unsigned(COORD_BW - 1 DOWNTO 0);
  SIGNAL VgaYxDI   : unsigned(COORD_BW - 1 DOWNTO 0);
  SIGNAL VSYNCxSI  : std_logic := '1';
  SIGNAL BallXxDO  : unsigned(COORD_BW - 1 DOWNTO 0);
  SIGNAL BallYxDO  : unsigned(COORD_BW - 1 DOWNTO 0);
  SIGNAL PlateXxDO : unsigned(COORD_BW - 1 DOWNTO 0);
  

  COMPONENT pong_fsm IS
    PORT (
      CLKxCI    : IN  std_logic;
      RSTxRI    : IN  std_logic;
      LeftxSI   : IN  std_logic;
      RightxSI  : IN  std_logic;
      VgaXxDI   : IN  unsigned(COORD_BW - 1 DOWNTO 0);
      VgaYxDI   : IN  unsigned(COORD_BW - 1 DOWNTO 0);
      VSYNCxSI  : IN  std_logic;
      BallXxDO  : OUT unsigned(COORD_BW - 1 DOWNTO 0);
      BallYxDO  : OUT unsigned(COORD_BW - 1 DOWNTO 0);
      PlateXxDO : OUT unsigned(COORD_BW - 1 DOWNTO 0));
  END COMPONENT pong_fsm;

  
BEGIN  -- ARCHITECTURE tb

  pong_fsm_1: ENTITY work.pong_fsm
    PORT MAP (
      CLKxCI    => CLKxCI,
      RSTxRI    => RSTxRI,
      LeftxSI   => LeftxSI,
      RightxSI  => RightxSI,
      VgaXxDI   => VgaXxDI,
      VgaYxDI   => VgaYxDI,
      VSYNCxSI  => VSYNCxSI,
      BallXxDO  => BallXxDO,
      BallYxDO  => BallYxDO,
      PlateXxDO => PlateXxDO);

  --=============================================================================
-- CLOCK PROCESS
-- Process for generating the clock signal
--=============================================================================
  p_CLK: process is
  begin
    CLKxCI <= '0';
    wait for CLK_LOW;
    CLKxCI <= '1';
    wait for CLK_HIGH;
  end process p_CLK;

  --=============================================================================
-- VSYNC PROCESS
-- Process for generating the vsync signal
--=============================================================================
  p_vs: process is
  begin
    VSYNCxSI <= '0';
    --wait for CLK_LOW * (HS_DISPLAY * VS_DISPLAY);
    wait for CLK_LOW * 200;
    VSYNCxSI <= '1';
    wait for CLK_HIGH;
  end process p_vs;

--=============================================================================
-- RESET PROCESS
-- Process for generating initial reset
--=============================================================================
  p_RST: process is
  begin
    RSTxRI <= '1';
    wait until CLKxCI'event and CLKxCI = '1'; -- Align to clock
    wait for (2*CLK_PERIOD + CLK_STIM);
    RSTxRI <= '0';
    wait;
  end process p_RST;

  --=============================================================================
-- TEST PROCESSS
--=============================================================================

  p_STIM: PROCESS IS
  BEGIN  -- PROCESS p_STIM
    LeftxSI <= '0';
    RightxSI <= '0';
    
    wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;
    report "Test 1" severity note;
    LeftxSI <= '1';
    RightxSI <= '1';


    wait until VSYNCxSI'event and VSYNCxSI = '1';
    wait until VSYNCxSI'event and VSYNCxSI = '1';

    LeftxSI <= '0';
    RightxSI <= '0';
    
    wait until CLKxCI'event and CLKxCI = '1';
    
    RightxSI <= '1';
    
    WAIT;

  END PROCESS p_STIM;

  

END ARCHITECTURE tb;
