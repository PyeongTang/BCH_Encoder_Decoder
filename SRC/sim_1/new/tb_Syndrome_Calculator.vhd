----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/29 23:05:46
-- Design Name: 
-- Module Name: tb_Syndrome_Calculator - Behavioral
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

entity tb_Syndrome_Calculator is
  --  Port ( );
end tb_Syndrome_Calculator;

architecture Behavioral of tb_Syndrome_Calculator is

  component Syndrome_Calculator is
    generic (
      g_DATA_WIDTH  : integer := 3;
      g_ALPHA_POWER : integer := 1
    );
    port (
      i_clk            : in std_logic;
      i_n_reset        : in std_logic;
      i_primitive_poly : in std_logic_vector(g_DATA_WIDTH - 1 downto 0);
      i_data           : in std_logic;
      i_valid          : in std_logic;
      o_syndrome       : out std_logic_vector(g_DATA_WIDTH - 1 downto 0);
      o_syndrome_valid : out std_logic
    );
  end component;

  constant c_DATA_WIDTH  : integer   := 3;
  constant c_ALPHA_POWER : integer   := 1;
  
  signal i_clk           : std_logic := '0';
  signal i_n_reset       : std_logic := '1';

  signal t_clk_period : time      := 10 ns;
  signal RESET_DONE   : std_logic := '0';

  signal i_primitive_poly : std_logic_vector(c_DATA_WIDTH - 1 downto 0) := (others => '0');
  signal i_data           : std_logic                                   := '0';
  signal i_valid          : std_logic                                   := '0';
  signal o_syndrome       : std_logic_vector(c_DATA_WIDTH - 1 downto 0);
  signal o_syndrome_valid : std_logic;

begin

  i_primitive_poly <= "011";

  Syndrome_Calculator_inst : Syndrome_Calculator
  generic map(
    g_DATA_WIDTH  => c_DATA_WIDTH,
    g_ALPHA_POWER => c_ALPHA_POWER
  )
  port map
  (
    i_clk            => i_clk,
    i_n_reset        => i_n_reset,
    i_primitive_poly => i_primitive_poly,
    i_data           => i_data,
    i_valid          => i_valid,
    o_syndrome       => o_syndrome,
    o_syndrome_valid => o_syndrome_valid
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
    i_valid <= '1';                 -- Order    Syndrome
    i_data  <= '0';                 -- 6        101
    wait until rising_edge(i_clk);
    i_data  <= '0';                 -- 5        111
    wait until rising_edge(i_clk);
    i_data  <= '1';                 -- 4        110
    wait until rising_edge(i_clk);
    i_data  <= '0';                 -- 3        011
    wait until rising_edge(i_clk);
    i_data  <= '1';                 -- 2        100
    wait until rising_edge(i_clk);
    i_data  <= '1';                 -- 1        010
    wait until rising_edge(i_clk);
    i_data  <= '0';                 -- 0        001
    wait until rising_edge(i_clk);
    i_valid <= '0';
    wait;
  end process; -- DATA_INPUT
end Behavioral;
