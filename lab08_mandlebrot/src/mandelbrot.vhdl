--=============================================================================
-- @file mandelbrot.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- mandelbrot
--
-- @brief This file specifies a basic circuit for mandelbrot
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR MANDELBROT
--=============================================================================
entity mandelbrot is
    port (
        CLKxCI : in std_logic;
        RSTxRI : in std_logic;

        WExSO   : out std_logic;
        XxDO    : out unsigned(COORD_BW - 1 downto 0);
        YxDO    : out unsigned(COORD_BW - 1 downto 0);
        IterxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
    );
end entity mandelbrot;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of mandelbrot is

    -- State machine
    type FsmState is (CalculateNew, IterateCheck, Output);
    signal FsmStatexDP, FsmStatexDN : FsmState := CalculateNew;
    
    signal XCntxDP, XCntxDN : unsigned(COORD_BW - 1 downto 0) := (others => '0');
    signal YCntxDP, YCntxDN : unsigned(COORD_BW - 1 downto 0) := (others => '0');

    -- Counters
    signal cRealCntxDP, cRealCntxDN : signed(N_BITS - 1 downto 0) := C_RE_0;
    signal cComplexCntxDP, cComplexCntxDN : signed(N_BITS - 1 downto 0) := C_IM_0;

    signal zRealCntxDP, zRealCntxDN : signed(N_BITS - 1 downto 0) := C_RE_0;
    signal zComplexCntxDP, zComplexCntxDN : signed(N_BITS - 1 downto 0) := C_IM_0;

    signal IterxDP, IterxDN : unsigned(MEM_DATA_BW - 1 downto 0) := (others => '0');

    -- Mandelbrot intermediate values
    signal XComplex_FULLxDP, YComplex_FULLxDP, Complex_NORMxDP : unsigned(2*N_BITS-1 downto 0);
    signal Z_rxxDP, Z_ixxDP : unsigned(N_BITS-1 downto 0);
    signal z_RxIx_2xDP : unsigned(N_BITS+3-1 downto 0);
    signal Complex_XY_FULLxDP : signed(2*N_BITS-1 downto 0);
    signal Complex_XYxD : signed(N_BITS-1 downto 0);

    -- Output
    signal WExDP, WExDN : std_logic := '0';


--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin
    process(CLKxCI, RSTxRI)
    begin
        if (RSTxRI = '1') then
            FsmStatexDP <= CalculateNew;
            XCntxDP <= (others => '0');
            YCntxDP <= (others => '0');
            cRealCntxDP <= C_RE_0;
            cComplexCntxDP <= C_IM_0;
            zRealCntxDP <= C_RE_0;
            zComplexCntxDP <= C_IM_0;
            IterxDP <= (others => '0');
            WExDP <= '0';

        elsif rising_edge(CLKxCI) then
            FsmStatexDP <= FsmStatexDN;
            XCntxDP <= XCntxDN;
            YCntxDP <= YCntxDN;
            cRealCntxDP <= cRealCntxDN;
            cComplexCntxDP <= cComplexCntxDN;
            zRealCntxDP <= zRealCntxDN;
            zComplexCntxDP <= zComplexCntxDN;
            IterxDP <= IterxDN;
            WExDP <= WExDN;
            
        end if;
    end process;

    process(all)
    begin
        FsmStatexDN <= FsmStatexDP;
        XCntxDN <= XCntxDP;
        YCntxDN <= YCntxDP;
        cRealCntxDN <= cRealCntxDP;
        cComplexCntxDN <= cComplexCntxDP;
        zRealCntxDN <= zRealCntxDP;
        zComplexCntxDN <= zComplexCntxDP;
        IterxDN <= IterxDP;
        WExDN <= '0';

        case FsmStatexDP is
            when CalculateNew =>
                -- Update FSM state
                FsmStatexDN <= IterateCheck;

                -- Reset all variables and iterate for new pixel
                XCntxDN <= XCntxDP + 1;
                cRealCntxDN <= cRealCntxDP + C_RE_INC;
                zRealCntxDN <= cRealCntxDP + C_RE_INC;
                zComplexCntxDN <= cComplexCntxDP;
                IterxDN <= (others => '0');

                -- If reach end of x-axis of screen, reset and increment row
                if (XCntxDP >= 1023) then
                    XCntxDN <= (others => '0');
                    cRealCntxDN <= C_RE_0;
                    zRealCntxDN <= C_RE_0;

                    if (YCntxDP < 767) then
                        YCntxDN <= YCntxDP + 1;
                        cComplexCntxDN <= cComplexCntxDP + C_IM_INC;
                        zComplexCntxDN <= cComplexCntxDP + C_IM_INC;
                    else 
                        YCntxDN <= (others => '0');
                        cComplexCntxDN <= C_IM_0;
                        zComplexCntxDN <= C_IM_0;
                    end if;
                end if;

            when IterateCheck =>
                -- Verify that we haven't reached max iterations
                if (IterxDP >= MAX_ITER - 1) then
                    FsmStatexDN <= Output;
                    IterxDN <= (others => '0');
                    WExDN <= '1';
                elsif (z_RxIx_2xDP >= ITER_LIM) then
                    -- Count color if reach MAX_ITER
                    FsmStatexDN <= Output;
                    IterxDN <= IterxDP;
                    WExDN <= '1';
                else
                    -- Iterate and claculate
                    -- z_r = z_r^2 - z_i^2 + c_r
                    zRealCntxDN <= signed(Z_rxxDP) - signed(Z_ixxDP) + signed(cRealCntxDP);

                    -- z_i = 2*z_r*z_i + c_i
                    zComplexCntxDN <= signed(Complex_XYxD) + signed(cComplexCntxDP);

                    -- Increment iteration count
                    IterxDN <= IterxDP + 1;
                    -- Repeat
                    FsmStatexDN <= IterateCheck;
                end if;
            
            when Output =>
                FsmStatexDN <= CalculateNew;
                WExDN <= '0';
                
            when others =>
                FsmStatexDN <= CalculateNew;
                WExDN <= '0';
                
        end case;
    end process;

    XComplex_FULLxDP <= unsigned(signed(zRealCntxDP)*signed(zRealCntxDP));
    YComplex_FULLxDP <= unsigned(signed(zComplexCntxDP)*signed(zComplexCntxDP));

    Z_rxxDP <= unsigned(XComplex_FULLxDP(2*N_BITS-4 downto N_BITS-3));
    Z_ixxDP <= unsigned(YComplex_FULLxDP(2*N_BITS-4 downto N_BITS-3));

    Complex_NORMxDP <= resize(XComplex_FULLxDP + YComplex_FULLxDP, 2*N_BITS);

    z_RxIx_2xDP <= Complex_NORMxDP(2*N_BITS-1 downto N_BITS-3);

    Complex_XY_FULLxDP <= resize(2*zRealCntxDP*zComplexCntxDP, 2*N_BITS);
    Complex_XYxD <= Complex_XY_FULLxDP(2*N_BITS-4 downto N_BITS-3);

    WExSO <= WExDP;
    XxDO <= XCntxDP;
    YxDO <= YCntxDP;
    ITERxDO <= IterxDP;

end architecture rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
