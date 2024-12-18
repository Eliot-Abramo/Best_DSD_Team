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

    -- FSM, ball and plate
    FsmStatexDI: in GameControl;
    PlateXxDI : in unsigned(COORD_BW - 1 downto 0);
    BallsxDI : in BallArrayType;

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
  constant SPRITE_WIDTH       : natural := 200;
  constant SPRITE_MEM_ADDR_BW  : natural := 17;

  -- Index map
  constant SPRITE_PLATE_INDEX : natural := 64 * SPRITE_WIDTH + 512;

  -- Fixed positions
  constant TEXT_WIDTH  : natural := 512;
  constant TEXT_HEIGHT : natural := 128;
  constant TEXT_POS_X  : natural := HS_DISPLAY/2 - TEXT_WIDTH/2;
  constant TEXT_POS_Y  : natural := VS_DISPLAY/4;

  -- Signals (TODO: remove signed)
  signal PlateRelativeXxD : signed(COORD_BW downto 0) := (others => '0');
  signal PlateRelativeYxD : signed(COORD_BW downto 0) := (others => '0');

  signal PlateMemRelativeXxD : unsigned(SPRITE_MEM_ADDR_BW - 1 downto 0) := (others => '0');
  signal PlateMemRelativeYxD : unsigned(SPRITE_MEM_ADDR_BW - 1 downto 0) := (others => '0');

  -- Memory ROM

  signal ENxS   : std_logic;
  signal DOUTxD : std_logic_vector(MEM_DATA_BW - 1 downto 0);
  signal RdAddrxD : std_logic_vector(SPRITE_MEM_ADDR_BW - 1 DOWNTO 0);

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
  port map(
    clka => CLKxCI,
    ena => ENxS,
    addra => RdAddrxD,
    douta => DOUTxD
  );
  --=========================================================================
  -- Precalculated signals
  --=========================================================================
  MemRedxS   <= DOUTxD(3 * COLOR_BW - 1 downto 2 * COLOR_BW);
  MemGreenxS <= DOUTxD(2 * COLOR_BW - 1 downto 1 * COLOR_BW);
  MemBluexS  <= DOUTxD(1 * COLOR_BW - 1 downto 0 * COLOR_BW);

  PlateRelativeXxD    <= signed(resize(XCoordxDI, COORD_BW + 1)) - signed(resize(PlateXxDI, COORD_BW + 1));
  PlateRelativeYxD    <= signed(resize(YCoordxDI, COORD_BW + 1)) - (VS_DISPLAY - PLATE_HEIGHT);
  PlateMemRelativeXxD <= resize(unsigned(PlateRelativeXxD), SPRITE_MEM_ADDR_BW);
  PlateMemRelativeYxD <= resize(unsigned(PlateRelativeYxD), SPRITE_MEM_ADDR_BW);

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

    -- Plate
    if ((PlateRelativeXxD >= 0 and PlateRelativeXxD < PLATE_WIDTH) and (PlateRelativeYxD >= 0)) then
      RdAddrxD <= std_logic_vector(resize(SPRITE_PLATE_INDEX + PlateMemRelativeXxD + PlateMemRelativeYxD * SPRITE_WIDTH, SPRITE_MEM_ADDR_BW));
      RedxSO   <= MemRedxS;
      GreenxSO <= MemGreenxS;
      BluexSO  <= MemBluexS;
    end if;

    -- Ball logic 
    FOR i IN 0 TO (MaxBallCount - 1) LOOP
      IF (BallsxDI(i).IsActive = 1) THEN
          IF (XCoordxDI >= BallsxDI(i).BallX AND XCoordxDI < BallsxDI(i).BallX + BALL_WIDTH AND
              YCoordxDI >= BallsxDI(i).BallY AND YCoordxDI < BallsxDI(i).BallY + BALL_HEIGHT) THEN
            RedxSO   <= "1111";
            GreenxSO <= "1111";
            BluexSO  <= "1111";
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