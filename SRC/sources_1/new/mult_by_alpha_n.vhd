----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/29 21:57:30
-- Design Name: 
-- Module Name: mult_by_alpha_n - Behavioral
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

-- =========================================================================================================================
-- Multiply element in GF(2^m) by alpha n-th power (primitive element) can be implemented by cascading mult_alpha blocks
-- =========================================================================================================================

entity mult_by_alpha_n is
  generic (
    g_GF_POWER  : integer := 3;
    g_ALPHA_POWER : integer := 2
  );
  port (
    i_primitive_poly : in std_logic_vector(g_GF_POWER downto 0);
    i_data           : in std_logic_vector(g_GF_POWER - 1 downto 0);
    o_data           : out std_logic_vector(g_GF_POWER - 1 downto 0)
  );
end mult_by_alpha_n;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of mult_by_alpha_n is

  ---------------------------------------------------------------------------
  -- Component
  ---------------------------------------------------------------------------
  component mult_by_alpha is
    generic (
      g_GF_POWER : integer := 3
    );
    port (
      i_primitive_poly : in std_logic_vector(g_GF_POWER downto 0);
      i_data           : in std_logic_vector(g_GF_POWER - 1 downto 0);
      o_data           : out std_logic_vector(g_GF_POWER - 1 downto 0)
    );
  end component;

  ---------------------------------------------------------------------------
  -- Signal
  ---------------------------------------------------------------------------

  signal w_data : std_logic_vector(g_GF_POWER * g_ALPHA_POWER - 1 downto 0) := (others => '0');

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------

begin

  o_data <= w_data(g_GF_POWER * g_ALPHA_POWER - 1 downto g_GF_POWER * g_ALPHA_POWER - g_GF_POWER);

  ---------------------------------------------------------------------------
  -- Instance
  ---------------------------------------------------------------------------

  mult_by_alpha_0 : mult_by_alpha
    generic map(
      g_GF_POWER => g_GF_POWER
    )
    port map
    (
      i_primitive_poly => i_primitive_poly,
      i_data           => i_data,
      o_data           => w_data(g_GF_POWER - 1 downto 0)
  );

  MULT_ALPHA_CHAIN : if (g_ALPHA_POWER > 1) generate
    GEN_LOOP : for i in 1 to (g_ALPHA_POWER - 1) generate
      i_mult_by_alpha : mult_by_alpha
      generic map(
        g_GF_POWER => g_GF_POWER
      )
      port map
      (
        i_primitive_poly => i_primitive_poly,
        i_data           => w_data(i * g_GF_POWER - 1 downto i * g_GF_POWER - g_GF_POWER),
        o_data           => w_data((i + 1) * g_GF_POWER - 1 downto (i + 1) * g_GF_POWER - g_GF_POWER)
      );
    end generate;
  end generate;

end Behavioral;
