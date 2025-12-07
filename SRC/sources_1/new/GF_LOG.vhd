----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/30 12:18:50
-- Design Name: 
-- Module Name: GF_LOG - Behavioral
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

entity GF_LOG is
  generic (
    g_GF_POWER : integer := 3
  );
  port (
    i_clk      : in std_logic;
    i_n_reset  : in std_logic;
    i_index    : in std_logic_vector(g_GF_POWER - 1 downto 0);
    i_valid    : in std_logic;
    o_exponent : out std_logic_vector(g_GF_POWER - 1 downto 0);
    o_valid    : out std_logic
  );
end GF_LOG;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of GF_LOG is

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal r_exponent  : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal w_index_int : integer                                   := 0;
  signal r_valid     : std_logic                                 := '0';

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------

begin

  w_index_int <= to_integer(unsigned(i_index));
  o_exponent  <= r_exponent;
  o_valid     <= r_valid;

  ---------------------------------------------------------------------------
  -- Porcess
  ---------------------------------------------------------------------------

  GF_LOG_TABLE : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_exponent <= (others => '1');
      r_valid    <= '0';
    elsif (rising_edge(i_clk)) then
      if (i_valid = '1') then
        case w_index_int is --                       Index                                Exponent
          when 0      => r_exponent  <= "1111"; --   UNDEFINED                        =   All One's
          when 1      => r_exponent  <= "0000"; --   1                       (0001)   =   alpha^0
          when 2      => r_exponent  <= "0001"; --   alpha                   (0010)   =   alpha^1
          when 3      => r_exponent  <= "0100"; --   alpha+1                 (0011)   =   alpha^4
          when 4      => r_exponent  <= "0010"; --   alpha^2                 (0100)   =   alpha^2
          when 5      => r_exponent  <= "1000"; --   alpha^2+1               (0101)   =   alpha^8
          when 6      => r_exponent  <= "0101"; --   alpha^2+alpha           (0110)   =   alpha^5
          when 7      => r_exponent  <= "1010"; --   alpha^2+alpha+1         (0111)   =   alpha^10
          when 8      => r_exponent  <= "0011"; --   alpha^3                 (1000)   =   alpha^3
          when 9      => r_exponent  <= "1110"; --   alpha^3+1               (1001)   =   alpha^14
          when 10     => r_exponent <= "1001"; --    alpha^3+alpha           (1010)   =   alpha^9
          when 11     => r_exponent <= "0111"; --    alpha^3+alpha+1         (1011)   =   alpha^7
          when 12     => r_exponent <= "0110"; --    alpha^3+alpha^2         (1100)   =   alpha^6
          when 13     => r_exponent <= "1101"; --    alpha^3+alpha^2+1       (1101)   =   alpha^13
          when 14     => r_exponent <= "1011"; --    alpha^3+alpha^2+alpha   (1110)   =   alpha^11
          when 15     => r_exponent <= "1100"; --    alpha^3+alpha^2+alpha+1 (1111)   =   alpha^12
          when others =>
            null;
        end case;
        r_valid <= '1';
      else
        r_exponent <= (others => '1');
        r_valid    <= '0';
      end if;
    end if;
  end process; -- GF_LOG_TABLE

end Behavioral;
