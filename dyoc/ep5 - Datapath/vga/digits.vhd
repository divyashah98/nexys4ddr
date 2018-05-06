library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity digits is
   generic (
      G_FONT_FILE : string
   );
   port (
      clk_i     : in  std_logic;

      pix_x_i   : in  std_logic_vector(9 downto 0);
      pix_y_i   : in  std_logic_vector(9 downto 0);
      digits_i  : in  std_logic_vector(47 downto 0);

      vga_col_o : out std_logic_vector(7 downto 0)
   );
end digits;

architecture Structural of digits is

   -- Define pixel counter range
   constant H_TOTAL  : integer := 800;
   constant V_TOTAL  : integer := 525;

   -- Define visible screen size
   constant H_PIXELS : integer := 640;
   constant V_PIXELS : integer := 480;

   -- Each character is 16x16 pixels, so the screen contains 40x30 characters.

   -- Define positioning of first digit
   constant DIGITS_CHAR_X : integer := 8;
   constant DIGITS_CHAR_Y : integer := 15;

   constant TEXT_CHAR_X   : integer := 2;
   constant TEXT_CHAR_Y   : integer := DIGITS_CHAR_Y;

   type txt_t is array (0 to 14) of character;
   constant txt : txt_t := "DI AR" & "IR CN" & "  PC ";

   -- A single character bitmap is defined by 8x8 = 64 bits.
   subtype bitmap_t is std_logic_vector(63 downto 0);


   -- Define colours
   constant COL_BLACK : std_logic_vector(7 downto 0) := B"000_000_00";
   constant COL_DARK  : std_logic_vector(7 downto 0) := B"001_001_01";
   constant COL_WHITE : std_logic_vector(7 downto 0) := B"111_111_11";
   constant COL_RED   : std_logic_vector(7 downto 0) := B"111_000_00";
   constant COL_GREEN : std_logic_vector(7 downto 0) := B"000_111_00";
   constant COL_BLUE  : std_logic_vector(7 downto 0) := B"000_000_11";


   -- Character coordinates
   signal char_col : integer range 0 to H_TOTAL/16-1;
   signal char_row : integer range 0 to V_TOTAL/16-1;

   -- Value of nibble at current position
   signal nibble_offset : integer range 0 to 11;
   signal nibble_index  : integer range 0 to 11;
   signal nibble        : std_logic_vector(3 downto 0);
   signal txt_offset    : integer range 0 to 14;

   -- Bitmap of digit at current position
   signal char_nibble   : std_logic_vector(7 downto 0);
   signal char_txt      : std_logic_vector(7 downto 0);
   signal char          : std_logic_vector(7 downto 0);
   signal bitmap        : bitmap_t;

   -- Pixel at current position
   signal pix_col       : integer range 0 to 7;
   signal pix_row       : integer range 0 to 7;
   signal bitmap_index  : integer range 0 to 63;
   signal pix           : std_logic;

   -- Pixel colour
   signal vga_col : std_logic_vector(7 downto 0);

begin

   --------------------------------------------------
   -- Calculate character coordinates, within 40x30
   --------------------------------------------------

   char_col <= conv_integer(pix_x_i(9 downto 4));
   char_row <= conv_integer(pix_y_i(9 downto 4));


   --------------------------------------------------
   -- Calculate value of digit at current position ('0' or '1')
   --------------------------------------------------

   nibble_offset <= (char_row - DIGITS_CHAR_Y)*4 + (char_col - DIGITS_CHAR_X);
   nibble_index  <= 11 - nibble_offset;
   nibble        <= digits_i(4*nibble_index+3 downto 4*nibble_index);
   txt_offset    <= (char_row - TEXT_CHAR_Y)*5 + (char_col - TEXT_CHAR_X);


   --------------------------------------------------
   -- Calculate character to display at current position
   --------------------------------------------------

   char_nibble <= nibble + X"30" when nibble < 10 else
           nibble + X"41" - 10;

   char_txt    <= std_logic_vector(to_unsigned(character'pos(txt(txt_offset)), 8));

   char <= char_nibble when char_row >= DIGITS_CHAR_Y and char_row < DIGITS_CHAR_Y+3 and
                            char_col >= DIGITS_CHAR_X and char_col < DIGITS_CHAR_X+4 else
           char_txt    when char_row >= TEXT_CHAR_Y   and char_row < TEXT_CHAR_Y+3 and
                            char_col >= TEXT_CHAR_X   and char_col < TEXT_CHAR_X+5 else
           X"20"; -- Space


   --------------------------------------------------
   -- Calculate bitmap (64 bits) of digit at current position
   --------------------------------------------------

   i_font : entity work.font
   generic map (
      G_FONT_FILE => "font8x8.txt"
   )
   port map (
      char_i   => char,
      bitmap_o => bitmap
   );


   --------------------------------------------------
   -- Calculate pixel at current position ('0' or '1')
   --------------------------------------------------

   pix_col       <= conv_integer(pix_x_i(3 downto 1));
   pix_row       <= 7 - conv_integer(pix_y_i(3 downto 1));
   bitmap_index  <= pix_row*8 + pix_col;
   pix           <= bitmap(bitmap_index);


   --------------------------------------------------
   -- Generate pixel colour
   --------------------------------------------------

   p_vga_col : process (clk_i)
   begin
      if rising_edge(clk_i) then

         -- Set the default screen background colour
         vga_col <= COL_BLACK;

--         -- Are we within the borders of the text?
--         if char_row >= DIGITS_CHAR_Y and char_row < DIGITS_CHAR_Y+3 and
--            char_col >= DIGITS_CHAR_X and char_col < DIGITS_CHAR_X+4 then

            if pix = '1' then
               vga_col <= COL_WHITE;
            else
               vga_col <= COL_DARK; -- Text background colour.
            end if;
--         end if;

         -- Make sure colour is black outside visible screen
         if pix_x_i >= H_PIXELS or pix_y_i >= V_PIXELS then
            vga_col <= COL_BLACK;
         end if;

      end if;
   end process p_vga_col;


   --------------------------------------------------
   -- Drive output signals
   --------------------------------------------------

   vga_col_o <= vga_col;

end architecture Structural;
