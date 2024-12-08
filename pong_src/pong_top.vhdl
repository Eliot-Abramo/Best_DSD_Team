--=============================================================================
-- @file pong_top.vhdl
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
-- pong_top
--
-- @brief This file specifies the toplevel of the pong game with bacground from
-- an image. For lab 7.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR PONG_TOP
--=============================================================================
entity pong_top is
  port (
    CLK125xCI : in std_logic;
    RSTxRI    : in std_logic;

    -- Button inputs
    LeftxSI  : in std_logic;
    RightxSI : in std_logic;

    -- Timing outputs
    HSxSO : out std_logic;
    VSxSO : out std_logic;

    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end pong_top;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_top is

--=============================================================================
-- SIGNAL (COMBINATIONAL) DECLARATIONS
--=============================================================================;

  -- clk_wiz_0
  signal CLK75xC : std_logic;

  -- blk_mem_gen_0
  signal WrAddrAxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal RdAddrBxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal ENAxS     : std_logic;
  signal WEAxS     : std_logic_vector(0 downto 0);
  signal ENBxS     : std_logic;
  signal DINAxD    : std_logic_vector(MEM_DATA_BW - 1 downto 0);
  signal DOUTBxD   : std_logic_vector(MEM_DATA_BW - 1 downto 0);

  signal BGRedxS   : std_logic_vector(COLOR_BW - 1 downto 0); -- Background colors from the memory
  signal BGGreenxS : std_logic_vector(COLOR_BW - 1 downto 0);
  signal BGBluexS  : std_logic_vector(COLOR_BW - 1 downto 0);

  -- vga_controller
  signal RedxS   : std_logic_vector(COLOR_BW - 1 downto 0); -- Color to VGA controller
  signal GreenxS : std_logic_vector(COLOR_BW - 1 downto 0);
  signal BluexS  : std_logic_vector(COLOR_BW - 1 downto 0);

  signal XCoordxD : unsigned(COORD_BW - 1 downto 0); -- Coordinates from VGA controller
  signal YCoordxD : unsigned(COORD_BW - 1 downto 0);

  signal VSEdgexS : std_logic; -- If 1, row counter resets (new frame). HIGH for 1 CC, when vertical sync starts)

  -- pong_fsm
--  signal BallXxD  : unsigned(COORD_BW - 1 downto 0); -- Coordinates of ball and plate
--  signal BallYxD  : unsigned(COORD_BW - 1 downto 0);
  signal BallsxD : BallArrayType;
  signal ActiveBallsxD : natural;
  signal PlateXxD : unsigned(COORD_BW - 1 downto 0);

  -- TODO:
  signal DrawBallxS  : std_logic; -- If 1, draw the ball
  signal DrawPlatexS : std_logic; -- If 1, draw the plate

--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
  component clk_wiz_0 is
    port (
      clk_out1 : out std_logic;
      reset    : in  std_logic;
      locked   : out std_logic;
      clk_in1  : in  std_logic
    );
  end component clk_wiz_0;

  component blk_mem_gen_0
    port (
      clka  : in std_logic;
      ena   : in std_logic;
      wea   : in std_logic_vector(0 downto 0);
      addra : in std_logic_vector(15 downto 0);
      dina  : in std_logic_vector(11 downto 0);

      clkb  : in std_logic;
      enb   : in std_logic;
      addrb : in std_logic_vector(15 downto 0);
      doutb : out std_logic_vector(11 downto 0)
    );
  end component;

  component vga_controller is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      -- Data/color input
      RedxSI   : in std_logic_vector(COLOR_BW - 1 downto 0);
      GreenxSI : in std_logic_vector(COLOR_BW - 1 downto 0);
      BluexSI  : in std_logic_vector(COLOR_BW - 1 downto 0);

      -- Coordinate output
      XCoordxDO : out unsigned(COORD_BW - 1 downto 0);
      YCoordxDO : out unsigned(COORD_BW - 1 downto 0);

      -- Timing output
      HSxSO : out std_logic;
      VSxSO : out std_logic;

      VSEdgexSO : out std_logic;

      -- Data/color output
      RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
      GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
      BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
    );
  end component vga_controller;

  component pong_fsm is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      -- Controls from push buttons
      LeftxSI  : in std_logic;
      RightxSI : in std_logic;

      -- Coordinate from VGA
      VgaXxDI : in unsigned(COORD_BW - 1 downto 0);
      VgaYxDI : in unsigned(COORD_BW - 1 downto 0);

      -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
      VSEdgexSI : in std_logic;

      -- Ball and plate coordinates
--      BallXxDO  : out unsigned(COORD_BW - 1 downto 0);
--      BallYxDO  : out unsigned(COORD_BW - 1 downto 0);
      BallsxDO : out BallArrayType;
      ActiveBallsxDO : out natural;
      PlateXxDO : out unsigned(COORD_BW - 1 downto 0)
    );
  end component pong_fsm;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- COMPONENT INSTANTIATIONS
--=============================================================================
  i_clk_wiz_0 : clk_wiz_0
    port map (
      clk_out1 => CLK75xC,
      reset    => RSTxRI,
      locked   => open,
      clk_in1  => CLK125xCI
    );

  i_blk_mem_gen_0 : blk_mem_gen_0
    port map (
      clka  => CLK75xC,
      ena   => ENAxS,
      wea   => WEAxS,
      addra => WrAddrAxD,
      dina  => DINAxD,

      clkb  => CLK75xC,
      enb   => ENBxS,
      addrb => RdAddrBxD,
      doutb => DOUTBxD
    );

  i_vga_controller: vga_controller
    port map (
      CLKxCI => CLK75xC,
      RSTxRI => RSTxRI,

      RedxSI   => RedxS,
      GreenxSI => GreenxS,
      BluexSI  => BluexS,

      HSxSO => HSxSO,
      VSxSO => VSxSO,

      VSEdgexSO => VSEdgexS,

      XCoordxDO => XCoordxD,
      YCoordxDO => YCoordxD,

      RedxSO   => RedxSO,
      GreenxSO => GreenxSO,
      BluexSO  => BluexSO
    );

  i_pong_fsm : pong_fsm
    port map (
      CLKxCI => CLK75xC,
      RSTxRI => RSTxRI,

      RightxSI => RightxSI,
      LeftxSI  => LeftxSI,

      VgaXxDI => XCoordxD,
      VgaYxDI => YCoordxD,

      VSEdgexSI => VSEdgexS,

--      BallXxDO  => BallXxD,
--      BallYxDO  => BallYxD,
      BallsxDO => BallsxD,
      ActiveBallsxDO => ActiveBallsxD,

      PlateXxDO => PlateXxD
    );

--=============================================================================
-- MEMORY SIGNAL MAPPING
--=============================================================================

  -- Port A
  ENAxS     <= '0';
  WEAxS     <= "0";
  WrAddrAxD <= (others => '0');
  DINAxD    <= (others => '0');

  -- Port B
  ENBxS     <= '1';
  -- We "divide" by a factor of  4 to account for the bigger size of the screen coordinates and then multiply y for 256 pixels in a row
  -- TODO: optmize
  RdAddrBxD <= std_logic_vector(resize(YCoordxD / 4 * 256 + XCoordxD / 4, 16));

  BGRedxS   <= DOUTBxD(3 * COLOR_BW - 1 downto 2 * COLOR_BW);
  BGGreenxS <= DOUTBxD(2 * COLOR_BW - 1 downto 1 * COLOR_BW);
  BGBluexS  <= DOUTBxD(1 * COLOR_BW - 1 downto 0 * COLOR_BW);


--=============================================================================
-- Sprite logic
--=============================================================================
process(all)
begin
  -- Default
  RedxS <= BGRedxS;
  GreenxS <= BGGreenxS;
  BluexS <= BGBluexS;
  -- Plate
  if (XCoordxD >= PlateXxD and XCoordxD < PlateXxD + PLATE_WIDTH and YCoordxD >= VS_DISPLAY - PLATE_HEIGHT) then
    RedxS   <= "1111";
    GreenxS <= "1111";
    BluexS  <= "1111";
  end if;

  -- Ball
  FOR i IN 0 TO (MaxBallCount)-1 LOOP
    if(i<ActiveBallsxD) then
        if (XCoordxD >= BallsxD(i).BallX and XCoordxD < BallsxD(i).BallX + BALL_WIDTH and YCoordxD >= BallsxD(i).BallY and YCoordxD < BallsxD(i).BallY + BALL_HEIGHT) then
            RedxS   <= "1111";
            GreenxS <= "1111";
            BluexS  <= "1111";
        end if;
     end if;
  end loop;
end process;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
