--=============================================================================
-- @file sprite_manager.vhdl
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
-- sprite_manager
--
-- @brief This file specifies a basic circuit for the sprite manager
--
--=============================================================================
--=============================================================================
-- ENTITY DECLARATION FOR SPRITE_MANAGER
--=============================================================================

entity sprite_manager is
  port
  (
    CLKxCI : in std_logic;

    -- Coordinate from VGA
    XCoordxDI : in unsigned(COORD_BW - 1 downto 0);
    YCoordxDI : in unsigned(COORD_BW - 1 downto 0);

    -- Background colors from the memory (to handle transparency)
    BGRedxSI   : in std_logic_vector(COLOR_BW - 1 downto 0);
    BGGreenxSI : in std_logic_vector(COLOR_BW - 1 downto 0);
    BGBluexSI  : in std_logic_vector(COLOR_BW - 1 downto 0);

    -- Ball and plate coordinates
    BallsxDI : in BallArrayType;
    PlateXxDI : in unsigned(COORD_BW - 1 downto 0);
    -- Highscore and state

    -- Current output colors
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end entity;
--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================

architecture rtl of sprite_manager is
  --=============================================================================
  -- ARCHITECTURE BEGIN
  --=============================================================================

  -- Constants

  -- Index map

  -- Fixed positions
  constant TEXT_WIDTH  : natural := 512;
  constant TEXT_HEIGHT : natural := 128;
  constant TEXT_POS_X  : natural := HS_DISPLAY/2 - TEXT_WIDTH/2;
  constant TEXT_POS_Y  : natural := VS_DISPLAY/4;

  -- Signals (TODO: remove signed)

  -- Memory ROM

  signal ENxS   : std_logic;
  signal DOUTxD : std_logic_vector(MEM_DATA_BW - 1 downto 0);

  signal MemRedxS   : std_logic_vector(COLOR_BW - 1 downto 0);
  signal MemGreenxS : std_logic_vector(COLOR_BW - 1 downto 0);
  signal MemBluexS  : std_logic_vector(COLOR_BW - 1 downto 0);

  --=============================================================================
  -- COMPONENT DECLARATIONS
  --=============================================================================
  component blk_mem_gen_1
    port
    (
      clka  : in std_logic;
      ena   : in std_logic;
      addra : in std_logic_vector(16 downto 0);
      douta : out std_logic_vector(11 downto 0)
    );
  end component;

begin
  --=============================================================================
  -- COMPONENT INSTANTIATIONS
  --=============================================================================
  --=========================================================================
  -- Precalculated signals
  --=========================================================================
  MemRedxS   <= DOUTxD(3 * COLOR_BW - 1 downto 2 * COLOR_BW);
  MemGreenxS <= DOUTxD(2 * COLOR_BW - 1 downto 1 * COLOR_BW);
  MemBluexS  <= DOUTxD(1 * COLOR_BW - 1 downto 0 * COLOR_BW);

  --=============================================================================
  -- Sprite logic
  --=============================================================================
  process (all)
  begin
    -- Default
    EnxS     <= '1';

    RedxSO   <= BGRedxSI;
    GreenxSO <= BGGreenxSI;
    BluexSO  <= BGBluexSI;

     -- Plate logic
    IF (XCoordxDI >= PlateXxDI AND XCoordxDI < PlateXxDI + PLATE_WIDTH AND YCoordxDI >= VS_DISPLAY - PLATE_HEIGHT) THEN
      RedxSO   <= BGRedxSI;
      GreenxSO <= BGGreenxSI;
      BluexSO  <= BGBluexSI;
    END IF;

    -- Ball logic 
    FOR i IN 0 TO (MaxBallCount - 1) LOOP
      IF (BallsxDI(i).IsActive = 1) THEN
          IF (XCoordxDI >= BallsxDI(i).BallX AND XCoordxDI < BallsxDI(i).BallX + BALL_WIDTH AND
              YCoordxDI >= BallsxDI(i).BallY AND YCoordxDI < BallsxDI(i).BallY + BALL_HEIGHT) THEN
            RedxSO   <= BGRedxSI;
            GreenxSO <= BGGreenxSI;
            BluexSO  <= BGBluexSI;
        END IF;
     END IF;
    END LOOP;
    -- Text (only if stopped)

    -- Transparent background (if black then simply draw the background)
    if (DOUTxD = "000000000000") then
      RedxSO   <= BGRedxSI;
      GreenxSO <= BGGreenxSI;
      BluexSO  <= BGBluexSI;
    end if;

  end process;
  
end architecture;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================