-- pong_types_pkg.vhd
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use work.dsd_prj_pkg.all;

PACKAGE pong_types_pkg IS
  
  CONSTANT MAX_BALL_COUNT : natural := 4;
  TYPE GameControl IS (Game1Ball, Game2Ball, Game3Ball, GameEnd);

  CONSTANT MAX_OBS_COUNT : natural := 9;
  constant OBSTACLE_RGB : std_logic_vector(BIT_SIZE_RGB - 1 downto 0) := x"F00"; -- Red color
  
  -- Ball object 
  TYPE BallType IS RECORD
    BallX     : unsigned(COORD_BW - 1 DOWNTO 0);
    BallY     : unsigned(COORD_BW - 1 DOWNTO 0);
    BallXSpeed: signed(2-1 DOWNTO 0);
    BallYSpeed: signed(2-1 DOWNTO 0);
    IsActive  : unsigned(2-1 DOWNTO 0);
    Collision : std_logic;
  END RECORD;

  -- Plate object
  TYPE PlateBumpType IS RECORD
    Left : signed(COORD_BW-1 downto 0);
    Right : signed(COORD_BW-1 downto 0);  
  END RECORD; 
  
  -- Obstacle object
  TYPE ObstacleType IS RECORD
    X      : unsigned(COORD_BW - 1 DOWNTO 0);
    Y      : unsigned(COORD_BW - 1 DOWNTO 0);
    Width  : unsigned(COORD_BW - 1 DOWNTO 0);
    Height : unsigned(COORD_BW - 1 DOWNTO 0);
  END RECORD;
  
  -- Array of objects
  TYPE BallArrayType IS ARRAY (0 TO MAX_BALL_COUNT-1) OF BallType;
  TYPE PlateBumpArrayType IS ARRAY (0 to MAX_BALL_COUNT-1) OF PlateBumpType;  
  TYPE ObstacleArrayType IS ARRAY (0 to MAX_OBS_COUNT-1) OF ObstacleType;

  -- Example obstacle definitions
  CONSTANT OBSTACLES : ObstacleArrayType := (
    0 => (x => to_unsigned(70, COORD_BW), y => to_unsigned(180, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    1 => (x => to_unsigned(190, COORD_BW), y => to_unsigned(180, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    2 => (x => to_unsigned(260, COORD_BW), y => to_unsigned(260, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    3 => (x => to_unsigned(340, COORD_BW), y => to_unsigned(260, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    4 => (x => to_unsigned(400, COORD_BW), y => to_unsigned(210, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    5 => (x => to_unsigned(470, COORD_BW), y => to_unsigned(310, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    6 => (x => to_unsigned(640, COORD_BW), y => to_unsigned(310, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    7 => (x => to_unsigned(730, COORD_BW), y => to_unsigned(210, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW)),
    8 => (x => to_unsigned(850, COORD_BW), y => to_unsigned(310, COORD_BW), Width => to_unsigned(80, COORD_BW), Height => to_unsigned(20, COORD_BW))
  );

END PACKAGE;