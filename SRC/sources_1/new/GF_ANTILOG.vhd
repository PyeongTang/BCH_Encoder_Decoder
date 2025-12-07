----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/30 12:28:21
-- Design Name: 
-- Module Name: GF_ANTILOG - Behavioral
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

entity GF_ANTILOG is
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
end GF_ANTILOG;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of GF_ANTILOG is

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------
  signal r_index        : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal w_exponent_int : integer                                   := 0;
  signal r_valid        : std_logic                                 := '0';

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------
begin

  w_exponent_int <= to_integer(unsigned(i_exponent));
  o_index        <= r_index;
  o_valid        <= r_valid;

  ---------------------------------------------------------------------------
  -- Porcess
  ---------------------------------------------------------------------------

  GF_ANTILOG_TABLE : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_index <= (others => '0');
      r_valid <= '0';
    elsif (rising_edge(i_clk)) then
      if (i_valid = '1') then
        case w_exponent_int is --                 Exponent        Index
          when 0      => r_index  <= "0001"; --   alpha^0       = 1
          when 1      => r_index  <= "0010"; --   alpha^1       = alpha
          when 2      => r_index  <= "0100"; --   alpha^2       = alpha^2
          when 3      => r_index  <= "1000"; --   alpha^3       = alpha^3
          when 4      => r_index  <= "0011"; --   alpha^4       = alpha + 1
          when 5      => r_index  <= "0110"; --   alpha^5       = alpha^2 + alpha
          when 6      => r_index  <= "1100"; --   alpha^6       = alpha^3 + alpha^2
          when 7      => r_index  <= "1011"; --   alpha^7       = alpha^3 + alpha + 1
          when 8      => r_index  <= "0101"; --   alpha^8       = alpha^2 + 1
          when 9      => r_index  <= "1010"; --   alpha^9       = alpha^3 + alpha
          when 10     => r_index <= "0111"; --    alpha^10      = alpha^2 + alpha + 1
          when 11     => r_index <= "1110"; --    alpha^11      = alpha^3 + alpha^2 + alpha
          when 12     => r_index <= "1111"; --    alpha^12      = alpha^3 + alpha^2 + alpha + 1
          when 13     => r_index <= "1101"; --    alpha^13      = alpha^3 + alpha^2 + 1
          when 14     => r_index <= "1001"; --    alpha^14      = alpha^3 + 1
          when 15     => r_index <= "0001"; --    wrap-around to 1
          when others =>
            null;
        end case;
        r_valid <= '1';
      else
        r_index <= (others => '0');
        r_valid <= '0';
      end if;
    end if;
  end process; -- GF_ANTILOG_TABLE
end Behavioral;
