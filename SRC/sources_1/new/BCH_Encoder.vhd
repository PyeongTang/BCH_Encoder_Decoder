----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/12/06 00:57:53
-- Design Name: 
-- Module Name: BCH_Encoder - Behavioral
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

-- =========================================================================================================================
-- BCH (n, k) Encoder Encodes k-bit of Message into n-bit of Codeword with (n-k) bit of parity
-- Parity bits determined by LFSR, finding remainder of divisor (generative polynomial) with dividend (Zero-Filled Message, n-bit)
-- Codeword consists of (Message, Parity) in systematic way
-- Generative Polynomial can be found on various way
--  Example)
--  t = 1     BCH(7,  4)    : x^3 + x^1 + 1                           : "1011"        : 0xB
--  t = 1     BCH(15, 11)   : x^4 + x^1 + 1                           : "10011"       : 0x13
--  t = 2     BCH(31, 21)   : x^10 + x^9 + x^8 + x^6 + x^5 + x^3 + 1  : "11101101001" : 0x769
--  t = 3     BCH(15, 5)    : x^10 + x^8 + x^5 + x^4 + x^2 + x^1 + 1  : "10100110110" : 0x537
--  ...
-- =========================================================================================================================

entity BCH_Encoder is
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
end BCH_Encoder;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of BCH_Encoder is

  ---------------------------------------------------------------------------
  -- Components
  ---------------------------------------------------------------------------

  component Shift_Register_Signle_Bit is
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
  end component;

  component LFSR is
    generic (
      g_CODEWORD_WIDTH  : integer                                      := 7;
      g_MAX_DEGREE_POLY : integer                                      := 3;
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

  constant c_MESSAGE_ZERO_FILL : std_logic_vector(g_PARITY_WIDTH - 1 downto 0) := (others => '0');
  constant c_MESSAGE_WIDTH     : integer                                       := g_CODEWORD_WIDTH - g_PARITY_WIDTH;

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal r_input_message : std_logic_vector(g_CODEWORD_WIDTH - 1 downto 0) := (others => '0');
  signal r_message_valid : std_logic                                       := '0';

  signal w_message_signle_bit       : std_logic;
  signal w_message_single_bit_valid : std_logic;

  signal w_parity       : std_logic_vector(g_PARITY_WIDTH - 1 downto 0);
  signal w_parity_valid : std_logic;

  signal r_output_codeword : std_logic_vector(g_CODEWORD_WIDTH - 1 downto 0) := (others => '0');
  signal r_codeword_valid  : std_logic                                       := '0';
  signal r_ready                : std_logic;

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------

begin

  o_data <= r_output_codeword;
  o_valid <= r_codeword_valid;
  o_ready <= r_ready;

  ---------------------------------------------------------------------------
  -- Instances
  ---------------------------------------------------------------------------

  Shift_Register_Signle_Bit_inst : Shift_Register_Signle_Bit
  generic map(
    g_INPUT_DATA_WIDTH => g_CODEWORD_WIDTH
  )
  port map
  (
    i_clk     => i_clk,
    i_n_reset => i_n_reset,
    i_data    => r_input_message,
    i_valid   => r_message_valid,
    o_data    => w_message_signle_bit,
    o_valid   => w_message_single_bit_valid,
    o_ready   => open
  );

  LFSR_inst : LFSR
  generic map(
    g_CODEWORD_WIDTH  => g_CODEWORD_WIDTH,
    g_MAX_DEGREE_POLY => g_PARITY_WIDTH,
    g_GENERATIVE_POLY => g_GENERATIVE_POLY
  )
  port map
  (
    i_clk     => i_clk,
    i_n_reset => i_n_reset,
    i_data    => w_message_signle_bit,
    i_valid   => w_message_single_bit_valid,
    o_data    => w_parity,
    o_valid   => w_parity_valid
  );

  ---------------------------------------------------------------------------
  -- Porcess
  ---------------------------------------------------------------------------

  DETERMINE_READY : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_ready <= '0';
    elsif (rising_edge(i_clk)) then
      if (i_valid = '1') then
        r_ready <= '0';
      elsif (r_codeword_valid = '1') then
        r_ready <= '1';
      end if;
    end if;
  end process; -- DETERMINE_READY

  DETERMINE_MESSAGE : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_input_message <= (others => '0');
      r_message_valid <= '0';
    elsif (rising_edge(i_clk)) then
      r_message_valid <= '0';
      if (i_valid = '1') then
        r_input_message <= i_data & c_MESSAGE_ZERO_FILL;
        r_message_valid <= '1';
      end if;
    end if;
  end process; -- DETERMINE_MESSAGE

  DETERMINE_CODEWORD : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_output_codeword <= (others => '0');
      r_codeword_valid  <= '0';
    elsif (rising_edge(i_clk)) then
      r_codeword_valid <= '0';
      if (w_parity_valid = '1') then
        r_output_codeword <= r_input_message(g_CODEWORD_WIDTH - 1 downto g_PARITY_WIDTH) & w_parity;
        r_codeword_valid  <= '1';
      end if;
    end if;
  end process; -- DETERMINE_CODEWORD
end Behavioral;
