----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/12/05 23:49:02
-- Design Name: 
-- Module Name: LFSR - Behavioral
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
-- LFSR (Linear Feedback Shift Register) is a shift register whose feedback loop, xor wiring with generative polynomial
-- For Feedback Looping, LFSR results a remainder with divisor (generative polynomial), after g_CODEWORD_LENGTH clk
-- g_GENERATIVE_POLY in generic indicates LSB : Lowest Degree (Constant), MSB : Highest Degree (X^(MAX_DEGREE_POLY))
-- =========================================================================================================================

entity LFSR is
  generic (
    g_CODEWORD_WIDTH  : integer                                      := 7;
    g_MAX_DEGREE_POLY : integer                                      := 3;
    g_GENERATIVE_POLY : std_logic_vector(g_MAX_DEGREE_POLY downto 0) := (others => '0')
  );
  port (
    i_clk     : in std_logic;
    i_n_reset : in std_logic;
    i_data    : in std_logic;
    i_valid   : in std_logic;
    o_data    : out std_logic_vector(g_MAX_DEGREE_POLY - 1 downto 0);
    o_valid   : out std_logic
  );
end LFSR;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of LFSR is

  ---------------------------------------------------------------------------
  -- Constants
  ---------------------------------------------------------------------------

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal r_shift_register : std_logic_vector(g_MAX_DEGREE_POLY - 1 downto 0) := (others => '0');
  signal r_valid          : std_logic                                        := '0';
  signal r_count          : integer                                          := 0;

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------

begin

  o_data  <= r_shift_register;
  o_valid <= r_valid;

  ---------------------------------------------------------------------------
  -- Porcess
  ---------------------------------------------------------------------------

  LFSR : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_count          <= 0;
      r_valid          <= '0';
      r_shift_register <= (others => '0');
    elsif (rising_edge(i_clk)) then
      if (r_valid = '0') then
        if (i_valid = '1') then
          r_shift_register(0) <= r_shift_register(g_MAX_DEGREE_POLY - 1) xor i_data; -- MSB to Constant Feedback
          for i in 1 to g_MAX_DEGREE_POLY - 1 loop -- Inner Shifting
            if g_GENERATIVE_POLY(i) = '1' then
              r_shift_register(i) <= r_shift_register(i - 1) xor r_shift_register(g_MAX_DEGREE_POLY - 1);
            else
              r_shift_register(i) <= r_shift_register(i - 1);
            end if;
          end loop;
          if (r_count >= g_CODEWORD_WIDTH - 1) then
            r_count <= 0;
            r_valid <= '1';
          else
            r_count <= r_count + 1;
          end if;
        end if;
      else
        r_shift_register <= (others => '0');
        r_valid          <= '0';
      end if;
    end if;
  end process; -- LFSR

end Behavioral;
