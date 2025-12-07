----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/30 13:11:08
-- Design Name: 
-- Module Name: GF_INV - Behavioral
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

entity GF_INV is
  generic (
    g_GF_POWER : integer := 3
  );
  port (
    i_clk         : in std_logic;
    i_n_reset     : in std_logic;
    i_A           : in std_logic_vector(g_GF_POWER - 1 downto 0);
    i_A_valid     : in std_logic;
    o_A_INV       : out std_logic_vector(g_GF_POWER - 1 downto 0);
    o_A_INV_valid : out std_logic
  );
end GF_INV;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of GF_INV is

  ---------------------------------------------------------------------------
  -- Components
  ---------------------------------------------------------------------------

  component GF_LOG is
    generic (
      g_GF_POWER : integer := 3
    );
    port (
      i_clk      : in std_logic;
      i_n_reset  : in std_logic;
      i_index    : in std_logic_vector(g_GF_POWER - 1 downto 0);
      i_valid    : in std_logic;
      o_exponent : out std_logic_vector(g_GF_POWER - 1 downto 0);
      o_valid    : out std_logic
    );
  end component;

  component GF_ANTILOG is
    generic (
      g_GF_POWER : integer := 3
    );
    port (
      i_clk      : in std_logic;
      i_n_reset  : in std_logic;
      i_exponent : in std_logic_vector(g_GF_POWER - 1 downto 0);
      i_valid    : in std_logic;
      o_index    : out std_logic_vector(g_GF_POWER - 1 downto 0);
      o_valid    : out std_logic
    );
  end component;

  ---------------------------------------------------------------------------
  -- Constants
  ---------------------------------------------------------------------------

  constant c_MOD       : integer                                   := (2 ** g_GF_POWER - 1);

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal w_A_exp       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal r_A_exp       : integer;
  signal r_A_exp_valid : std_logic := '0';
  signal w_A_exp_valid : std_logic := '0';

  signal r_A_INV_exp         : integer                                   := 0;
  signal w_A_INV_exp         : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal r_A_INV_exp_valid   : std_logic                                 := '0';
  signal w_A_INV_index       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal w_A_INV_index_valid : std_logic                                 := '0';

begin

  w_A_INV_exp   <= std_logic_vector(to_unsigned(r_A_INV_exp, g_GF_POWER));
  o_A_INV       <= w_A_INV_index;
  o_A_INV_valid <= w_A_INV_index_valid;

  ---------------------------------------------------------------------------
  -- Instances
  ---------------------------------------------------------------------------

  GF_LOG_A : GF_LOG
    generic map(
      g_GF_POWER => g_GF_POWER
    )
    port map
    (
      i_clk      => i_clk,
      i_n_reset  => i_n_reset,
      i_index    => i_A,
      i_valid    => i_A_valid,
      o_exponent => w_A_exp,
      o_valid    => w_A_exp_valid
  );

  GF_ANTILOG_inst : GF_ANTILOG
    generic map(
      g_GF_POWER => g_GF_POWER
    )
    port map
    (
      i_clk      => i_clk,
      i_n_reset  => i_n_reset,
      i_exponent => w_A_INV_exp,
      i_valid    => r_A_INV_exp_valid,
      o_index    => w_A_INV_index,
      o_valid    => w_A_INV_index_valid
  );

  ---------------------------------------------------------------------------
  -- Processes
  ---------------------------------------------------------------------------

  FF_STAGE_1 : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_A_exp       <= 0;
      r_A_exp_valid <= '0';
    elsif (rising_edge(i_clk)) then
      r_A_exp       <= to_integer(unsigned(w_A_exp));
      r_A_exp_valid <= w_A_exp_valid;
    end if;
  end process; -- FF_STAGE_1

  FF_STAGE_2 : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_A_INV_exp       <= 0;
      r_A_INV_exp_valid <= '0';
    elsif (rising_edge(i_clk)) then
      if (r_A_exp_valid = '1') then
        r_A_INV_exp       <= c_MOD - r_A_exp;
        r_A_INV_exp_valid <= r_A_exp_valid;
      else
        r_A_INV_exp_valid <= '0';
      end if;
    end if;
  end process; -- FF_STAGE_2

end Behavioral;
