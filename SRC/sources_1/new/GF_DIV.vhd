----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/11/30 13:22:30
-- Design Name: 
-- Module Name: GF_DIV - Behavioral
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

entity GF_DIV is
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
    o_Q       : out std_logic_vector(g_GF_POWER - 1 downto 0);
    o_Q_valid : out std_logic
  );
end GF_DIV;

---------------------------------------------------------------------------
-- Architecture
---------------------------------------------------------------------------

architecture Behavioral of GF_DIV is

  ---------------------------------------------------------------------------
  -- Components
  ---------------------------------------------------------------------------

  component GF_MULT is
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
  end component;

  component GF_INV is
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
  end component;

  ---------------------------------------------------------------------------
  -- Signals
  ---------------------------------------------------------------------------

  signal r_A_latch : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');

  signal w_B_INV       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal w_B_INV_valid : std_logic                                 := '0';

  signal w_Q       : std_logic_vector(g_GF_POWER - 1 downto 0) := (others => '0');
  signal w_Q_valid : std_logic                                 := '0';

  ---------------------------------------------------------------------------
  -- Architecture Body
  ---------------------------------------------------------------------------

begin

  o_Q       <= w_Q;
  o_Q_valid <= w_Q_valid;

  ---------------------------------------------------------------------------
  -- Instances
  ---------------------------------------------------------------------------

  GF_MULT_inst : GF_MULT
    generic map(
      g_GF_POWER => g_GF_POWER
    )
    port map
    (
      i_clk     => i_clk,
      i_n_reset => i_n_reset,
      i_A       => r_A_latch,
      i_A_valid => w_B_INV_valid,
      i_B       => w_B_INV,
      i_B_valid => w_B_INV_valid,
      o_P       => w_Q,
      o_P_valid => w_Q_valid
  );

  GF_INV_inst : GF_INV
    generic map(
      g_GF_POWER => g_GF_POWER
    )
    port map
    (
      i_clk         => i_clk,
      i_n_reset     => i_n_reset,
      i_A           => i_B,
      i_A_valid     => i_B_valid,
      o_A_INV       => w_B_INV,
      o_A_INV_valid => w_B_INV_valid
  );

  ---------------------------------------------------------------------------
  -- Porcess
  ---------------------------------------------------------------------------

  INPUT_A_LATCH : process( i_clk, i_n_reset )
  begin
    if (i_n_reset = '0') then
      r_A_latch <= (others => '0');
    elsif (rising_edge(i_clk)) then
      if (i_A_valid = '1') then
        r_A_latch <= i_A;
      end if;
    end if;
  end process ; -- INPUT_A_LATCH

end Behavioral;
