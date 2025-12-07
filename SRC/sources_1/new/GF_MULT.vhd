----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/30 12:42:30
-- Design Name: 
-- Module Name: GF_MULT - Behavioral
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

entity GF_MULT is
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
    o_P       : out std_logic_vector(g_GF_POWER - 1 downto 0);
    o_P_valid : out std_logic
  );
end GF_MULT;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of GF_MULT is

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

  constant c_MOD : integer := (2 ** g_GF_POWER - 1);

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal w_A_exp       : std_logic_vector(g_GF_POWER - 1 downto 0);
  signal r_A_exp_valid : std_logic;
  signal w_A_exp_valid : std_logic;
  signal w_B_exp       : std_logic_vector(g_GF_POWER - 1 downto 0);
  signal r_B_exp_valid : std_logic;
  signal w_B_exp_valid : std_logic;

  signal r_A_exp      : integer   := 0;
  signal r_B_exp      : integer   := 0;
  signal r_zero       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal r_zero_valid : std_logic := '0';

  signal r_P_exp_valid : std_logic := '0';
  signal w_P_exp_valid : std_logic;
  signal r_P_exp       : integer                                   := 0;
  signal w_P_exp       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal w_P_index     : std_logic_vector(g_GF_POWER - 1 downto 0);
  signal r_P_index     : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal w_P_valid     : std_logic                                 := '0';

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------

begin

  w_P_exp_valid <= r_P_exp_valid;
  w_P_exp       <= std_logic_vector(to_unsigned(r_P_exp, g_GF_POWER));
  o_P           <= w_P_index when (r_zero_valid = '0') else (others => '0') ;
  o_P_valid     <= w_P_valid when (r_zero_valid = '0') else r_zero_valid;

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

  GF_LOG_B : GF_LOG
    generic map(
      g_GF_POWER => g_GF_POWER
    )
    port map
    (
      i_clk      => i_clk,
      i_n_reset  => i_n_reset,
      i_index    => i_B,
      i_valid    => i_B_valid,
      o_exponent => w_B_exp,
      o_valid    => w_B_exp_valid
  );

  GF_ANTILOG_inst : GF_ANTILOG
    generic map(
      g_GF_POWER => g_GF_POWER
    )
    port map
    (
      i_clk      => i_clk,
      i_n_reset  => i_n_reset,
      i_exponent => w_P_exp,
      i_valid    => w_P_exp_valid,
      o_index    => w_P_index,
      o_valid    => w_P_valid
  );

  ---------------------------------------------------------------------------
  -- Porcess
  ---------------------------------------------------------------------------

  FF_STAGE_1 : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_A_exp       <= 0;
      r_B_exp       <= 0;
      r_A_exp_valid <= '0';
      r_B_exp_valid <= '0';
    elsif (rising_edge(i_clk)) then
      r_A_exp       <= to_integer(unsigned(w_A_exp));
      r_B_exp       <= to_integer(unsigned(w_B_exp));
      r_A_exp_valid <= w_A_exp_valid;
      r_B_exp_valid <= w_B_exp_valid;
    end if;
  end process; -- FF_STAGE_1

  FF_STAGE_2 : process (i_clk, i_n_reset)
  begin
    if (i_n_reset = '0') then
      r_P_exp       <= 0;
      r_P_exp_valid <= '0';
      r_zero_valid  <= '0';
    elsif (rising_edge(i_clk)) then
      r_zero_valid  <= '0';
      r_P_exp_valid <= '0';
      if (r_A_exp_valid = '1' and r_B_exp_valid = '1') then
        if (r_A_exp = (2 ** g_GF_POWER - 1) or r_B_exp = (2 ** g_GF_POWER - 1)) then
          r_zero_valid <= '1';
        else
          r_P_exp       <= (r_A_exp + r_B_exp) mod c_MOD;
          r_P_exp_valid <= '1';
        end if;
      else
      end if;
    end if;
  end process; -- FF_STAGE_2

end Behavioral;
