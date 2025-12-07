----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/12/06 00:58:19
-- Design Name: 
-- Module Name: tb_LFSR - Behavioral
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

entity tb_LFSR is
  --  Port ( );
end tb_LFSR;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of tb_LFSR is

  component LFSR is
    generic (
      g_CODEWORD_WIDTH  : integer                                          := 7;
      g_MAX_DEGREE_POLY : integer                                          := 3;
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
  end component;

  ---------------------------------------------------------------------------
  -- Constants
  ---------------------------------------------------------------------------

  constant c_CODEWORD_WIDTH  : integer                                          := 10;
  constant c_MAX_DEGREE_POLY : integer                                          := 6;
  constant c_GENERATIVE_POLY : std_logic_vector(c_MAX_DEGREE_POLY downto 0) := "1100101";
  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal t_clk_period : time      := 5 ns;
  signal RESET_DONE   : std_logic := '0';

  signal i_clk     : std_logic := '0';
  signal i_n_reset : std_logic := '1';

  signal i_data  : std_logic := '0';
  signal i_valid : std_logic := '0';

  signal o_data  : std_logic_vector(c_MAX_DEGREE_POLY - 1 downto 0);
  signal o_valid : std_logic;

begin

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------

  ---------------------------------------------------------------------------
  -- Instances
  ---------------------------------------------------------------------------

  LFSR_inst : LFSR
  generic map(
        g_CODEWORD_WIDTH  => c_CODEWORD_WIDTH,
        g_MAX_DEGREE_POLY => c_MAX_DEGREE_POLY,
        g_GENERATIVE_POLY => c_GENERATIVE_POLY
    )
    port map
    (
        i_clk     => i_clk,
        i_n_reset => i_n_reset,
        i_data    => i_data,
        i_valid   => i_valid,
        o_data    => o_data,
        o_valid   => o_valid
  );

  ---------------------------------------------------------------------------
  -- Porcess
  ---------------------------------------------------------------------------

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

    -- Message
    i_data <= '0'; i_valid <= '1'; wait until rising_edge(i_clk);
    i_data <= '0'; i_valid <= '1'; wait until rising_edge(i_clk);
    i_data <= '1'; i_valid <= '1'; wait until rising_edge(i_clk);
    i_data <= '1'; i_valid <= '1'; wait until rising_edge(i_clk);

    -- Shift for Parity
    for i in 1 to c_MAX_DEGREE_POLY loop
        i_data <= '0'; i_valid <= '1'; wait until rising_edge(i_clk);
    end loop;
    
    i_valid <= '0';
    wait;
  end process; -- DATA_INPUT

end Behavioral;
