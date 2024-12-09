-- pong_types_pkg.vhd
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use work.dsd_prj_pkg.all;

PACKAGE pong_types_pkg IS
  
  CONSTANT MaxBallCount : natural := 3;

  TYPE BallType IS RECORD
    BallX     : unsigned(COORD_BW - 1 DOWNTO 0);
    BallY     : unsigned(COORD_BW - 1 DOWNTO 0);
    BallXSpeed: signed(2-1 DOWNTO 0);
    BallYSpeed: signed(2-1 DOWNTO 0);    
  END RECORD;

  TYPE BallArrayType IS ARRAY (0 TO 3-1) OF BallType;
END PACKAGE;
