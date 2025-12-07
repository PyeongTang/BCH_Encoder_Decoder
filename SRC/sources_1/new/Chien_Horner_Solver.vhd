----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/12/01 22:35:09
-- Design Name: 
-- Module Name: Chien_Horner_Solver - Behavioral
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
-- Chien-Horner Solver implemented by FSM
-- For Given Sigma(x), Chien Search evaluates Sigma(x) on every alpha^-1
-- That is,
--  Evaluate Sigma(alpha^-i) on every i
--  if Sigma(alpha^-i) = 0, indicates that error occured on i-th position
-- For implementation on hardware, there is a Horner form of Chien Search algorithm
-- =========================================================================================================================

entity Chien_Horner_Solver is
  generic (
    g_GF_POWER                : integer := 3;
    g_ERR_CORRECTION_CAPACITY : integer := 2;
    g_ALPHA_INVERSE_EXPONENT  : integer := 6
  );
  port (
    i_clk                      : in std_logic;
    i_n_reset                  : in std_logic;
    i_sigma                    : in t_array_slv_n(0 to g_ERR_CORRECTION_CAPACITY)(g_GF_POWER - 1 downto 0);
    i_sigma_valid              : in std_logic;
    o_error_bit_position       : out std_logic_vector(2 ** g_GF_POWER - 1 - 1 downto 0);
    o_error_bit_position_valid : out std_logic
  );
end Chien_Horner_Solver;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of Chien_Horner_Solver is

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

  component GF_ANTILOG is
    generic (
      g_GF_POWER : integer := 3
    );
    port (
      i_clk      : in std_logic;
      i_n_reset  : in std_logic;
      i_exponent : in std_logic_vector(g_GF_POWER - 1 downto 0);
      i_valid    : in std_logic;
      o_index    : out std_logic_vector(g_GF_POWER - 1 downto 0);
      o_valid    : out std_logic
    );
  end component;

  ---------------------------------------------------------------------------
  -- Constants
  ---------------------------------------------------------------------------
  constant c_MAX_CODEWORD_LENGTH : integer := 2 ** g_GF_POWER - 1 - 1;
  constant c_K_MAX               : integer := g_ERR_CORRECTION_CAPACITY;

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  type t_state is (
    IDLE,
    HORNER_LOOP,
    ACC_LOOP,
    WAIT_ACC_MULT,
    ACC_DONE_CHECK,
    WAIT_POS_MULT,
    HORNER_DONE
  );

  signal present_state : t_state := IDLE;

  signal i                          : integer                                          := 0;
  signal k                          : integer                                          := 0;
  signal X                          : std_logic_vector(g_GF_POWER - 1 downto 0)        := (others => '0');
  signal r_sigma                    : t_array_slv_n(0 to g_ERR_CORRECTION_CAPACITY)(g_GF_POWER - 1 downto 0) := (others => (others => '0'));
  signal r_MULT_A                   : std_logic_vector(g_GF_POWER - 1 downto 0)        := (others => '0');
  signal r_MULT_B                   : std_logic_vector(g_GF_POWER - 1 downto 0)        := (others => '0');
  signal r_MULT_A_valid             : std_logic                                        := '0';
  signal r_MULT_B_valid             : std_logic                                        := '0';
  signal w_MULT_P                   : std_logic_vector(g_GF_POWER - 1 downto 0);
  signal w_MULT_P_valid             : std_logic;
  signal r_ACC                      : std_logic_vector(g_GF_POWER - 1 downto 0)      := (others => '0');
  signal r_error_bit_position       : std_logic_vector(2 ** g_GF_POWER - 1 - 1 downto 0) := (others => '0');
  signal r_error_bit_position_valid : std_logic                                      := '0';
  signal w_alpha_inverse            : std_logic_vector(g_GF_POWER - 1 downto 0);

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------
begin

  o_error_bit_position       <= r_error_bit_position;
  o_error_bit_position_valid <= r_error_bit_position_valid;

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
      i_B       => r_MULT_B,
      i_A_valid => r_MULT_A_valid,
      i_B_valid => r_MULT_B_valid,
      o_P       => w_MULT_P,
      o_P_valid => w_MULT_P_valid
  );

  GF_ANTILOG_inst : GF_ANTILOG
    generic map(
      g_GF_POWER => g_GF_POWER
    )
    port map
    (
      i_clk      => i_clk,
      i_n_reset  => i_n_reset,
      i_exponent => std_logic_vector(to_unsigned(g_ALPHA_INVERSE_EXPONENT, g_GF_POWER)),
      i_valid    => '1',
      o_index    => w_alpha_inverse,
      o_valid    => open
  );

  ---------------------------------------------------------------------------
  -- Process
  ---------------------------------------------------------------------------

  STATE_TRANSITION : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      present_state              <= IDLE;
      i                          <= 0;
      k                          <= 0;
      X                          <= (others => '0');
      r_MULT_A                   <= (others => '0');
      r_MULT_B                   <= (others => '0');
      r_MULT_A_valid             <= '0';
      r_MULT_B_valid             <= '0';
      r_ACC                      <= (others => '0');
      r_error_bit_position       <= (others => '0');
      r_error_bit_position_valid <= '0';
    elsif (rising_edge(i_clk)) then
      r_MULT_A_valid             <= '0';
      r_MULT_B_valid             <= '0';
      r_error_bit_position_valid <= '0';
      case present_state is
        when IDLE =>
          if (i_sigma_valid = '1') then
            present_state <= HORNER_LOOP;
            r_sigma       <= i_sigma;
            X(0)          <= '1';
            i             <= 0;
          end if;

        when HORNER_LOOP =>
          if (i >= c_MAX_CODEWORD_LENGTH) then
            present_state              <= HORNER_DONE;
            r_error_bit_position_valid <= '1';
          else
            present_state <= ACC_LOOP;
            r_ACC         <= r_sigma(c_K_MAX);
            k             <= c_K_MAX - 1;
          end if;

        when ACC_LOOP =>
          present_state  <= WAIT_ACC_MULT;
          r_MULT_A       <= r_ACC;
          r_MULT_B       <= X;
          r_MULT_A_valid <= '1';
          r_MULT_B_valid <= '1';

        when WAIT_ACC_MULT =>
          if (w_MULT_P_valid = '1') then
            present_state <= ACC_DONE_CHECK;
            r_ACC         <= w_MULT_P xor r_sigma(k);
          end if;

        when ACC_DONE_CHECK =>
          if (k > 0) then
            present_state <= ACC_LOOP;
            k             <= k - 1;
          else
            if (to_integer(unsigned(r_ACC)) = 0) then
              r_error_bit_position(i) <= '1';
            end if;
            present_state  <= WAIT_POS_MULT;
            r_MULT_A       <= X;
            r_MULT_B       <= w_alpha_inverse;
            r_MULT_A_valid <= '1';
            r_MULT_B_valid <= '1';
          end if;

        when WAIT_POS_MULT =>
          if (w_MULT_P_valid = '1') then
            present_state <= HORNER_LOOP;
            X             <= w_MULT_P;
            i             <= i + 1;
          end if;

        when HORNER_DONE =>
          present_state              <= IDLE;
          i                          <= 0;
          k                          <= 0;
          X                          <= (others => '0');
          r_MULT_A                   <= (others => '0');
          r_MULT_B                   <= (others => '0');
          r_MULT_A_valid             <= '0';
          r_MULT_B_valid             <= '0';
          r_ACC                      <= (others => '0');
          r_error_bit_position       <= (others => '0');
          r_error_bit_position_valid <= '0';
        when others =>
          null;
      end case;
    end if;
  end process; -- STATE_TRANSITION

end Behavioral;
