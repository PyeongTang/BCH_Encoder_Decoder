----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/30 16:09:36
-- Design Name: 
-- Module Name: tb_BM_Solver - Behavioral
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

use work.my_types_pkg.all;

entity tb_BM_Solver is
  --  Port ( );
end tb_BM_Solver;

architecture Behavioral of tb_BM_Solver is

  component BM_Solver is
    generic (
      g_GF_POWER                : integer := 3;
      g_ERR_CORRECTION_CAPACITY : integer := 2
    );
    port (
      i_clk            : in std_logic;
      i_n_reset        : in std_logic;
      i_syndrome_valid : in std_logic;
      i_syndrome       : in t_array_slv3(2 * g_ERR_CORRECTION_CAPACITY - 1 downto 0);
      o_sigma          : out t_array_slv3(2 * g_ERR_CORRECTION_CAPACITY - 1 downto 0);
      o_sigma_valid    : out std_logic
    );
  end component;


  constant c_GF_POWER : integer := 3;
  constant c_ERR_CORRECTION_CAPACITY : integer := 2;

  signal t_clk_period : time      := 10 ns;
  signal RESET_DONE   : std_logic := '0';

  signal i_clk     : std_logic := '0';
  signal i_n_reset : std_logic := '1';
  signal i_syndrome_valid : std_logic := '0';signal i_syndrome : t_array_slv3(3 downto 0)
  := (
        3 => "100",  -- s3 = α²
        2 => "011",  -- s2 = α³
        1 => "010",  -- s1 = α¹
        0 => "001"   -- s0 = 1
     );
  signal o_sigma          : t_array_slv3(2 * c_ERR_CORRECTION_CAPACITY - 1 downto 0) := (others => (others => '0') ) ;
  signal o_sigma_valid    : std_logic;

begin

  BM_Solver_inst : BM_Solver
  generic map(
    g_GF_POWER                => c_GF_POWER,
    g_ERR_CORRECTION_CAPACITY => c_ERR_CORRECTION_CAPACITY
  )
  port map
  (
    i_clk            => i_clk,
    i_n_reset        => i_n_reset,
    i_syndrome_valid => i_syndrome_valid,
    i_syndrome       => i_syndrome,
    o_sigma          => o_sigma,
    o_sigma_valid    => o_sigma_valid
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
    -- i_syndrome <= (
    --     3 => "110",  -- s3 = α⁴
    --     2 => "010",  -- s2 = α¹
    --     1 => "111",  -- s1 = α⁵
    --     0 => "100"   -- s0 = α²
    -- );
    -- i_syndrome_valid <= '1';
    -- wait until rising_edge(i_clk);
    -- i_syndrome_valid <= '0';
    -- wait until o_sigma_valid = '1';

    -- wait until rising_edge(i_clk);
    -- i_syndrome <= (
    --     3 => "101",  -- s3 = α⁶
    --     2 => "100",  -- s2 = α²
    --     1 => "110",  -- s1 = α⁴
    --     0 => "001"   -- s0 = 1
    -- );
    -- i_syndrome_valid <= '1';
    -- wait until rising_edge(i_clk);
    -- i_syndrome_valid <= '0';
    -- wait until o_sigma_valid = '1';

    wait until rising_edge(i_clk);
    i_syndrome <= (
        3 => "111",  -- s3 = α⁵
        2 => "101",  -- s2 = α⁶
        1 => "011",  -- s1 = α³
        0 => "001"   -- s0 = α¹
    );
    i_syndrome_valid <= '1';
    wait until rising_edge(i_clk);
    i_syndrome_valid <= '0';
    wait until o_sigma_valid = '1';
    wait;
  end process; -- DATA_INPUT
end Behavioral;
