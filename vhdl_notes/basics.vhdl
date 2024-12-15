-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Steps:
-- Editing
-- Analysis - checks the syntax and translates VHDL code into a binary rep.
--           that is stored in the specified design library. Default library
--           typically called "work".
--
-- Elaboration: expands the binary rep. and prepares it for the simulation or synthesis

-- WORK contains your design and is used when no library is explicitly specified when compiling

-------------------------------------------------------------------------------------------------

-- PACKAGES

-- collections of constants, types and functions
-- similar to include files in c
-- can include constants, components, data type def or commong functions and procedures

-- They are useful to avoid the need to change design-wide param. in one common place to
-- avoid inconsistendies and simplify changes.

-- VHDL components and packages can "use" the content of other packages

-- To use a package:
LIBRARY library_name;
USE library name.package_name.function_name/ALL; --function name or ALL

-- WORK library is always already declared by default and can be referred to without explicitly declaring it
-- packages included in library are not visible in the design
use WORK.my_package.ALL;

--i.e.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL; --for multi-valued logic 
USE ieee.numeric_std.ALL; --for signed/unsigned arithmetic

-- described in .vhd/.vhdl files, same as design entities
-- ALWAYS USE seperate files for each package

PACKAGE package_name IS
    -- package content
    -- decleration of CONSTANTS, TYPES, FUNCTIONS, ...
END PACKAGE package_name;

-- Packages can themselves include other packages from any library
-- Package included in a package is only visible in that package, not in the level above


-------------------------------------------------------------------------------------------------

-- ENTITY

-- ENTITY defines external interface of a HW module. Describes what the module is and how it connects
-- to other modules but not how it operates internally.

-- Entity declaration defines: 
    -- name of component
    -- ports:             interface (inputs and outputs) of the component
    -- generics:          instance specific paramters. Generics MUST resolve to a constat (to be known)
    --                    at compile time.

-- Ports and generics sections are optional.

-- Port directions can be:
    -- IN                 Input only
    -- OUT                Output only
    -- INOUT              Input/output for tristate
    -- BUFFER             Output that can also be read

--i.e.
ENTITY alu8_comb is
    PORT(
            opa, opb  : IN std_logic_vector(7 downto 0);
            cmd,      : IN std_logic_vector(2 downto 0);
            result    : OUT std_logic_vector(7 downto 0);
            zero:     : OUT std_logic;
            ovfl      : OUT std_logic
    );
END alu8_comb;


-------------------------------------------------------------------------------------------------

-- ARCHITECTURE

-- ARCHITECTURE specifies the model or implementation of a component. 

-- Provides internal implementation of the ENTITY. It describes the behavior or structure of the module
-- defined by the ENTITY.

-- Multiple ARCHITECTURE can be associated with the same entity, allowing for different implemenations
-- of the same interface. 

-- ARCHITECTURE declaration defines:
    -- name of architecture
    -- name of the associated entity
    -- architecture body that includes signal declarations and the actual code

ARCHITECTURE architecture_name OF entity_name IS
    -- signals to be used are declared here
BEGIN
    -- Insert VHDL statements to assign outputs to each of the output signals defined in the ENTITY
END architecture_name;

--i.e.
ENTITY and_gate IS
PORT( a: IN std_logic;
      b: IN std_logic;
      c: OUT std_logic);
END and_gate;

ARCHITECTURE comb_logic OF and_gate IS
BEGIN
    c <= a AND b;
END comb_logic;

-------------------------------------------------------------------------------------------------

-- COMPONENTS: ENTITY and ARCHITECTURE

-- Hardware blocks
-- Multiple architectures can be provided for the same entity
-- CONFIGURATIONS define which architecture is used if multiple exist
-- VHDL entity defines the interfaces of a VHDL component

-- Components need to be declared before instantiation/using them in the architecture of another component
-- Declaration in the preamble of the architecture in which they are used
-- Can also be declared in a package

-- Component declation and name must match corresponding entity name

-- Components act as placeholders or references to entities that may be defined elsewhere
-- During binding, compiler associates component instance with actual entities

-- i.e.
ENTITY entity_name IS
    GENERIC (
        generic_1_name : generic_1_type;
        generic_2_name : generic_2_type;
    );
    PORT (
        port_1_name : port_1_dir port_1_type;
        port_2_name : port_2_dir port_2_type;
    );
END entity_name;

ARCHITECTURE architecture_name OF other_entity_name IS
    -- component decleration
    COMPONENT component_name IS
        GENERIC (
            generic_1_name : generic_1_type;
            generic_2_name : generic_2_type;
        );
        PORT (
            port_1_name : port_1_dir port_1_type;
            port_2_name : port_2_dir port_2_type;
        );
BEGIN
    instance_1_name : component_name
        GENERIC MAP (
            generic_1_name => CONSTANT_EXP_1_1,
            generic_2_name => CONSTANT_EXP_1_2
        )
        PORT MAP (
            port_1_name => port_1_1_signal,
            port_2_name => port_1_2_signal
        );

    instance_2_name : component_name
        GENERIC MAP (
            generic_1_name => CONSTANT_EXP_2_1,
            generic_2_name => CONSTANT_EXP_2_2
        )
        PORT MAP (
            port_1_name => port_2_1_signal,
            port_2_name => port_2_2_signal
        );
    
END architecture_name;
-- connects ports of an instance of the components to signals
-- defines the generics (parameters) based on the expressions that can be evaluated at compilation time

-------------------------------------------------------------------------------------------------

-- SIGNALS

-- SIGNALS are wires, they are defined ONLY inside architecture
-- The ports of an entity allows signals to be connected from outside a component
-- Ports can be treated as signals inside its architecture

-- Signals are declared in the preamble of the architecture
-- Signals are associated with data types with abstract electrical behavior

ARCHITECTURE architecture_name OF entity_bame IS
    -- signals to be used are declared here
    SIGNAL signal_1_name : signal_1_type;
    SIGNAL signal_2_name : signal_2_type;
BEGIN
    -- VHDL statements
END architecture_name;


-- CONSTANTS

-- Constants serve 2 purposes (but as the same object)
    -- def fixed values that are known at compilation time
    -- def of fixed electrical signals that can be thought of as connections to VDD or GND

-- Can be declated in Packages, as GENERICS in an ENTITY, as CONSTANTS in the preamble 
-- of the architecture.

-- CONSTANTS can be derived with valid expressions from other constants

ARCHITECTURE architecture_name OF entity_name IS
    -- constants to be used are declared here
    CONSTANT constant_1_name : constant_1_type := expression;
    --i.e.
    CONSTANT WIDTH_A : integer := 8-1;
    CONSTANT WIDTH_B : integer := WIDTH_A + 1;
BEGIN
    -- VHDL statements
END architecture_name;

-------------------------------------------------------------------------------------------------

-- DATA TYPES

-- Use these ones
-- Bit : 1/0
-- Boolean : true/false

-- Try and avoid this one
-- Integer : defined by a range (default is 32 bits)

-- Avoid these but they do exist
-- Char: 8 bit
-- Real : floating point
-- Time : for modeling of delays [ps, ns]

-- std_logic
-- Logic-0 -- '0' -- Weak-0 -- 'L'
-- Logic-1 -- '1' -- Weak-1 -- 'H'
-- Don't care -- '-' -- Weak-X -- 'W'
-- High Impedance -- 'Z' -- Uninitialized -- 'U'
-- Uknown -- 'X' -- AVOID THIS

-- Use High Impedance rarely and Exceptional cases

-- In Simulation:
    -- X: useful to identify driver conflicts or unkown logic levels (i.e. signal rise time)
    -- U: indicates that a signal is never assigned a value
    -- L,H,W: mostly unused and appear only in simulation to resolve conflicts
    
-------------------------------------------------------------------------------------------------

-- To assign value to RHS expression to a signal on the LHS use:
signal <= expression;

-- = driving signal with the output of the circuit that evaluates the expression
-- concurrent assignments are always carried out in //
-- A signal should never have more then 1 driver
A <= '0';
A <= '1'; -- NO, driver conflict, A = 'X' here

-- Valid values can be assigned directly to a sginal with a compatible data type
signal_1 <= <valid_value>;
signal_3 <= signal_1 <boolean_operator> signal_2;
-- Bool op = AND, OR, XOR, NAND, NOR, XNOR, NOT

-------------------------------------------------------------------------------------------------

-- VHDL not case sensitive

-- Convention:
    -- VHDL keywords in ALL UPPER CASE
    -- Signals in CamelCase

    -- <Name>x<Signal Class>[<State>][<Low Active>][<PortDirection>]

-- Class:
    -- Clock            C - i.e. CLKxCI
    -- Asyn Reset       R - i.e. RSTXRBI
    -- Control/status   S - i.e. ClearCNTxS
    -- Data/address     D - i.e. SamplexDN
    -- Test signals     T - i.e. ScanENxT

-- Active:
    -- Low              B - i.e. ENxSB
    -- High               - i.e. ENxS

-- State:
    -- Present          P - i.e. REGxDP
    -- Next             N - i.e. REGxDN

-- Direction
    -- In               I - i.e. AxDI
    -- Out              O - i.e. ZxDO

