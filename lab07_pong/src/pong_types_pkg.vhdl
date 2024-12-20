-- pong_types_pkg.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dsd_prj_pkg.all;

package pong_types_pkg is
  
  constant MAX_BALL_COUNT : natural := 3;

  type GameControl is (Game1Ball, Game2Ball, Game3Ball, GameEnd);
  
  type BallType is record
    BallX      : unsigned(COORD_BW - 1 downto 0);
    BallY      : unsigned(COORD_BW - 1 downto 0);
    BallXSpeed : signed(2-1 downto 0);
    BallYSpeed : signed(2-1 downto 0);
    IsActive   : unsigned(2-1 downto 0);
  end record;

  type PlateBumpType is record
    Left  : signed(COORD_BW-1 downto 0);
    Right : signed(COORD_BW-1 downto 0);  
  end record; 
  
  type BallArrayType is array (0 to MAX_BALL_COUNT-1) of BallType;
  type PlateBumpArrayType is array (0 to MAX_BALL_COUNT-1) of PlateBumpType;

end package;

