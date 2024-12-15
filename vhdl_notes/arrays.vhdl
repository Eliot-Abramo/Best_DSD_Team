-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ARRAY TYPES

-- To describe HW we often need BUSES (groups of signals or constants)
-- Array are defined by declaring a custom type
-- Custom types are declared in the architecture preamble

-- Elements from left-to-right can be counted "from-low-to-high" or "from-high-downto-low"
-- Array types can again serve as basis for new arrays to build 2+D arrays

ARCHITECTURE architecture_name OF other_entity_name IS
    -- type declarations
    TYPE array_type_name_1_1D IS ARRAY (low TO high) of base_type;
    TYPE array_type_name_2_1D IS ARRAY (high DOWNTO low) of base_type;
    TYPE array_type_name_3_2D IS ARRAY (INTEGER RANGE <>) of array_type_name_2;

    -- signal declaration
    SIGNAL signal_1_name : array_type_name_1;
                                           -- range is defined here
    SIGNAL signal_2_name : array_type_name_3(low TO high);

-- DOWNTO needs STD_LOGIC_VECTOR. Ideally only use DOWNTO
USE ieee.std_logic_1164.ALL;

-- Accessing from and assigning to array elements or ranges:
target_array_object(index) <= base_type_object
target_base_type_object <= target_base_type_array(index)
target_array_object(index_range) <= from_array_object(index_range)
-- index_range = low TO high | high DOWNTO low

-- Assigning array aggregates (collection of elements) to an array
target_array_object <= (value_1, value_2, ...);
target_array_object <= (idx_1=>value_1, idx_2=>value_2, ...);
target_array_object <= (idx_1=>value_1, idx_2|idx_3=>value_2, ...); -- sets value_2 to BOTH idx_2 and idx_3

-- Filling an array
-- OTHERS refers to all still unassigned elements in the aggregator
target_array_object <= (idx_1=>value_1, OTHERS=>value_2); -- fill all remaining
target_array_object <= (OTHERS=>value_1); -- fill all elements

-- Assignements to arrays with character elements
-- Array literal values can be placed in double quotes
target_array_object(index_range) <= "..." -- i.e. "0100-1"
-- STD_LOGIC_VECTOR is based on STD_LOGIC which is a character type, i.e. '0','1','X','-'
target_array_object(index_range) <= "010-10-"

-- Concatenation of arrays and array elements
-- adds base_type_object_2 at the end of base_type_object_1
-- make sure index_range is big enough to take every bit otherwise first bit of base_object_1 disapears
target_array_object(index_range) <= base_type_object_1 & base_type_object_2

-------------------------------------------------------------------------------------------------

-- i.e.

-- Signal decleration of std_logic_vectors
SIGNAL AxD, BxD, CxD, DxD, ExD : STD_LOGIC_VECTOR(8-1 DOWNTO 0);
SIGNAL QxS : STD_LOGIC;

-- Assignment
QxS <= '1';
AxD <= "10010101";
BxD <= "-0-001-1";
CxD <= (OTHERS => "0");

-- Concatenation and indexing
BxD <= AxD(7-1 DOWNTO 0) & '0'; -- shift left
CxD <= '0' & AxD(7-1 DOWNTO 1) -- shift right
DxD <= AxD(7-1 DOWNTO 0) & AxD(8-1) --rotate left
ExD <= QxS & QxS & '1' & "00001";
