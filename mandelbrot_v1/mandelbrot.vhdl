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
    ITERxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
  );
end entity mandelbrot;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of mandelbrot is

  -- X and Y coordinates comptor
  signal XCompxDP : unsigned(COORD_BW - 1 downto 0);
  signal XCompxDN : unsigned(COORD_BW - 1 downto 0);

  signal YCompxDP : unsigned(COORD_BW - 1 downto 0);
  signal YCompxDN : unsigned(COORD_BW - 1 downto 0);

  -- Enable and reset comptors of X and Y coordinates
  signal EnableCompXxS : std_logic;
  signal EnableCompYxS : std_logic;

  signal ResetCompXxR : std_logic;
  signal ResetCompYxR : std_logic;

  -- Complex coordinates
  signal XComplexCompxDP : signed(N_BITS - 1 downto 0);
  signal XComplexCompxDN : signed(N_BITS - 1 downto 0);

  signal YComplexCompxDP : signed(N_BITS - 1 downto 0);
  signal YComplexCompxDN : signed(N_BITS - 1 downto 0);

  -- signals for the iteration in the mandelbrot algorithm
  signal iterxDP : unsigned(MEM_DATA_BW - 1 downto 0);
  signal iterxDN : unsigned(MEM_DATA_BW - 1 downto 0);

  signal ZrxDP : signed(N_BITS - 1 downto 0);
  signal ZixDP : signed(N_BITS - 1 downto 0);

  signal ZrxDN : signed(N_BITS - 1 downto 0);
  signal ZixDN : signed(N_BITS - 1 downto 0);

  -- signals for the next iteration in the mandelbrot algorithm
  signal Zr_next : signed(N_BITS - 1 downto 0);
  signal Zi_next : signed(N_BITS - 1 downto 0);

  signal Z_rxDN, Z_rxDP : signed(N_BITS - 1 downto 0):= (others => '0');
  signal Z_ixDN, Z_ixDP : signed(N_BITS - 1 downto 0):= (others => '0');
  signal XComplex_FULLxD, YComplex_FULLxD, Complex_NORMxD  : unsigned(N_BITS + N_BITS - 1 downto 0);
  signal X_SQxD, Y_SQxD : signed(N_BITS - 1 downto 0);
  signal Complex_XY_FULLxD  : signed(N_BITS + N_BITS - 1 downto 0):= (others => '0');
  signal Complex_XYxD  : signed(N_BITS - 1 downto 0);

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  -- X comptor for 0 to 1023 pixels
  X_comp : process (CLKxCI, RSTxRI)
  begin
    if RSTxRI = '1' then -- reset asynchrone
        -- real
        XCompxDP <= (others => '0');
        XCompxDN <= (others => '0');
        
        EnableCompXxS <= '1';
        
        ResetCompXxR <= '0';

        -- complex 
        XComplexCompxDP <= C_RE_0;
        XComplexCompxDN <= C_RE_0;

    elsif rising_edge(CLKxCI) then 
      if ResetCompXxR = '1' then -- reset synchrone
        -- real
        XCompxDP <= (others => '0');
        XCompxDN <= (others => '0');

        EnableCompXxS <= '1';

        ResetCompXxR <= '0';

        -- complex
        XComplexCompxDP <= C_RE_0;
        XComplexCompxDN <= C_RE_0;

      elsif EnableCompXxS = '1' then
        if XCompxDP = HS_DISPLAY then
          -- real and complex action
          ResetCompXxR <= '1';
          EnableCompYxS <= '1';

        elsif EnableCompXxS = '1' then
          -- real
          XCompxDN <= XCompxDP + 1;
          EnableCompXxS <= '0';

          -- complex 
          XComplexCompxDN <= XComplexCompxDP + C_RE_INC;
        end if;
      end if;

      -- real
    XCompxDP <= XCompxDN;
    XxDO <= XCompxDP;

    -- complex
    XComplexCompxDP <= XComplexCompxDN;

    end if;
      
  end process;

  Y_comp : process (CLKxCI, RSTxRI)
  begin
    if RSTxRI = '1' then -- reset asynchrone
        -- real
        YCompxDP <= (others => '0');
        YCompxDN <= (others => '0');
        
        EnableCompYxS <= '1';
        
        ResetCompYxR <= '0';

        -- complex
        YComplexCompxDP <= C_IM_0;
        YComplexCompxDN <= C_IM_0;

    elsif rising_edge(CLKxCI) then 
      if ResetCompYxR = '1' then -- reset synchrone
        -- real
        YCompxDP <= (others => '0');
        YCompxDN <= (others => '0');

        EnableCompYxS <= '1';

        ResetCompYxR <= '0';

        -- complex 
        YComplexCompxDP <= C_IM_0;
        YComplexCompxDN <= C_IM_0;

      elsif EnableCompYxS = '1' then
        if YCompxDP = VS_DISPLAY then
          -- real and complex action
          ResetCompYxR <= '1';

        elsif EnableCompYxS = '1' then
          YCompxDN <= YCompxDP + 1;
          EnableCompYxS <= '0';
        end if;
      end if;

      -- real
    YCompxDP <= YCompxDN;
    YxDO <= YCompxDP;

    -- complex
    YComplexCompxDP <= YComplexCompxDN;

    end if;
      
  end process;

  Mandelbrot : process (CLKxCI, RSTxRI)
  begin
    if RSTxRI = '1' then -- reset asynchrone
        iterxDP <= (others => '0');
        iterxDN <= (others => '0');

        ZrxDP <= (others => '0');
        ZixDP <= (others => '0');

        ZrxDN <= (others => '0');
        ZixDN <= (others => '0');
    
    elsif rising_edge(CLKxCI) then
      XComplex_FULLxD <= unsigned(Z_rxDP * Z_rxDP);
      X_SQxD <= signed(XComplex_FULLxD(N_BITS + N_FRAC - 1 downto N_FRAC));
      
      YComplex_FULLxD <= unsigned(Z_ixDP * Z_ixDP);
      Y_SQxD <= signed(YComplex_FULLxD(N_BITS + N_FRAC - 1 downto N_FRAC));
  
      Complex_NORMxD <= YComplex_FULLxD + XComplex_FULLxD;

      if iterxDP = MAX_ITER or Complex_NORMxD > ITER_LIM then
        iterxDN <= (others => '0');
        WExSO <= '1';
        EnableCompXxS <= '1';

        Complex_XY_FULLxD <= resize(2 * Z_rxDP * Z_ixDP, 2*N_BITS);
        Complex_XYxD <= Complex_XY_FULLxD(N_BITS + N_FRAC - 1 downto N_FRAC);

        Zr_next <=  X_SQxD - Y_SQxD + XComplexCompxDP;
        Zi_next <=  Complex_XYxD + YComplexCompxDP;

        ZrxDN <= Zr_next;
        ZixDN <= Zi_next;

      else
        WExSO <= '0';
        EnableCompXxS <= '0';
        iterxDN <= iterxDP + 1;

        Zr_next <= XComplexCompxDP;
        Zi_next <= YComplexCompxDP;

        ZrxDN <= Zr_next;
        ZixDN <= Zi_next;
      end if;

      ZrxDP <= ZrxDN;
      ZixDP <= ZixDN;

      iterxDP <= iterxDN;
      ITERxDO <= iterxDP;
    end if;

  end process;

end architecture rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
