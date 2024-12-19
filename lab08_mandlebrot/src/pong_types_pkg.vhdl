-- pong_types_pkg.vhd
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use work.dsd_prj_pkg.all;

PACKAGE pong_types_pkg IS
  
  CONSTANT MAX_BALL_COUNT : natural := 4;
  TYPE GameControl IS (Game1Ball, Game2Ball, Game3Ball, GameEnd);

  CONSTANT MAX_OBS_COUNT : natural := 25;
  constant OBSTACLE_RGB : std_logic_vector(BIT_SIZE_RGB - 1 downto 0) := x"F00"; -- Red color
  
  -- Ball object 
  TYPE BallType IS RECORD
    BallX     : unsigned(COORD_BW - 1 DOWNTO 0);
    BallY     : unsigned(COORD_BW - 1 DOWNTO 0);
    BallXSpeed: signed(2-1 DOWNTO 0);
    BallYSpeed: signed(2-1 DOWNTO 0);
    IsActive  : unsigned(2-1 DOWNTO 0);
    Color : std_logic_vector(BIT_SIZE_RGB - 1 DOWNTO 0);
    Counter : unsigned(3-1 DOWNTO 0);
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

  
  CONSTANT OBSTACLES : ObstacleArrayType := (
    -- Obstacles to draw 'Roboto' in the top left corner
    -- R
    0 => (X => to_unsigned(10, COORD_BW),  Y => to_unsigned(10, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(25, COORD_BW)),  -- Left vertical bar
    1 => (X => to_unsigned(15, COORD_BW),  Y => to_unsigned(10, COORD_BW),  Width => to_unsigned(10, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Top horizontal bar
    2 => (X => to_unsigned(15, COORD_BW),  Y => to_unsigned(20, COORD_BW),  Width => to_unsigned(10, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Middle horizontal bar
    3 => (X => to_unsigned(25, COORD_BW),  Y => to_unsigned(10, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(15, COORD_BW)),  -- Right vertical bar
    4 => (X => to_unsigned(20, COORD_BW),  Y => to_unsigned(25, COORD_BW),  Width => to_unsigned(10, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Diagonal leg
    5 => (X => to_unsigned(25, COORD_BW),  Y => to_unsigned(30, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(5, COORD_BW)),   -- Diagonal end
    -- o
    6 => (X => to_unsigned(35, COORD_BW),  Y => to_unsigned(10, COORD_BW),  Width => to_unsigned(15, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Top horizontal bar
    7 => (X => to_unsigned(35, COORD_BW),  Y => to_unsigned(30, COORD_BW),  Width => to_unsigned(15, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Bottom horizontal bar
    8 => (X => to_unsigned(35, COORD_BW),  Y => to_unsigned(15, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(15, COORD_BW)),  -- Left vertical bar
    9 => (X => to_unsigned(45, COORD_BW),  Y => to_unsigned(15, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(15, COORD_BW)),  -- Right vertical bar
    -- b
   10 => (X => to_unsigned(55, COORD_BW),  Y => to_unsigned(10, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(25, COORD_BW)),  -- Left vertical bar
   11 => (X => to_unsigned(60, COORD_BW),  Y => to_unsigned(10, COORD_BW),  Width => to_unsigned(10, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Top horizontal bar
   12 => (X => to_unsigned(70, COORD_BW),  Y => to_unsigned(15, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(10, COORD_BW)),  -- Right vertical bar upper
   13 => (X => to_unsigned(60, COORD_BW),  Y => to_unsigned(25, COORD_BW),  Width => to_unsigned(10, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Middle horizontal bar
   14 => (X => to_unsigned(70, COORD_BW),  Y => to_unsigned(30, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(5, COORD_BW)),   -- Right vertical bar lower
    -- o
   15 => (X => to_unsigned(80, COORD_BW),  Y => to_unsigned(10, COORD_BW),  Width => to_unsigned(15, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Top horizontal bar
   16 => (X => to_unsigned(80, COORD_BW),  Y => to_unsigned(30, COORD_BW),  Width => to_unsigned(15, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Bottom horizontal bar
   17 => (X => to_unsigned(80, COORD_BW),  Y => to_unsigned(15, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(15, COORD_BW)),  -- Left vertical bar
   18 => (X => to_unsigned(90, COORD_BW),  Y => to_unsigned(15, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(15, COORD_BW)),  -- Right vertical bar
    -- t
   19 => (X => to_unsigned(100, COORD_BW), Y => to_unsigned(10, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(25, COORD_BW)), -- Vertical bar
   20 => (X => to_unsigned(95, COORD_BW),  Y => to_unsigned(10, COORD_BW),  Width => to_unsigned(15, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Top horizontal bar
    -- o
   21 => (X => to_unsigned(110, COORD_BW), Y => to_unsigned(10, COORD_BW),  Width => to_unsigned(15, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Top horizontal bar
   22 => (X => to_unsigned(110, COORD_BW), Y => to_unsigned(30, COORD_BW),  Width => to_unsigned(15, COORD_BW), Height => to_unsigned(5, COORD_BW)),   -- Bottom horizontal bar
   23 => (X => to_unsigned(110, COORD_BW), Y => to_unsigned(15, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(15, COORD_BW)),  -- Left vertical bar
   24 => (X => to_unsigned(120, COORD_BW), Y => to_unsigned(15, COORD_BW),  Width => to_unsigned(5, COORD_BW),  Height => to_unsigned(15, COORD_BW))   -- Right vertical bar
  );
  
END PACKAGE;