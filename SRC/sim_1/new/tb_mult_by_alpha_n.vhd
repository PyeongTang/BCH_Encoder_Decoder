----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/29 22:08:14
-- Design Name: 
-- Module Name: tb_mult_by_alpha_n - Behavioral
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

entity tb_mult_by_alpha_n is
  --  Port ( );
end tb_mult_by_alpha_n;

architecture Behavioral of tb_mult_by_alpha_n is
  component mult_by_alpha_n is
    generic (
      g_DATA_WIDTH  : integer := 3;
      g_ALPHA_POWER : integer := 2
    );
    port (
      i_primitive_poly : in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
      i_data           : in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
      o_data           : out std_logic_vector(g_DATA_WIDTH - 1 downto 0)
    );
  end component;

  constant c_DATA_WIDTH  : integer := 3;
  constant c_ALPHA_POWER : integer := 1;

  signal i_clk        : std_logic := '0';
  signal t_clk_period : time      := 10 ns;
  signal RESET_DONE   : std_logic := '0';

  signal i_primitive_poly : std_logic_vector(c_DATA_WIDTH - 1 downto 0) := (others => '0');
  signal i_data           : std_logic_vector(c_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal o_data : std_logic_vector(c_DATA_WIDTH - 1 downto 0);
begin

  TOGGLE_CLK : process
  begin
    i_clk <= not i_clk;
    wait for t_clk_period;
  end process; -- TOGGLE_CLK

  i_primitive_poly <= "011";

  mult_by_alpha_n_inst : mult_by_alpha_n
  generic map(
    g_DATA_WIDTH  => c_DATA_WIDTH,
    g_ALPHA_POWER => c_ALPHA_POWER
  )
  port map
  (
    i_primitive_poly => i_primitive_poly,
    i_data           => i_data,
    o_data           => o_data
  );

  DATA_INPUT : process
  begin
    wait until rising_edge(i_clk);
    i_data <= "001";
    wait until rising_edge(i_clk);
    i_data <= "010";
    wait until rising_edge(i_clk);
    i_data <= "100";
    wait until rising_edge(i_clk);
    i_data <= "011";
    wait until rising_edge(i_clk);
    i_data <= "110";
    wait until rising_edge(i_clk);
    i_data <= "111";
    wait until rising_edge(i_clk);
    i_data <= "101";
    wait until rising_edge(i_clk);
    i_data <= "001";
    -- wait until rising_edge(i_clk);
    -- i_data <= "010";
    -- wait until rising_edge(i_clk);
    wait;
  end process; -- DATA_INPUT

end Behavioral;
