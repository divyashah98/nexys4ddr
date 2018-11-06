library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

Library xpm;
use xpm.vcomponents.all;

-- This is the top level module. The ports on this entity are mapped directly
-- to pins on the FPGA.
--
-- In this version the design can execute all instructions.
--
-- Additionally, the CPU registers are shown on the VGA display.
-- The registers shown are:
-- * WREN (1 byte) and DATA OUT (1 byte)
-- * ADDR (2 bytes)
-- * HI (1 byte) and LO (1 byte)
-- * DATA IN (1 byte) and 'A' register (1 byte)
-- * PC (2 bytes)
-- * Instruction Register (1 byte) and Instruction Cycle Count (1 bytes)
--
-- The speed of the execution is controlled by the slide switches.

entity comp is
   generic (
      G_FONT_FILE : string := "font8x8.txt"
   );
   port (
      clk_i     : in  std_logic;                      -- 100 MHz

      sw_i      : in  std_logic_vector(7 downto 0);
      led_o     : out std_logic_vector(7 downto 0);
      rstn_i    : in  std_logic;

      vga_hs_o  : out std_logic;
      vga_vs_o  : out std_logic;
      vga_col_o : out std_logic_vector(7 downto 0)    -- RRRGGGBB
   );
end comp;

architecture Structural of comp is

   constant C_OVERLAY_BITS : integer := 176;

   -- MAIN Clock domain
   signal main_clk     : std_logic;
   signal main_rst     : std_logic;
   signal main_wait    : std_logic;
   signal main_overlay : std_logic_vector(C_OVERLAY_BITS-1 downto 0);

   -- VGA Clock doamin
   signal vga_clk        : std_logic;
   signal vga_overlay_en : std_logic;
   signal vga_overlay    : std_logic_vector(C_OVERLAY_BITS-1 downto 0);
   signal vga_char_addr  : std_logic_vector(12 downto 0);
   signal vga_char_data  : std_logic_vector( 7 downto 0);
   signal vga_col_addr   : std_logic_vector(12 downto 0);
   signal vga_col_data   : std_logic_vector( 7 downto 0);

begin
   
   --------------------------------------------------
   -- Instantiate Clock generation
   --------------------------------------------------

   clk_inst : entity work.clk_wiz_0_clk_wiz
   port map (
      clk_in1  => clk_i,
      eth_clk  => open, -- Not needed yet.
      vga_clk  => vga_clk,
      main_clk => main_clk
   ); -- clk_inst


   --------------------------------------------------
   -- Generate Reset
   --------------------------------------------------
   main_rst_proc : process (main_clk)
   begin
      if rising_edge(main_clk) then
         main_rst <= not rstn_i;
      end if;
   end process main_rst_proc;
   
   
   --------------------------------------------------
   -- Instantiate Waiter
   --------------------------------------------------

   waiter_inst : entity work.waiter
   port map (
      clk_i  => main_clk,
      sw_i   => sw_i,
      wait_o => main_wait
   ); -- waiter_inst


   --------------------------------------------------
   -- Instantiate main
   --------------------------------------------------

   main_inst : entity work.main
   generic map (
      G_OVERLAY_BITS => C_OVERLAY_BITS
   )
   port map (
      main_clk_i     => main_clk,
      main_rst_i     => main_rst,
      main_wait_i    => main_wait,
      main_led_o     => led_o,
      main_overlay_o => main_overlay,
      --
      vga_clk_i       => vga_clk,
      vga_char_addr_i => vga_char_addr,
      vga_char_data_o => vga_char_data,
      vga_col_addr_i  => vga_col_addr,
      vga_col_data_o  => vga_col_data
   ); -- main_inst


   --------------------------------------------------
   -- Instantiate clock crossing from MAIN to VGA
   --------------------------------------------------

   xpm_cdc_array_single_inst: xpm_cdc_array_single
   generic map (
      DEST_SYNC_FF   => 2,
      SIM_ASSERT_CHK => 1,
      SRC_INPUT_REG  => 1,
      WIDTH          => C_OVERLAY_BITS
   )
   port map (
      src_clk  => main_clk,
      src_in   => main_overlay,
      dest_clk => vga_clk,
      dest_out => vga_overlay
   ); -- xpm_cdc_array_single_inst


   vga_overlay_en <= not sw_i(7);

   --------------------------------------------------
   -- Instantiate VGA module
   --------------------------------------------------

   vga_inst : entity work.vga
   generic map (
      G_OVERLAY_BITS => C_OVERLAY_BITS,
      G_FONT_FILE    => G_FONT_FILE
   )
   port map (
      clk_i     => vga_clk,
      overlay_i => vga_overlay_en,
      digits_i  => vga_overlay,
      --
      char_addr_o => vga_char_addr,
      char_data_i => vga_char_data,
      col_addr_o  => vga_col_addr,
      col_data_i  => vga_col_data,
      --
      vga_hs_o  => vga_hs_o,
      vga_vs_o  => vga_vs_o,
      vga_col_o => vga_col_o
   ); -- vga_inst

end architecture Structural;

