----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/29 21:32:24
-- Design Name: 
-- Module Name: mult_by_alpha - Behavioral
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
-- Multiply element in GF(2^m) by alpha (primitive element) can be implemented by
-- alpha * a(x) = X * a(x) mod p(x)
-- where a(x) is input data, p(x) is primitive polynomial
-- multiplying X equals to shift left
-- if MSB = '1', need to reduct order, low orders of p(x) (except of MSB, highest order) xor-ed to shifted data (mod p(x))
-- =========================================================================================================================

entity mult_by_alpha is
  generic (
    g_GF_POWER : integer := 3
  );
  port (
    i_primitive_poly : in std_logic_vector(g_GF_POWER downto 0);
    i_data           : in std_logic_vector(g_GF_POWER - 1 downto 0);
    o_data           : out std_logic_vector(g_GF_POWER - 1 downto 0)
  );
end mult_by_alpha;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of mult_by_alpha is

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------
  signal r_mask    : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal r_shifted : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------
begin
  
  r_shifted <= std_logic_vector(SHIFT_LEFT(unsigned(i_data), 1));
  r_mask <= i_primitive_poly(g_GF_POWER - 1 downto 0);
  o_data    <= (r_shifted xor r_mask) when i_data(g_GF_POWER - 1) = '1' else
    r_shifted;

end Behavioral;
