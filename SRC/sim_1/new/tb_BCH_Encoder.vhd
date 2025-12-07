----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/12/06 12:49:25
-- Design Name: 
-- Module Name: tb_BCH_Encoder - Behavioral
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

use std.textio.all;
use ieee.std_logic_textio.all;
use std.env.all;

entity tb_BCH_Encoder is
  --  Port ( );
end tb_BCH_Encoder;

architecture Behavioral of tb_BCH_Encoder is

  component BCH_Encoder is
    generic (
      g_CODEWORD_WIDTH  : integer                                   := 7;
      g_PARITY_WIDTH    : integer                                   := 3;
      g_GENERATIVE_POLY : std_logic_vector(g_PARITY_WIDTH downto 0) := (others => '0')
    );
    port (
      i_clk     : in std_logic;
      i_n_reset : in std_logic;
      i_data    : in std_logic_vector((g_CODEWORD_WIDTH - g_PARITY_WIDTH) - 1 downto 0); -- Message
      i_valid   : in std_logic;
      o_ready   : out std_logic;
      o_data    : out std_logic_vector(g_CODEWORD_WIDTH - 1 downto 0); -- Codeword
      o_valid   : out std_logic
    );
  end component;

  ---------------------------------------------------------------------------
  -- Constants
  ---------------------------------------------------------------------------

  constant c_CODEWORD_WIDTH : integer := 15;
  constant c_PARITY_WIDTH   : integer := 10;
  constant c_MESSAGE_WIDTH  : integer := c_CODEWORD_WIDTH - c_PARITY_WIDTH;

  constant c_GENERATIVE_POLY : std_logic_vector(c_PARITY_WIDTH downto 0) := "10100110111";
  --   constant c_MESSAGE         : std_logic_vector(c_MESSAGE_WIDTH - 1 downto 0) := "0000";
  constant c_MESSAGE : integer := 0;
  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal t_clk_period : time      := 5 ns;
  signal RESET_DONE   : std_logic := '0';

  signal i_clk     : std_logic := '0';
  signal i_n_reset : std_logic := '1';

  signal i_data  : std_logic_vector((c_CODEWORD_WIDTH - c_PARITY_WIDTH) - 1 downto 0) := (others => '0'); -- Message
  signal i_valid : std_logic                                                          := '0';

  signal o_data  : std_logic_vector(c_CODEWORD_WIDTH - 1 downto 0); -- Codeword
  signal o_valid : std_logic;
  signal o_ready : std_logic;

  --   File
  file BCH_ENCODED_TXT : text open write_mode is "BCH_ENCODED.txt";
begin

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------

  ---------------------------------------------------------------------------
  -- Instances
  ---------------------------------------------------------------------------

  BCH_Encoder_inst : BCH_Encoder
  generic map(
    g_CODEWORD_WIDTH  => c_CODEWORD_WIDTH,
    g_PARITY_WIDTH    => c_PARITY_WIDTH,
    g_GENERATIVE_POLY => c_GENERATIVE_POLY
  )
  port map
  (
    i_clk     => i_clk,
    i_n_reset => i_n_reset,
    i_data    => i_data,
    i_valid   => i_valid,
    o_ready   => o_ready,
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
    for i in 0 to 2 ** c_MESSAGE_WIDTH - 1 loop
      i_data  <= std_logic_vector(TO_UNSIGNED(c_MESSAGE + i, c_MESSAGE_WIDTH));
      i_valid <= '1';
      wait until rising_edge(i_clk);

      i_valid <= '0';

      wait until o_ready = '1';
    end loop;
    stop;
  end process; -- DATA_INPUT

  capture_process : process (i_clk)
    variable l : line;
  begin
    if (rising_edge(i_clk)) then
      if (o_valid = '1') then
        hwrite(l, o_data);
        writeline(BCH_ENCODED_TXT, l);
      end if;
    end if;
  end process; -- capture_process

end Behavioral;
