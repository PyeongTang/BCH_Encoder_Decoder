----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/30 13:51:55
-- Design Name: 
-- Module Name: BM_Solver - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.my_types_pkg.all;

-- =========================================================================================================================
-- BM Solver (Berlekamp-Massey Algorithm Solver) implemented by FSM
-- For Given Syndrome Polynomial S(x), Find Coefficient of Minimum Polynomial Sigma(x) only if S(x) has non-zero coefficient
-- FSM contains Several steps
--    1. Calculate Descripancy
--    2. Coefficient Update
--    3. State and Step Update
-- In Step 1, 2, there is Multiplication and Division on GF
-- So GF_MULT and GF_DIV instantiated, Both Are Sequential Logic, WAIT_MULT/DIV State Handling Handshake with GF Arithmetic Operation
-- =========================================================================================================================

entity BM_Solver is
  generic (
    g_GF_POWER                : integer := 3;
    g_ERR_CORRECTION_CAPACITY : integer := 2
  );
  port (
    i_clk            : in std_logic;
    i_n_reset        : in std_logic;
    i_syndrome_valid : in std_logic;
    i_syndrome       : in t_array_slv_n(0 to 2 * g_ERR_CORRECTION_CAPACITY - 1)(g_GF_POWER - 1 downto 0); -- slv{m}(2t - 1 downto 0), GF(2**m)
    o_sigma          : out t_array_slv_n(0 to g_ERR_CORRECTION_CAPACITY)(g_GF_POWER - 1 downto 0);
    o_sigma_valid    : out std_logic
  );
end BM_Solver;
---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of BM_Solver is
  ---------------------------------------------------------------------------
  -- Components
  ---------------------------------------------------------------------------

  component GF_MULT is
    generic (
      g_GF_POWER : integer := 3
    );
    port (
      i_clk     : in std_logic;
      i_n_reset : in std_logic;
      i_A       : in std_logic_vector(g_GF_POWER - 1 downto 0);
      i_A_valid : in std_logic;
      i_B       : in std_logic_vector(g_GF_POWER - 1 downto 0);
      i_B_valid : in std_logic;
      o_P       : out std_logic_vector(g_GF_POWER - 1 downto 0);
      o_P_valid : out std_logic
    );
  end component;

  component GF_DIV is
    generic (
      g_GF_POWER : integer := 3
    );
    port (
      i_clk     : in std_logic;
      i_n_reset : in std_logic;
      i_A       : in std_logic_vector(g_GF_POWER - 1 downto 0);
      i_A_valid : in std_logic;
      i_B       : in std_logic_vector(g_GF_POWER - 1 downto 0);
      i_B_valid : in std_logic;
      o_Q       : out std_logic_vector(g_GF_POWER - 1 downto 0);
      o_Q_valid : out std_logic
    );
  end component;
  ---------------------------------------------------------------------------
  -- Constants
  ---------------------------------------------------------------------------

  constant c_MAX_DEG : integer := g_ERR_CORRECTION_CAPACITY;
  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  type t_state is (
    IDLE,
    CAL_D_START,
    CAL_D_CHECK_LOOP,
    CAL_D_WAIT_MULT,
    COEFF_DETERMINE,
    COEFF_START_DIV,
    COEFF_WAIT_DIV,
    COEFF_CHECK_LOOP,
    COEFF_REQ_MULT,
    COEFF_WAIT_MULT,
    STATE_UPDATE,
    STEP_UPDATE,
    DONE
  );

  signal present_state : t_state := IDLE;

  -- Sequence Index

  signal n : integer := 0; --  External Loop Index, 0 to 2t - 1
  signal i : integer := 0; --  Internal Loop Index, 1 to L
  signal k : integer := 0; --  Internal Loop Index, 0 to t

  -- BM State Variable
  signal m : integer := 0; --  Latest step since L updated
  signal L : integer := 0; --  Current Degree of Sigma(X)

  -- Syndrome Polynomial
  signal syndrome : t_array_slv_n(0 to 2 * g_ERR_CORRECTION_CAPACITY - 1)(g_GF_POWER - 1 downto 0) := (others => (others => '0')); --  Latched Syndrome Value

  -- Polynomial over GF(2**m)
  signal sigma_x : t_array_slv_n(0 to g_ERR_CORRECTION_CAPACITY)(g_GF_POWER - 1 downto 0) := (others => (others => '0')); --  Coefficients of Sigma(X)
  signal B_x     : t_array_slv_n(0 to g_ERR_CORRECTION_CAPACITY)(g_GF_POWER - 1 downto 0) := (others => (others => '0')); --  Backup Coeff. of Sigma(X)
  signal T_x     : t_array_slv_n(0 to g_ERR_CORRECTION_CAPACITY)(g_GF_POWER - 1 downto 0) := (others => (others => '0')); --  Temp. Coeff. of Sigma(X)

  -- Scalar over GF(2**m)
  signal d : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0'); --  Discrepancy
  signal b : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0'); --  Latest Non-zero d
  signal c : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0'); --  GF_DIV result from d_n/b

  -- Data Valid
  signal r_sigma_valid : std_logic := '0';

  -- GF Mult and DIV Handshaking
  signal r_MULT_A       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal r_MULT_B       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal r_MULT_A_valid : std_logic                                 := '0';
  signal r_MULT_B_valid : std_logic                                 := '0';
  signal w_MULT_P       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal w_MULT_P_valid : std_logic                                 := '0';

  signal r_DIV_A       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal r_DIV_B       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal r_DIV_A_valid : std_logic                                 := '0';
  signal r_DIV_B_valid : std_logic                                 := '0';
  signal w_DIV_Q       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal w_DIV_Q_valid : std_logic                                 := '0';

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------
begin

  o_sigma       <= sigma_x;
  o_sigma_valid <= r_sigma_valid;

  ---------------------------------------------------------------------------
  -- Instances
  ---------------------------------------------------------------------------

  GF_MULT_inst : GF_MULT
  generic map(
    g_GF_POWER => g_GF_POWER
  )
  port map
  (
    i_clk     => i_clk,
    i_n_reset => i_n_reset,
    i_A       => r_MULT_A,
    i_A_valid => r_MULT_A_valid,
    i_B       => r_MULT_B,
    i_B_valid => r_MULT_B_valid,
    o_P       => w_MULT_P,
    o_P_valid => w_MULT_P_valid
  );

  GF_DIV_inst : GF_DIV
  generic map(
    g_GF_POWER => g_GF_POWER
  )
  port map
  (
    i_clk     => i_clk,
    i_n_reset => i_n_reset,
    i_A       => r_DIV_A,
    i_A_valid => r_DIV_A_valid,
    i_B       => r_DIV_B,
    i_B_valid => r_DIV_B_valid,
    o_Q       => w_DIV_Q,
    o_Q_valid => w_DIV_Q_valid
  );

  ---------------------------------------------------------------------------
  -- Process
  ---------------------------------------------------------------------------

  STATE_TRANSITION : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      present_state  <= IDLE;
      sigma_x        <= (others => ((others => '0'))); --  Coefficients of Sigma(X)
      sigma_x(0)     <= std_logic_vector(to_unsigned(1, g_GF_POWER)); --  Coefficients of Sigma(X)
      B_x            <= (others => (others => '0')); --  Backup Coeff. of Sigma(X)
      B_x(0)         <= std_logic_vector(to_unsigned(1, g_GF_POWER));
      T_x            <= (others => (others => '0'));
      syndrome       <= (others => (others => '0')); --  Latched Syndrome Value
      d              <= (others => '0');
      b              <= std_logic_vector(to_unsigned(1, g_GF_POWER)); --  Latest Non-zero d
      c              <= (others => '0');
      n              <= 0; --  External Loop Index, 0 to 2t - 1
      m              <= 1; --  Latest step since L updated
      L              <= 0; --  Current Degree of Sigma(X)
      i              <= 0;
      k              <= 0;
      r_sigma_valid  <= '0';
      r_MULT_A       <= (others => '0');
      r_MULT_B       <= (others => '0');
      r_MULT_A_valid <= '0';
      r_MULT_B_valid <= '0';
      r_DIV_A        <= (others => '0');
      r_DIV_B        <= (others => '0');
      r_DIV_A_valid  <= '0';
      r_DIV_B_valid  <= '0';
    elsif (rising_edge(i_clk)) then

      r_sigma_valid  <= '0';
      r_MULT_A       <= (others => '0');
      r_MULT_B       <= (others => '0');
      r_MULT_A_valid <= '0';
      r_MULT_B_valid <= '0';
      r_DIV_A        <= (others => '0');
      r_DIV_B        <= (others => '0');
      r_DIV_A_valid  <= '0';
      r_DIV_B_valid  <= '0';

      case present_state is
        when IDLE =>
          if (i_syndrome_valid = '1') then
            present_state <= CAL_D_START;
            syndrome      <= i_syndrome; --  Latched Syndrome Value
            sigma_x       <= (others => ((others => '0'))); --  Coefficients of Sigma(X)
            sigma_x(0)    <= std_logic_vector(to_unsigned(1, g_GF_POWER)); --  Sigma(X) = 1
            B_x           <= (others => (others => '0')); --  Backup Coeff. of Sigma(X)
            B_x(0)        <= std_logic_vector(to_unsigned(1, g_GF_POWER)); --  B(X) = 1
            T_x           <= (others => (others => '0')); --  T(X) = 0
            d             <= (others => '0'); --  Latest Discrepancy = 0
            b             <= std_logic_vector(to_unsigned(1, g_GF_POWER)); --  Latest Non-zero = 1
            c             <= (others => '0'); --  d/b
            n             <= 0; --  External Loop Index, 0 to 2t - 1
            m             <= 1; --  Latest step since L updated
            L             <= 0; --  Current Degree of Sigma(X)
            i             <= 0; --  CAL_D loop
            k             <= 0; --  COEFF Update loop
          end if;

        when CAL_D_START =>
          d             <= syndrome(n);
          i             <= 1;
          present_state <= CAL_D_CHECK_LOOP;

        when CAL_D_CHECK_LOOP =>
          if (i <= L and i <= n) then
            present_state  <= CAL_D_WAIT_MULT;
            r_MULT_A       <= sigma_x(i);
            r_MULT_B       <= syndrome(n - i);
            r_MULT_A_valid <= '1';
            r_MULT_B_valid <= '1';
          else
            present_state <= COEFF_DETERMINE;
          end if;

        when CAL_D_WAIT_MULT =>
          if (w_MULT_P_valid = '1') then
            present_state <= CAL_D_CHECK_LOOP;
            d             <= d xor w_MULT_P;
            i             <= i + 1;
          end if;

        when COEFF_DETERMINE =>
          if (to_integer(unsigned(d)) /= 0) then
            present_state <= COEFF_WAIT_DIV;
            T_x           <= sigma_x;
            r_DIV_A       <= d;
            r_DIV_B       <= b;
            r_DIV_A_valid <= '1';
            r_DIV_B_valid <= '1';
          else
            present_state <= STATE_UPDATE;
          end if;

        when COEFF_WAIT_DIV =>
          if (w_DIV_Q_valid = '1') then
            present_state <= COEFF_CHECK_LOOP;
            k             <= 0;
            c             <= w_DIV_Q;
          end if;

        when COEFF_CHECK_LOOP =>
          if (k > c_MAX_DEG) then
            present_state <= STATE_UPDATE;
          else
            if (k >= m) then
              present_state  <= COEFF_WAIT_MULT;
              r_MULT_A       <= c;
              r_MULT_B       <= B_x(k - m);
              r_MULT_A_valid <= '1';
              r_MULT_B_valid <= '1';
            else
              k <= k + 1;
            end if;
          end if;

        when COEFF_WAIT_MULT =>
          if (w_MULT_P_valid = '1') then
            present_state <= COEFF_CHECK_LOOP;
            sigma_x(k)    <= sigma_x(k) xor w_MULT_P;
            k             <= k + 1;
          end if;

        when STATE_UPDATE =>
          present_state <= STEP_UPDATE;
          if (to_integer(unsigned(d)) = 0) then
            m <= m + 1;
          else
            if (2 * L <= n) then
              L         <= n + 1 - L;
              B_x       <= T_x;
              b         <= d;
              m         <= 1;
            else
              m <= m + 1;
            end if;
          end if;

        when STEP_UPDATE =>
          if (n >= 2 * g_ERR_CORRECTION_CAPACITY - 1) then
            present_state <= DONE;
          else
            present_state <= CAL_D_START;
            n             <= n + 1;
            i             <= 0;
            d             <= (others => '0');
          end if;

        when DONE =>
          present_state <= IDLE;
          r_sigma_valid <= '1';

        when others =>
          present_state <= IDLE;

      end case;
    end if;
  end process; -- STATE_TRANSITION

end Behavioral;
