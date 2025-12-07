----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/12/02 22:29:22
-- Design Name: 
-- Module Name: tb_BCH_Decoder - Behavioral
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
use work.my_types_pkg.all;
use std.env.all;

entity tb_BCH_Decoder is
  --  Port ( );
end tb_BCH_Decoder;

architecture Behavioral of tb_BCH_Decoder is

  component BCH_Decoder is
    generic (
      g_GF_POWER                : integer := 4;
      g_CODEWORD_WIDTH          : integer := 15;
      g_MESSAGE_WIDTH           : integer := 7;
      g_PARITY_WIDTH            : integer := 8;
      g_ERR_CORRECTION_CAPACITY : integer := 2
    );
    port (
      i_clk                : in std_logic;
      i_n_reset            : in std_logic;
      i_primitive_poly     : in std_logic_vector(g_GF_POWER downto 0);
      i_encoded_data       : in std_logic_vector(g_CODEWORD_WIDTH - 1 downto 0);
      i_encoded_data_valid : in std_logic;
      o_decoded_data       : out std_logic_vector(g_MESSAGE_WIDTH - 1 downto 0);
      o_decoded_data_valid : out std_logic;
      o_decode_ready       : out std_logic
    );
  end component;

  constant c_GF_POWER : integer := 4;

  -- Primitive Polynomial used for expanding GF, not for generating codeword
  constant c_PRIMITIVE_POLY : std_logic_vector(c_GF_POWER downto 0) := "10011"; -- x4 + x + 1 

  constant c_CODEWORD_WIDTH : integer := 2 ** c_GF_POWER - 1;
  constant c_MESSAGE_WIDTH  : integer := 5;
  constant c_PARITY_WIDTH   : integer := c_CODEWORD_WIDTH - c_MESSAGE_WIDTH;

  constant c_ERR_CORRECTION_CAPACITY : integer := 3;
  constant c_POSITION_BIT_ERROR_1    : integer := 2;
  constant c_POSITION_BIT_ERROR_2    : integer := 7;

  -- constant c_MESSAGE_VECTOR : std_logic_vector(c_MESSAGE_WIDTH - 1 downto 0) := "0000001";
  -- constant c_PARITY_VECTOR  : std_logic_vector(c_PARITY_WIDTH - 1 downto 0)  := "11010001";

  signal t_clk_period : time      := 10 ns;
  signal RESET_DONE   : std_logic := '0';

  signal i_clk                : std_logic                                       := '0';
  signal i_n_reset            : std_logic                                       := '1';
  signal i_primitive_poly     : std_logic_vector(c_GF_POWER downto 0)           := c_PRIMITIVE_POLY;
  signal i_encoded_data       : std_logic_vector(c_CODEWORD_WIDTH - 1 downto 0) := (others => '0');
  signal i_encoded_data_valid : std_logic                                       := '0';
  signal o_decoded_data       : std_logic_vector(c_MESSAGE_WIDTH - 1 downto 0);
  signal o_decoded_data_valid : std_logic;
  signal o_decode_ready       : std_logic;

  signal r_message     : std_logic_vector(c_MESSAGE_WIDTH - 1 downto 0)  := (others => '0');
  signal r_parity      : std_logic_vector(c_PARITY_WIDTH - 1 downto 0)   := (others => '0');
  signal r_rx_codeword : std_logic_vector(c_CODEWORD_WIDTH - 1 downto 0) := (others => '0');
  signal r_error_bit   : std_logic_vector(c_CODEWORD_WIDTH - 1 downto 0) := (others => '0');

  --   File
  file BCH_ENCODED_TXT : text open read_mode is "BCH_ENCODED.txt";

  impure function read_hex_line(
    file f : text;
    width  : integer
  ) return std_logic_vector is
    variable l   : line;
    variable tmp : std_logic_vector(width - 1 downto 0);
  begin
    if endfile(f) then
      tmp := (others => '0');
    else
      readline(f, l);
      hread(l, tmp); -- 16진수 문자열 -> std_logic_vector
    end if;
    return tmp;
  end function;

begin

  BCH_Decoder_inst : BCH_Decoder
  generic map(
    g_GF_POWER                => c_GF_POWER,
    g_CODEWORD_WIDTH          => c_CODEWORD_WIDTH,
    g_MESSAGE_WIDTH           => c_MESSAGE_WIDTH,
    g_PARITY_WIDTH            => c_PARITY_WIDTH,
    g_ERR_CORRECTION_CAPACITY => c_ERR_CORRECTION_CAPACITY
  )
  port map
  (
    i_clk                => i_clk,
    i_n_reset            => i_n_reset,
    i_primitive_poly     => i_primitive_poly,
    i_encoded_data       => r_rx_codeword,
    i_encoded_data_valid => i_encoded_data_valid,
    o_decoded_data       => o_decoded_data,
    o_decoded_data_valid => o_decoded_data_valid,
    o_decode_ready       => o_decode_ready
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

  -- DATA_INPUT : process
  -- begin
  --   wait until RESET_DONE = '1';
  --   wait until rising_edge(i_clk);
  --   r_message <= c_MESSAGE_VECTOR;
  --   r_parity  <= c_PARITY_VECTOR;
  --   wait until rising_edge(i_clk);
  --   i_encoded_data                    <= r_message & r_parity;
  --   r_error_bit(c_POSITION_BIT_ERROR_1) <= '1';
  --   r_error_bit(c_POSITION_BIT_ERROR_2) <= '0';
  --   wait until rising_edge(i_clk);
  --   r_rx_codeword        <= i_encoded_data xor r_error_bit;
  --   i_encoded_data_valid <= '1';
  --   wait until rising_edge(i_clk);
  --   i_encoded_data_valid <= '0';
  --   wait;
  -- end process; -- DATA_INPUT

  READ_DATA : process
    variable l : line;
    variable v : std_logic_vector(c_CODEWORD_WIDTH - 1 downto 0);
  begin
    wait until RESET_DONE = '1';
    wait until rising_edge(i_clk);
    while (not endfile(BCH_ENCODED_TXT)) loop
      r_rx_codeword        <= read_hex_line(BCH_ENCODED_TXT, c_CODEWORD_WIDTH);
      i_encoded_data_valid <= '1';
      wait until rising_edge(i_clk);
      i_encoded_data_valid <= '0';
      wait until (o_decode_ready = '1');
    end loop;
    stop;
  end process; -- READ_DATA
end Behavioral;
