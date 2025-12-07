----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/12/02 21:03:23
-- Design Name: 
-- Module Name: BCH_Decoder - Behavioral
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

-- =========================================================================================================================
-- BCH (n, k) Decoder Decodes Input n-bit codeword to k-bit message, with following method
--  1. Syndrome Evaluation
--      Syndrome S(x) is evaluated with given input codeword, for non-zero syndrome, indicates there are errors
--  2. BM Algorithm Solving
--      Berlekamp-Massey Algorithm finds coefficients of minimum degree polynomial (Error Location Polynomial, Sigma(x))
--  3. Chien Search
--      For Sigma(x), Bit error position i, can be found by evaluating Sigma(alpha^-i) = 0
--  4. Recovered codeword can be found by INPUT_CODEWORD xor ERR_BIT_POSITION
--      BCH Code defined by GF(2), error value always '1', this means error correction done with bit-wise XOR
--  5. Part Selection
--      For recovered n-bit codeword, Codeword = {Message, Parity}, Message can be selected
-- =========================================================================================================================

entity BCH_Decoder is
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
end BCH_Decoder;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of BCH_Decoder is

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

  component Syndrome_Generator is
    generic (
      g_GF_POWER                : integer := 3;
      g_ERR_CORRECTION_CAPACITY : integer := 2
    );
    port (
      i_clk            : in std_logic;
      i_n_reset        : in std_logic;
      i_data           : in std_logic;
      i_valid          : in std_logic;
      i_primitive_poly : std_logic_vector(g_GF_POWER downto 0);
      o_syndrome       : out t_array_slv_n(0 to 2 * g_ERR_CORRECTION_CAPACITY - 1)(g_GF_POWER - 1 downto 0);
      o_syndrome_valid : out std_logic
    );
  end component;

  component BM_Solver is
    generic (
      g_GF_POWER                : integer := 3;
      g_ERR_CORRECTION_CAPACITY : integer := 2
    );
    port (
      i_clk            : in std_logic;
      i_n_reset        : in std_logic;
      i_syndrome_valid : in std_logic;
      i_syndrome       : in t_array_slv_n(0 to 2 * g_ERR_CORRECTION_CAPACITY - 1)(g_GF_POWER - 1 downto 0); -- slv{m}(2t - 1 downto 0), GF(2**m)
      o_sigma          : out t_array_slv_n(0 to g_ERR_CORRECTION_CAPACITY)(g_GF_POWER - 1 downto 0);
      o_sigma_valid    : out std_logic
    );
  end component;

  component Chien_Horner_Solver is
    generic (
      g_GF_POWER                : integer := 3;
      g_ERR_CORRECTION_CAPACITY : integer := 2;
      g_ALPHA_INVERSE_EXPONENT  : integer := 6
    );
    port (
      i_clk                      : in std_logic;
      i_n_reset                  : in std_logic;
      i_sigma                    : in t_array_slv_n(0 to g_ERR_CORRECTION_CAPACITY)(g_GF_POWER - 1 downto 0);
      i_sigma_valid              : in std_logic;
      o_error_bit_position       : out std_logic_vector(2 ** g_GF_POWER - 1 - 1 downto 0);
      o_error_bit_position_valid : out std_logic
    );
  end component;

  ---------------------------------------------------------------------------
  -- Constants
  ---------------------------------------------------------------------------
  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal w_rx_bit       : std_logic;
  signal w_rx_bit_valid : std_logic;

  signal r_encoded_data_valid : std_logic                                       := '0';
  signal r_codeword           : std_logic_vector(g_CODEWORD_WIDTH - 1 downto 0) := (others => '0');
  signal r_decode_ready       : std_logic                                       := '0';

  signal r_decoded_done   : std_logic := '0';
  signal r_decoded_done_z : std_logic := '0';

  signal w_syndrome       : t_array_slv_n(0 to 2 * g_ERR_CORRECTION_CAPACITY - 1)(g_GF_POWER - 1 downto 0);
  signal w_syndrome_valid : std_logic;

  signal r_syndrome_valid : std_logic := '0';
  signal r_error_occured  : std_logic := '0';
  signal w_BM_enable      : std_logic;

  signal w_sigma       : t_array_slv_n(0 to g_ERR_CORRECTION_CAPACITY)(g_GF_POWER - 1 downto 0);
  signal w_sigma_valid : std_logic;

  signal w_error_bit_position       : std_logic_vector(g_CODEWORD_WIDTH - 1 downto 0);
  signal w_error_bit_position_valid : std_logic;

  signal r_decoded_data       : std_logic_vector(g_CODEWORD_WIDTH - 1 downto 0) := (others => '0');
  signal r_decoded_data_valid : std_logic                                       := '0';

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------
begin
  ---------------------------------------------------------------------------
  -- Output Latch
  ---------------------------------------------------------------------------

  o_decoded_data       <= r_decoded_data((g_CODEWORD_WIDTH - 1) downto (g_CODEWORD_WIDTH - 1) - g_MESSAGE_WIDTH + 1);
  o_decoded_data_valid <= r_decoded_data_valid;
  o_decode_ready       <= r_decode_ready;
  w_BM_enable          <= r_syndrome_valid and r_error_occured;

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
    i_data    => i_encoded_data,
    i_valid   => i_encoded_data_valid,
    o_data    => w_rx_bit,
    o_valid   => w_rx_bit_valid,
    o_ready   => open
  );

  Syndrome_Generator_inst : Syndrome_Generator
  generic map(
    g_GF_POWER                => g_GF_POWER,
    g_ERR_CORRECTION_CAPACITY => g_ERR_CORRECTION_CAPACITY
  )
  port map
  (
    i_clk            => i_clk,
    i_n_reset        => i_n_reset,
    i_data           => w_rx_bit,
    i_valid          => w_rx_bit_valid,
    i_primitive_poly => i_primitive_poly,
    o_syndrome       => w_syndrome,
    o_syndrome_valid => w_syndrome_valid
  );

  BM_Solver_inst : BM_Solver
  generic map(
    g_GF_POWER                => g_GF_POWER,
    g_ERR_CORRECTION_CAPACITY => g_ERR_CORRECTION_CAPACITY
  )
  port map
  (
    i_clk            => i_clk,
    i_n_reset        => i_n_reset,
    i_syndrome       => w_syndrome,
    i_syndrome_valid => w_BM_enable,
    o_sigma          => w_sigma,
    o_sigma_valid    => w_sigma_valid
  );

  Chien_Horner_Solver_inst : Chien_Horner_Solver
  generic map(
    g_GF_POWER                => g_GF_POWER,
    g_ERR_CORRECTION_CAPACITY => g_ERR_CORRECTION_CAPACITY,
    g_ALPHA_INVERSE_EXPONENT  => (2 ** g_GF_POWER - 1) - 1
  )
  port map
  (
    i_clk                      => i_clk,
    i_n_reset                  => i_n_reset,
    i_sigma                    => w_sigma,
    i_sigma_valid              => w_sigma_valid,
    o_error_bit_position       => w_error_bit_position,
    o_error_bit_position_valid => w_error_bit_position_valid
  );

  ---------------------------------------------------------------------------
  -- Processes
  ---------------------------------------------------------------------------

  SYNDROME_ERROR_CHECK : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_error_occured <= '0';
    elsif (rising_edge(i_clk)) then
      for i in w_syndrome'range loop
        if (w_syndrome_valid = '1') then
          if (to_integer(unsigned(w_syndrome(i))) /= 0) then
            r_error_occured <= '1';
          else
            r_error_occured <= '0';
          end if;
        else
            r_error_occured <= '0';
        end if;
      end loop;
    end if;
  end process; -- SYNDROME_ERROR_CHECK

  DELAY_FOR_EDGE : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_encoded_data_valid <= '0';
      r_syndrome_valid     <= '0';
    elsif (rising_edge(i_clk)) then
      r_encoded_data_valid <= i_encoded_data_valid;
      r_syndrome_valid     <= w_syndrome_valid;
    end if;
  end process; -- DELAY_FOR_EDGE

  DETERMINE_READY : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_decode_ready <= '1';
    elsif (rising_edge(i_clk)) then
      if (i_encoded_data_valid = '1' and r_encoded_data_valid = '0') then
        r_decode_ready <= '0';
      elsif (r_decode_ready = '0' and r_syndrome_valid = '1' and r_error_occured = '0') then
        r_decode_ready <= '1';
      elsif (r_decoded_data_valid = '1') then
        r_decode_ready <= '1';
      end if;
    end if;
  end process; -- DETERMINE_READY

  CODEWORD_XOR_ERROR : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_codeword           <= (others => '0');
      r_decoded_data       <= (others => '0');
      r_decoded_data_valid <= '0';
    elsif (rising_edge(i_clk)) then
      r_decoded_data_valid <= '0';
      if (i_encoded_data_valid = '1') then
        r_codeword <= i_encoded_data;
      end if;
      if (w_error_bit_position_valid = '1') then
        r_decoded_data       <= r_codeword xor w_error_bit_position;
        r_decoded_data_valid <= '1';
      end if;
    end if;
  end process; -- CODEWORD_XOR_ERROR

end Behavioral;
