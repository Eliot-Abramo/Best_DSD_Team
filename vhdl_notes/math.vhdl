-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Built in INTEGER supports basics arithemetic operations, but the integer is not sufficiently generic for optimized HW
-- INTEGER type has 32 bit and rep only signed numbers having half the range
-- Any overflow or undeflow will trigger an error in the simulation rather than a wrap-around

ieee.numeric_std.all -- package that define integer as array of std_logic
-- 2 new types of data, UNSIGNED and SIGNED

-- UNSIGNED are rep. as standard binary
-- SIGNED are rep. using 2 complement
-- Array elements can be accessed and assigned as in std_logic_vector

-- SIGNED and UNSIGNED used weighted binary digits, counted from right to left
-- Use DOWNTO bit order to palce the LSB on the right and MSB on the left

-- When declaring signal it is useful to see number of bits so use this convention
SIGNAL <Signal_Name>xD : UNSIGNED(#BITS-1 DOWNTO 0);
SIGNAL <Signal_Name>xD : SIGNED(#BITS-1 DOWNTO 0);

-------------------------------------------------------------------------------------------------

-- i.e.
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY adder IS
    PORT(
        AxDI,
        BxDI,
        CxDO
    )
END adder;

ARCHITECTURE rtl OF adder IS
    -- signal declaration
    SIGNAL SgnAxD, SgnBxD, SgnCxD : signed(8-1 DOWNTO 0);
BEGIN
    -- type conversion
    SgnAxD <= signed(AxDI); --uses non HW ressources
    SgnBxD <= signed(BxDI);

    -- arithmetic
    SgnCxD <= SgnAxD + SgnBxD;

    -- convert back to std_logic_vector for output port
    CxDO <= std_logic_vector(SgnCxD);

END rtl;

-------------------------------------------------------------------------------------------------

-- Conditional Assignments

-- order priority decreases as you go down, multiple MUX for all if-else statements
target_signal <= expression_1 WHEN boolean_expression_1 ELSE
                 expression_2 WHEN boolean_expression_2 ELSE
                .... 
                expression_N; --ELSE

-- select value of target_signal with cond_signal, acts as select bit of MUX
WITH cond_signal SELECT target_signal <= expression_1 WHEN constant_1,
                                         expression_2 WHEN constant_2,
                                         ...
                                         expression_N WHEN OTHERS -- ELSE

-- physical wire can never not be assigned, so always make sure you wrap up with an else

-------------------------------------------------------------------------------------------------

-- i.e. simple ALU
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY my_first_counter IS
    PORT(
        AxDI    : IN std_logic_vector(8-1 DOWNTO 0);
        BxDI    : IN std_logic_vector(8-1 DOWNTO 0);
        CMDxSI  : IN std_logic_vecotr(2-1 DOWNTO 0);

        CxDO    : OUT std_logic_vector(8-1 DOWNTO 0);
    );
END my_first_counter;

architecture rtl of my_first_counter is
    --signal declaration
    SIGNAL SgnCxD   : SIGNED(8-1 DOWNTO 0);

BEGIN
    WITH CMDxSI SELECT
        SgnCxD <=
        SIGNED(AxDI) + SIGNED(BxDI) WHEN "00",
        SIGNED(AxDI) - SIGNED(BxDI) WHEN "01",
        SIGNED(AxDI AND BxDI)       WHEN "10",
        "--------" WHEN OTHERS;

        -- output assignment with type conversion
        CxDO <= std_logic_vector(SgnCxD);

END rtl;
