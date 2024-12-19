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
  constant SPRITE_ATLAS_WIDTH       : natural := 768;
  constant SPRITE_ATLAS_MEM_ADDR_BW : natural := 17;

  -- Index map
  constant SPRITE_BALL_INDEX  : natural := 512;
  constant SPRITE_PLATE_INDEX : natural := 64 * SPRITE_ATLAS_WIDTH + 512;

  -- Signals (TODO: remove signed)
  signal BallRelativeXxD : signed(COORD_BW downto 0) := (others => '0');
  signal BallRelativeYxD : signed(COORD_BW downto 0) := (others => '0');

  signal BallMemRelativeXxD : unsigned(SPRITE_ATLAS_MEM_ADDR_BW - 1 downto 0) := (others => '0');
  signal BallMemRelativeYxD : unsigned(SPRITE_ATLAS_MEM_ADDR_BW - 1 downto 0) := (others => '0');

 signal PlateRelativeXxD : signed(COORD_BW downto 0) := (others => '0');
 signal PlateRelativeYxD : signed(COORD_BW downto 0) := (others => '0');

  signal PlateMemRelativeXxD : unsigned(SPRITE_ATLAS_MEM_ADDR_BW - 1 downto 0) := (others => '0');
  signal PlateMemRelativeYxD : unsigned(SPRITE_ATLAS_MEM_ADDR_BW - 1 downto 0) := (others => '0');

  -- Memory ROM
  signal RdAddrxD : std_logic_vector(SPRITE_ATLAS_MEM_ADDR_BW - 1 downto 0);

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
  i_bkl_mem_gen_1 : blk_mem_gen_1
  port map
  (
    clka  => CLKxCI,
    ena   => ENxS,
    addra => RdAddrxD,
    douta => DOUTxD
  );

  --=========================================================================
  -- Precalculated signals
  --=========================================================================
  BallRelativeXxD    <= signed(resize(XCoordxDI, COORD_BW + 1)) - signed(resize(BallsxDI(0).BallX, COORD_BW + 1));
  BallRelativeYxD    <= signed(resize(YCoordxDI, COORD_BW + 1)) - signed(resize(BallsxDI(0).BallY, COORD_BW + 1));
  BallMemRelativeXxD <= resize(unsigned(BallRelativeXxD), SPRITE_ATLAS_MEM_ADDR_BW);
  BallMemRelativeYxD <= resize(unsigned(BallRelativeYxD), SPRITE_ATLAS_MEM_ADDR_BW);

  PlateRelativeXxD    <= signed(resize(XCoordxDI, COORD_BW + 1)) - signed(resize(PlateXxDI, COORD_BW + 1));
  PlateRelativeYxD    <= signed(resize(YCoordxDI, COORD_BW + 1)) - (VS_DISPLAY - PLATE_HEIGHT);
  PlateMemRelativeXxD <= resize(unsigned(PlateRelativeXxD), SPRITE_ATLAS_MEM_ADDR_BW);
  PlateMemRelativeYxD <= resize(unsigned(PlateRelativeYxD), SPRITE_ATLAS_MEM_ADDR_BW);

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
    RdAddrxD <= (others => '0');

    RedxSO   <= BGRedxSI;
    GreenxSO <= BGGreenxSI;
    BluexSO  <= BGBluexSI;

    -- TODO optmize since the code is always the same
    -- Plate
    if ((PlateRelativeXxD >= 0 and PlateRelativeXxD < PLATE_WIDTH) and (PlateRelativeYxD >= 0)) then
      RdAddrxD <= std_logic_vector(resize(SPRITE_PLATE_INDEX + PlateMemRelativeXxD + PlateMemRelativeYxD * SPRITE_ATLAS_WIDTH, SPRITE_ATLAS_MEM_ADDR_BW));
      RedxSO   <= MemRedxS;
      GreenxSO <= MemGreenxS;
      BluexSO  <= MemBluexS;
    end if;

    -- Ball
    if ((BallRelativeXxD >= 0 and BallRelativeXxD < BALL_WIDTH) and (BallRelativeYxD >= 0 and BallRelativeYxD < BALL_HEIGHT)) then
      if (BallsxDI(0).BallYSpeed > 0) then
        RdAddrxD <= std_logic_vector(resize(SPRITE_BALL_INDEX + BallMemRelativeXxD + BallMemRelativeYxD * SPRITE_ATLAS_WIDTH, SPRITE_ATLAS_MEM_ADDR_BW));
      else
        RdAddrxD <= std_logic_vector(resize(SPRITE_BALL_INDEX + BallMemRelativeXxD + (BALL_HEIGHT - BallMemRelativeYxD) * SPRITE_ATLAS_WIDTH, SPRITE_ATLAS_MEM_ADDR_BW));
      end if;
      RedxSO   <= MemRedxS;
      GreenxSO <= MemGreenxS;
      BluexSO  <= MemBluexS;
    end if;

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