----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/12/01 23:27:27
-- Design Name: 
-- Module Name: tb_Chien_Horner_Solver - Behavioral
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

entity tb_Chien_Horner_Solver is
  --  Port ( );
end tb_Chien_Horner_Solver;

architecture Behavioral of tb_Chien_Horner_Solver is

  component Chien_Horner_Solver is
    generic (
      g_GF_POWER                : integer := 3;
      g_ERR_CORRECTION_CAPACITY : integer := 2;
      g_ALPHA_INVERSE_EXPONENT  : integer := 6
    );
    port (
      i_clk                      : in std_logic;
      i_n_reset                  : in std_logic;
      i_sigma                    : in t_array_slv3(g_ERR_CORRECTION_CAPACITY downto 0);
      i_sigma_valid              : in std_logic;
      o_error_bit_position       : out std_logic_vector(2 ** g_GF_POWER - 1 downto 0);
      o_error_bit_position_valid : out std_logic
    );
  end component;

  constant  c_GF_POWER                : integer := 3;
  constant  c_ERR_CORRECTION_CAPACITY : integer := 2;
  constant  c_ALPHA_INVERSE_EXPONENT  : integer := 6;

  signal t_clk_period : time      := 10 ns;
  signal RESET_DONE   : std_logic := '0';

  signal i_clk     : std_logic := '0';
  signal i_n_reset : std_logic := '1';
  signal i_sigma                    :  t_array_slv3(c_ERR_CORRECTION_CAPACITY downto 0) := (others => (others => '0') ) ;
  signal i_sigma_valid              :  std_logic := '0';
  signal o_error_bit_position       :  std_logic_vector(2 ** c_GF_POWER - 1 downto 0);
  signal o_error_bit_position_valid :  std_logic;

begin

  Chien_Horner_Solver_inst : Chien_Horner_Solver
  generic map(
    g_GF_POWER                => c_GF_POWER,
    g_ERR_CORRECTION_CAPACITY => c_ERR_CORRECTION_CAPACITY,
    g_ALPHA_INVERSE_EXPONENT  => c_ALPHA_INVERSE_EXPONENT
  )
  port map
  (
    i_clk                      => i_clk,
    i_n_reset                  => i_n_reset,
    i_sigma                    => i_sigma,
    i_sigma_valid              => i_sigma_valid,
    o_error_bit_position       => o_error_bit_position,
    o_error_bit_position_valid => o_error_bit_position_valid
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
    -- wait until rising_edge(i_clk);
    -- -- Error Position i = 1, 4
    -- i_sigma <= (
    --     2 => "111", --  alpha^5
    --     1 => "100", --  alpha^2
    --     0 => "001"  --  1
    -- );
    -- i_sigma_valid <= '1';
    -- wait until rising_edge(i_clk);
    -- i_sigma_valid <= '0';
    -- wait;
    wait until rising_edge(i_clk);
    -- Error Position i = 0, 3
    i_sigma <= (
        2 => "011", --  alpha^3
        1 => "010", --  alpha^1
        0 => "001"  --  1
    );
    i_sigma_valid <= '1';
    wait until rising_edge(i_clk);
    i_sigma_valid <= '0';
    wait;
  end process; -- DATA_INPUT

end Behavioral;
