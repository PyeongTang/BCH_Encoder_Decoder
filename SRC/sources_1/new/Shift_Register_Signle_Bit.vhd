----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/12/02 21:29:31
-- Design Name: 
-- Module Name: Shift_Register_Signle_Bit - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Shift_Register_Signle_Bit is
  generic (
    g_INPUT_DATA_WIDTH : integer := 8
  );
  port (
    i_clk     : in std_logic;
    i_n_reset : in std_logic;
    i_data    : in std_logic_vector(g_INPUT_DATA_WIDTH - 1 downto 0);
    i_valid   : in std_logic;
    o_data    : out std_logic;
    o_valid   : out std_logic;
    o_ready   : out std_logic
  );
end Shift_Register_Signle_Bit;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of Shift_Register_Signle_Bit is

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal r_shift_register : std_logic_vector(g_INPUT_DATA_WIDTH - 1 downto 0) := (others => '0');

  signal r_valid : std_logic := '0';
  signal r_ready : std_logic := '0';

  signal r_count_enable : std_logic := '0';
  signal r_count        : integer   := 0;
  signal r_count_done   : std_logic := '0';

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------

begin

  o_data  <= r_shift_register(g_INPUT_DATA_WIDTH - 1);
  o_valid <= r_count_enable and not r_count_done;
  o_ready <= r_ready;

  ---------------------------------------------------------------------------
  -- Porcess
  ---------------------------------------------------------------------------

  INPUT_DATA_LATCH : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_count_enable   <= '0';
      r_ready          <= '1';
      r_shift_register <= (others => '0');
    elsif (rising_edge(i_clk)) then
      if (i_valid = '1') then
        r_shift_register <= i_data;
        r_count_enable   <= '1';
        r_ready          <= '0';
      elsif (r_count_done = '1') then
        r_ready        <= '1';
        r_count_enable <= '0';
      elsif (r_count_enable = '1') then
        r_shift_register <= r_shift_register(g_INPUT_DATA_WIDTH - 2 downto 0) & '0';
      end if;
    end if;
  end process; -- INPUT_DATA_LATCH

  COUNT_BIT : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_count      <= g_INPUT_DATA_WIDTH - 1;
      r_count_done <= '0';
      r_valid      <= '0';
    elsif (rising_edge(i_clk)) then
      r_valid      <= '0';
      r_count_done <= '0';
      if (r_count_enable = '1' and r_count_done = '0') then
        r_count_done <= '0';
        if (r_count  <= 0) then
          r_count      <= g_INPUT_DATA_WIDTH - 1;
          r_count_done <= '1';
        else
          r_count <= r_count - 1;
          r_valid <= '1';
        end if;
      end if;
    end if;
  end process; -- COUNT_BIT
end Behavioral;
