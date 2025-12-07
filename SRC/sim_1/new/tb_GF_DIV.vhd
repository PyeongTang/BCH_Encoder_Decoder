----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/30 13:31:10
-- Design Name: 
-- Module Name: tb_GF_DIV - Behavioral
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

entity tb_GF_DIV is
  --  Port ( );
end tb_GF_DIV;

architecture Behavioral of tb_GF_DIV is

  component GF_DIV is
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
      o_Q       : out std_logic_vector(g_GF_POWER - 1 downto 0);
      o_Q_valid : out std_logic
    );
  end component;

  constant c_GF_POWER : integer := 3;

  signal t_clk_period : time      := 10 ns;
  signal RESET_DONE   : std_logic := '0';

  signal i_clk     : std_logic                                 := '0';
  signal i_n_reset : std_logic                                 := '1';
  signal i_A       : std_logic_vector(c_GF_POWER - 1 downto 0) := (others => '0');
  signal i_A_valid : std_logic                                 := '0';
  signal i_B       : std_logic_vector(c_GF_POWER - 1 downto 0) := (others => '0');
  signal i_B_valid : std_logic                                 := '0';
  signal o_Q       : std_logic_vector(c_GF_POWER - 1 downto 0);
  signal o_Q_valid : std_logic;

begin

  GF_DIV_inst : GF_DIV
  generic map(
    g_GF_POWER => C_GF_POWER
  )
  port map
  (
    i_clk     => i_clk,
    i_n_reset => i_n_reset,
    i_A       => i_A,
    i_A_valid => i_A_valid,
    i_B       => i_B,
    i_B_valid => i_B_valid,
    o_Q       => o_Q,
    o_Q_valid => o_Q_valid
  );

  TOGGLE_CLK : process
  begin
    i_clk <= not i_clk;
    wait for t_clk_period;
  end process; -- TOGGLE_CLK

  ASSERT_RESET : process
  begin
    wait for 7 ns;
    i_n_reset <= '1';
    wait for 7 ns;
    i_n_reset <= '0';
    wait for 7 ns;
    i_n_reset <= '1';
    wait for 7 ns;
    RESET_DONE <= '1';
    wait;
  end process; -- ASSERT_RESET

  DATA_INPUT : process
  begin
    wait until RESET_DONE = '1';
    wait until rising_edge(i_clk);
    i_A       <= "111"; -- a2 + a1 + 1
    i_A_valid <= '1';
    i_B       <= "100"; -- a2
    i_B_valid <= '1';
    wait;
  end process; -- DATA_INPUT

end Behavioral;
