--=============================================================================
-- @file mandelbrot_top.vhdl
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
-- mandelbrot_top
--
-- @brief This file specifies the toplevel of the pong game with the Mandelbrot
-- to generate the background for lab 8, the final lab.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR MANDELBROT_TOP
--=============================================================================
entity mandelbrot_top is
  port
  (
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
end mandelbrot_top;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of mandelbrot_top is

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
  signal BallsxD : BallArrayType;
  signal PlateXxD : unsigned(COORD_BW - 1 downto 0);

  -- mandelbrot
  signal MandelbrotWExS   : std_logic; -- If 1, Mandelbrot writes
  signal MandelbrotXxD    : unsigned(COORD_BW - 1 downto 0);
  signal MandelbrotYxD    : unsigned(COORD_BW - 1 downto 0);
  signal MandelbrotITERxD : unsigned(MEM_DATA_BW - 1 downto 0); -- Iteration number from Mandelbrot (chooses colour)

  --=============================================================================
  -- COMPONENT DECLARATIONS
  --=============================================================================
  component clk_wiz_0 is
    port
    (
      clk_out1 : out std_logic;
      reset    : in std_logic;
      locked   : out std_logic;
      clk_in1  : in std_logic
    );
  end component clk_wiz_0;

  component blk_mem_gen_0
    port
    (
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
    port
    (
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
    port
    (
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
      PlateXxDO : out unsigned(COORD_BW - 1 downto 0);
      BallsxDO : out BallArrayType
    );
  end component pong_fsm;

  component mandelbrot is
    port
    (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      WExSO   : out std_logic;
      XxDO    : out unsigned(COORD_BW - 1 downto 0);
      YxDO    : out unsigned(COORD_BW - 1 downto 0);
      ITERxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
    );
  end component mandelbrot;
  
--  component sprite_manager is
--     port
--     (
--       CLKxCI : in std_logic;

--       -- Coordinate from VGA
--       XCoordxDI : in unsigned(COORD_BW - 1 downto 0);
--       YCoordxDI : in unsigned(COORD_BW - 1 downto 0);

--       -- Background colors from the memory (to handle transparency)
--       BGRedxSI   : in std_logic_vector(COLOR_BW - 1 downto 0);
--       BGGreenxSI : in std_logic_vector(COLOR_BW - 1 downto 0);
--       BGBluexSI  : in std_logic_vector(COLOR_BW - 1 downto 0);

--       -- Ball and plate coordinates
--       BallsxDI : in BallArrayType;
--       PlateXxDI : in unsigned(COORD_BW - 1 downto 0);


--       -- Current output colors
--       RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
--       GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
--       BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
--     );
--   end component;

  --=============================================================================
  -- ARCHITECTURE BEGIN
  --=============================================================================
begin

  --=============================================================================
  -- COMPONENT INSTANTIATIONS
  --=============================================================================
  i_clk_wiz_0 : clk_wiz_0
  port map
  (
    clk_out1 => CLK75xC,
    reset    => RSTxRI,
    locked   => open,
    clk_in1  => CLK125xCI
  );

  i_blk_mem_gen_0 : blk_mem_gen_0
  port
  map (
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

  i_vga_controller : vga_controller
  port
  map (
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
  port
  map (
  CLKxCI => CLK75xC,
  RSTxRI => RSTxRI,

  RightxSI => RightxSI,
  LeftxSI  => LeftxSI,

  VgaXxDI => XCoordxD,
  VgaYxDI => YCoordxD,

  VSEdgexSI => VSEdgexS,

  PlateXxDO => PlateXxD,
  BallsxDO => BallsxD
  );

  i_mandelbrot : mandelbrot
  port
  map (
  CLKxCI => CLK75xC,
  RSTxRI => RSTxRI,

  WExSO   => MandelbrotWExS,
  XxDO    => MandelbrotXxD,
  YxDO    => MandelbrotYxD,
  ITERxDO => MandelbrotITERxD
  );

  -- i_sprite_manager : sprite_manager
  -- port
  -- map (
  -- CLKxCI => CLK75xC,

  -- XCoordxDI => XCoordxD,
  -- YCoordxDI => YCoordxD,

  -- BGRedxSI   => BGRedxS,
  -- BGGreenxSI => BGGreenxS,
  -- BGBluexSI  => BGBluexS,
  
  -- BallsxDI => BallsxD,
  -- PlateXxDI => PlateXxD,
  
  -- -- Current output colors
  -- RedxSO   => RedxS,
  -- GreenxSO => GreenxS,
  -- BluexSO  => BluexS
  -- );

  --=============================================================================
  -- MEMORY SIGNAL MAPPING
  --=============================================================================
  -- Port A
  ENAxS     <= MandelbrotWExS;
  WEAxS     <= (others => MandelbrotWExS);
  -- WrAddrAxD <= std_logic_vector(MandelbrotYxD(9 DOWNTO 2) & MandelbrotXxD(9 DOWNTO 2));
  WrAddrAxD <= std_logic_vector(resize(MandelbrotYxD / 4 * 256 + MandelbrotXxD / 4, 16));
  -- DINAxD    <= std_logic_vector(shift_left(MandelbrotITERxD, 9));
  DINAxD    <= std_logic_vector(MandelbrotITERxD);

  -- Port B
  ENBxS     <= '1';
  -- RdAddrBxD <= std_logic_vector(YCoordxD(9 DOWNTO 2) & XCoordxD(9 DOWNTO 2)); -- Map the X and Y coordinates to the address of the memory
  RdAddrBxD <= std_logic_vector(resize(YCoordxD / 4 * 256 + XCoordxD / 4, 16));

  BGRedxS   <= DOUTBxD(3 * COLOR_BW - 1 DOWNTO 2 * COLOR_BW);
  BGGreenxS <= DOUTBxD(2 * COLOR_BW - 1 DOWNTO 1 * COLOR_BW);
  BGBluexS  <= DOUTBxD(1 * COLOR_BW - 1 DOWNTO 0 * COLOR_BW);

--=============================================================================
-- SPRITE SIGNAL MAPPING
--=============================================================================

-- RedxS <= BALL_RGB(12-1 downto 8) WHEN (XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
--                                       AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
--                                       AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
--                                       AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length))

--         ELSE PLATE_RGB(12-1 downto 8) WHEN (YCoordxD > to_unsigned(VS_DISPLAY - PLATE_HEIGHT, YCoordxD'length)
--                                       AND XCoordxD >= (PlateXxD)
--                                       AND XCoordxD <= (PlateXxD + PLATE_WIDTH)) 
--         ELSE BGRedxS;
       
-- GreenxS <= BALL_RGB(8-1 downto 4)    WHEN (XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
--                                           AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
--                                           AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
--                                           AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)) 

--         ELSE PLATE_RGB(8-1 downto 4) WHEN (YCoordxD > to_unsigned(VS_DISPLAY - PLATE_HEIGHT, YCoordxD'length)
--                                           AND XCoordxD >= (PlateXxD)
--                                           AND XCoordxD <= (PlateXxD + PLATE_WIDTH)) 
--         ELSE BGGreenxS;
  
-- BluexS <= BALL_RGB(4-1 downto 0)    WHEN (XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
--                                           AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
--                                           AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
--                                           AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)) 
                                          
--         ELSE PLATE_RGB(4-1 downto 0) WHEN (YCoordxD > to_unsigned(VS_DISPLAY - PLATE_HEIGHT, YCoordxD'length)
--                                           AND XCoordxD >= (PlateXxD)
--                                           AND XCoordxD <= (PlateXxD + PLATE_WIDTH)) 
--         ELSE BGBluexS;

process(all)
begin

      RedxS <= PLATE_RGB(12-1 downto 8) WHEN (YCoordxD > to_unsigned(VS_DISPLAY - PLATE_HEIGHT, YCoordxD'length)
                                      AND XCoordxD >= (PlateXxD)
                                      AND XCoordxD <= (PlateXxD + PLATE_WIDTH))
        ELSE BGRedxS;
       
    GreenxS <= PLATE_RGB(8-1 downto 4) WHEN (YCoordxD > to_unsigned(VS_DISPLAY - PLATE_HEIGHT, YCoordxD'length)
                                          AND XCoordxD >= (PlateXxD)
                                          AND XCoordxD <= (PlateXxD + PLATE_WIDTH))
        ELSE BGGreenxS;
  
    BluexS <= PLATE_RGB(4-1 downto 0) WHEN (YCoordxD > to_unsigned(VS_DISPLAY - PLATE_HEIGHT, YCoordxD'length)
                                          AND XCoordxD >= (PlateXxD)
                                          AND XCoordxD <= (PlateXxD + PLATE_WIDTH))
        ELSE BGBluexS;

  
  if(BallsxD(0).IsActive = 1 and BallsxD(1).IsActive = 0 and BallsxD(2).IsActive = 0) then
    RedxS <= BALL_RGB(12-1 downto 8) WHEN (XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                      AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                      AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
                                      AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length));
       
    GreenxS <= BALL_RGB(8-1 downto 4)    WHEN (XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
                                          AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length));
  
    BluexS <= BALL_RGB(4-1 downto 0)    WHEN (XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
                                          AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length));

  elsif(BallsxD(0).IsActive = 1 and BallsxD(1).IsActive = 1 and BallsxD(2).IsActive = 0) then
    RedxS <= BALL_RGB(12-1 downto 8) WHEN ((XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                      AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                      AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
                                      AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)) 
                                      OR
                                      (XCoordxD > BallsxD(1).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                      AND XCoordxD < BallsxD(1).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                      AND YCoordxD > BallsxD(1).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length)
                                      AND YCoordxD < BallsxD(1).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length)));
       
    GreenxS <= BALL_RGB(8-1 downto 4)    WHEN((XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
                                          AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length))
                                          OR
                                          (XCoordxD > BallsxD(1).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                          AND XCoordxD < BallsxD(1).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                          AND YCoordxD > BallsxD(1).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length)
                                          AND YCoordxD < BallsxD(1).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length)));
  
    BluexS <= BALL_RGB(4-1 downto 0)    WHEN((XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
                                          AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length))
                                          OR
                                          (XCoordxD > BallsxD(1).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                          AND XCoordxD < BallsxD(1).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                          AND YCoordxD > BallsxD(1).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length)
                                          AND YCoordxD < BallsxD(1).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length)));                                        

  elsif(BallsxD(0).IsActive = 1 and BallsxD(1).IsActive = 1 and BallsxD(2).IsActive = 1) then
    RedxS <= BALL_RGB(12-1 downto 8) WHEN ((XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                      AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                      AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
                                      AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)) 
                                      OR
                                      (XCoordxD > BallsxD(1).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                      AND XCoordxD < BallsxD(1).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                      AND YCoordxD > BallsxD(1).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length)
                                      AND YCoordxD < BallsxD(1).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length))
                                      OR
                                      (XCoordxD > BallsxD(2).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(2).BallX'length)
                                      AND XCoordxD < BallsxD(2).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(2).BallX'length)
                                      AND YCoordxD > BallsxD(2).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(2).BallY'length)
                                      AND YCoordxD < BallsxD(2).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(2).BallY'length)));
       
    GreenxS <= BALL_RGB(8-1 downto 4)    WHEN((XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
                                          AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length))
                                          OR
                                          (XCoordxD > BallsxD(1).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                          AND XCoordxD < BallsxD(1).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                          AND YCoordxD > BallsxD(1).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length)
                                          AND YCoordxD < BallsxD(1).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length))
                                          OR
                                          (XCoordxD > BallsxD(2).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(2).BallX'length)
                                          AND XCoordxD < BallsxD(2).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(2).BallX'length)
                                          AND YCoordxD > BallsxD(2).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(2).BallY'length)
                                          AND YCoordxD < BallsxD(2).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(2).BallY'length)));
  
    BluexS <= BALL_RGB(4-1 downto 0)    WHEN((XCoordxD > BallsxD(0).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND XCoordxD < BallsxD(0).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(0).BallX'length)
                                          AND YCoordxD > BallsxD(0).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length)
                                          AND YCoordxD < BallsxD(0).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(0).BallY'length))
                                          OR
                                          (XCoordxD > BallsxD(1).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                          AND XCoordxD < BallsxD(1).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(1).BallX'length)
                                          AND YCoordxD > BallsxD(1).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length)
                                          AND YCoordxD < BallsxD(1).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(1).BallY'length))
                                          OR
                                          (XCoordxD > BallsxD(2).BallX - to_unsigned(BALL_WIDTH/2, BallsxD(2).BallX'length)
                                          AND XCoordxD < BallsxD(2).BallX + to_unsigned(BALL_WIDTH/2, BallsxD(2).BallX'length)
                                          AND YCoordxD > BallsxD(2).BallY - to_unsigned(BALL_HEIGHT/2, BallsxD(2).BallY'length)
                                          AND YCoordxD < BallsxD(2).BallY + to_unsigned(BALL_HEIGHT/2, BallsxD(2).BallY'length)));
  end if;
  
end process;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
