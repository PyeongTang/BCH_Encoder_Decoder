----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/29 22:35:54
-- Design Name: 
-- Module Name: Syndrome_Calculator - Behavioral
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
-- Syndrome S_i = r(alpha_i) = (r_0) + (r_1 * alpha_i) + (r_i * alpha_i^2) + ... + (r_n-1 * alpha_i^(n-1))
-- Can be Implemented by accumulation, 
--    S_i(k + 1) = alpha^i * S_i(k) + r_k
-- where  i = index of syndrome (number of syndromes), 0 to 2t (t = error correction capacity)
--        k = index of polynomial (number of term in polynomial, equivalent to codeword length), 0 to n-1
-- 
-- Every clock with received data valid, S_i(k + 1) evaluated with r_k, which going to xor-ed with syndrome that multiplied by alpha (S_i(k))
-- Index i indicates syndromes,
--    S(x) = S_0 + S_1 * x + S_2 * x^2 + ... + S_2t-1 * x^(2t - 1) = Summation of S_k * x ^ (k), k goes to 0 upto 2t - 1
-- =========================================================================================================================

entity Syndrome_Calculator is
  generic (
    g_GF_POWER                  : integer := 3;
    g_ALPHA_POWER               : integer := 1
  );
  port (
    i_clk            : in std_logic;
    i_n_reset        : in std_logic;
    i_primitive_poly : in std_logic_vector(g_GF_POWER downto 0);
    i_data           : in std_logic;
    i_valid          : in std_logic;
    o_syndrome       : out std_logic_vector(g_GF_POWER - 1 downto 0);
    o_syndrome_valid : out std_logic
  );
end Syndrome_Calculator;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of Syndrome_Calculator is

  ---------------------------------------------------------------------------
  -- Component
  ---------------------------------------------------------------------------

  component mult_by_alpha_n is
    generic (
      g_GF_POWER    : integer := 3;
      g_ALPHA_POWER : integer := 2
    );
    port (
      i_primitive_poly : in std_logic_vector(g_GF_POWER downto 0);
      i_data           : in std_logic_vector(g_GF_POWER - 1 downto 0);
      o_data           : out std_logic_vector(g_GF_POWER - 1 downto 0)
    );
  end component;

  ---------------------------------------------------------------------------
  -- Constants
  ---------------------------------------------------------------------------

  constant c_CODEWORD_LENGTH : integer := 2 ** g_GF_POWER - 1;

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal r_syndrome            : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal r_syndrome_mult_alpha : std_logic_vector(g_GF_POWER - 1 downto 0);
  signal r_syndrome_valid      : std_logic                                 := '0';
  signal r_syndrome_valid_z : std_logic := '0';
  signal w_received_bit        : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');

  signal r_count : integer := 0;

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------

begin

  o_syndrome        <= r_syndrome;
  o_syndrome_valid  <= r_syndrome_valid;
  w_received_bit(0) <= i_data;

  ---------------------------------------------------------------------------
  -- Instances
  ---------------------------------------------------------------------------

  MULT_ALPHA_N : mult_by_alpha_n
  generic map(
    g_GF_POWER    => g_GF_POWER,
    g_ALPHA_POWER => g_ALPHA_POWER
  )
  port map
  (
    i_primitive_poly => i_primitive_poly,
    i_data           => r_syndrome,
    o_data           => r_syndrome_mult_alpha
  );

  ---------------------------------------------------------------------------
  -- Processes
  ---------------------------------------------------------------------------

  DELAY_SYNDROME_VALID : process( i_clk, i_n_reset )
  begin
    if (i_n_reset = '0') then
      r_syndrome_valid_z <= '0';
    elsif (rising_edge(i_clk)) then
      r_syndrome_valid_z <= r_syndrome_valid;
    end if;
  end process ; -- DELAY_SYNDROME_VALID

  COUNT_CODEWORD : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_count          <= 0;
      r_syndrome_valid <= '0';
    elsif (rising_edge(i_clk)) then
      r_syndrome_valid <= '0';
      if (i_valid = '1') then
        if (r_count >= c_CODEWORD_LENGTH - 1) then
          r_count          <= 0;
          r_syndrome_valid <= '1';
        else
          r_count          <= r_count + 1;
          r_syndrome_valid <= '0';
        end if;
      end if;
    end if;
  end process; -- COUNT_CODEWORD

  ACCUMULATE_SYNDROME : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_syndrome <= (others => '0');
    elsif (rising_edge(i_clk)) then
      if (i_valid = '1') then
        r_syndrome <= r_syndrome_mult_alpha xor w_received_bit;
      elsif (r_syndrome_valid_z = '1') then
        r_syndrome <= (others => '0');
      end if;
    end if;

  end process; -- ACCUMULATE_SYNDROME

end Behavioral;
