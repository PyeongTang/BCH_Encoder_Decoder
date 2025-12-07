----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/30 00:45:53
-- Design Name: 
-- Module Name: Syndrome_Generator - Behavioral
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
-- Syndrome polynomial S(x) is 
--    S(x) = S_0 + S_1 * x + S_2 * x^2 + ... + S_2t-1 * x^(2t - 1) = Summation of S_k * x ^ (k), k goes to 0 upto 2t - 1
--    has it's size of
--      Width : GF_Power (m)
--      Depth : Number Of Syndrome Coefficient (2t - 1)
-- 
-- So each coefficient calculated in Syndrome_Calculator, which instantiated parallelly
-- =========================================================================================================================

entity Syndrome_Generator is
  generic (
    g_GF_POWER                  : integer := 3;
    g_ERR_CORRECTION_CAPACITY   : integer := 2
  );
  port (
    i_clk            : in std_logic;
    i_n_reset        : in std_logic;
    i_data           : in std_logic;
    i_valid          : in std_logic;
    i_primitive_poly : std_logic_vector(g_GF_POWER downto 0);
    o_syndrome       : out t_array_slv_n(0 to 2 * g_ERR_CORRECTION_CAPACITY - 1)(g_GF_POWER - 1 downto 0);
    o_syndrome_valid : out std_logic
  );
end Syndrome_Generator;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of Syndrome_Generator is

  ---------------------------------------------------------------------------
  -- Components
  ---------------------------------------------------------------------------

  component Syndrome_Calculator is
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
  end component;

  ---------------------------------------------------------------------------
  -- Constants
  ---------------------------------------------------------------------------

  constant c_NUM_SYNDROME : integer := 2 * g_ERR_CORRECTION_CAPACITY;

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal w_syndrome       : t_array_slv_n(0 to c_NUM_SYNDROME - 1)(g_GF_POWER - 1 downto 0);
  signal w_syndrome_valid : std_logic;

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------

begin

  o_syndrome       <= w_syndrome;
  o_syndrome_valid <= w_syndrome_valid;

  ---------------------------------------------------------------------------
  -- Instances
  ---------------------------------------------------------------------------

  SYNDROMES : for i in 1 to c_NUM_SYNDROME generate
    Syndrome_Calculator_inst : Syndrome_Calculator
    generic map(
      g_GF_POWER                  => g_GF_POWER,
      g_ALPHA_POWER               => i
    )
    port map
    (
      i_clk            => i_clk,
      i_n_reset        => i_n_reset,
      i_primitive_poly => i_primitive_poly,
      i_data           => i_data,
      i_valid          => i_valid,
      o_syndrome       => w_syndrome(i - 1),
      o_syndrome_valid => w_syndrome_valid
    );
  end generate; -- SYNDROMES

end Behavioral;
