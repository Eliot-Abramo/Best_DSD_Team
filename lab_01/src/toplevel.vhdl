--=============================================================================
-- @file toplevel.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;

--=============================================================================
--
-- toplevel
--
-- @brief This file specifies a basic toplevel circuit for the Vivado
-- introduction in the Digital systems design class (EE-334) taught at EPFL.
-- The file is a bit verbose for a file of this size but the comments serve to
-- illustrate the different parts of a VHDL file.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR TOPLEVEL
--=============================================================================
entity toplevel is
  port (
    P0xSI : in std_logic;
    P1xSI : in std_logic;
    P2xSI : in std_logic;
    P3xSI : in std_logic;

    LED0xSO : out std_logic;
    LED3xSO : out std_logic
  );
end toplevel;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of toplevel is

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  LED0xSO <= P0xSI or  P1xSI;
  LED3xSO <= P2xSI and P3xSI;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
