--=============================================================================
-- @file toplevel_tb.vhdl
--=============================================================================
-- Standard library
library ieee;
library std;
-- Standard packages
use std.env.all;
use ieee.std_logic_1164.all;

--=============================================================================
--
-- toplevel_tb
--
-- @brief This file specifies the testbench for the Vivado introduction in the
-- Digital systems design class (EE-334) taught at EPFL.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR TOPLEVEL_TB
--=============================================================================
entity toplevel_tb is
end toplevel_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of toplevel_tb is

  constant DELAY: time := 10 ns;

  -- Note: All input signals have to be initialized to 0 (or some other known state)
  signal P0xSI : std_logic := '0';
  signal P1xSI : std_logic := '0';
  signal P2xSI : std_logic := '0';
  signal P3xSI : std_logic := '0';

  -- IMPORTANT: DO NOT INITIALIZE THE OUTPUT SIGNALS!!!!!!
  signal LED0xSO : std_logic;
  signal LED3xSO : std_logic;

--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
  component toplevel is
    port (
      P0xSI : in std_logic;
      P1xSI : in std_logic;
      P2xSI : in std_logic;
      P3xSI : in std_logic;

      LED0xSO : out std_logic;
      LED3xSO : out std_logic
    );
  end component;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- COMPONENT INSTANTIATIONS
--=============================================================================
  dut: toplevel
    port map (
      P0xSI => P0xSI,
      P1xSI => P1xSI,
      P2xSI => P2xSI,
      P3xSI => P3xSI,

      LED0xSO => LED0xSO,
      LED3xSO => LED3xSO
    );

--=============================================================================
-- TEST PROCESSS
--=============================================================================
  p_stim: process
  begin

    wait for DELAY;

    -- Make OR gate output transition to HIGH
    P0xSI <= '1';
    wait for DELAY;

    P1xSI <= '1';
    wait for DELAY;

    -- Make OR gate output transition to LOW
    P0xSI <= '0';
    P1xSI <= '0';
    wait for DELAY;

    -- Make AND gate output transition HIGH
    P2xSI <= '1';
    wait for DELAY;

    P3xSI <= '1';
    wait for DELAY;

    -- Make AND gate output transition LOW
    P2xSI <= '0';
    P3xSI <= '0';
    wait for DELAY;

    -- Make both gates transition HIGH
    P0xSI <= '1';
    P1xSI <= '1';
    P2xSI <= '1';
    P3xSI <= '1';
    wait for DELAY;

    -- Make both gates transition LOW
    P0xSI <= '0';
    P1xSI <= '0';
    P2xSI <= '0';
    P3xSI <= '0';
    wait for DELAY;

    stop(0);

  end process;

end tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
