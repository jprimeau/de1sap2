-- DESCRIPTION: SAP-2 - DE1
-- AUTHOR: Jonathan Primeau

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity de1_sap2 is
    port (
        -- ***** Clocks
        CLOCK_50    : in std_logic;
        
        -- ***** SRAM 256K x 16
--        SRAM_ADDR   : out std_logic_vector(17 downto 0);
--        SRAM_DQ     : inout std_logic_vector(15 downto 0);
--        SRAM_OE_N   : out std_logic;
--        SRAM_UB_N   : out std_logic;
--        SRAM_LB_N   : out std_logic;        
--        SRAM_CE_N   : out std_logic;
--        SRAM_WE_N   : out std_logic; 
        
        -- ***** RS-232
--        UART_RXD    : in std_logic;
--        UART_TXD    : out std_logic;
        
        -- ***** Switches and buttons
        SW          : in std_logic_vector(9 downto 0);
        
        -- ***** Leds
        LEDR        : out std_logic_vector(9 downto 0);
        LEDG        : out std_logic_vector(7 downto 0);
        
        -- ***** Quad 7-seg displays
        HEX0        : out std_logic_vector(0 to 6);
        HEX1        : out std_logic_vector(0 to 6);
        HEX2        : out std_logic_vector(0 to 6);
        HEX3        : out std_logic_vector(0 to 6)
    );
    
end de1_sap2;

architecture rtl of de1_sap2 is

    signal reset            : std_logic;
    signal clk_1hz          : std_logic;
    signal counter_1hz      : std_logic_vector(25 downto 0);
    signal clk_10hz         : std_logic;
    signal counter_10hz     : std_logic_vector(25 downto 0);
    signal clk_100hz        : std_logic;
    signal counter_100hz    : std_logic_vector(25 downto 0);
    signal cpu_clk          : std_logic;
    signal halt             : std_logic;
    signal p0               : std_logic_vector(7 downto 0);
    
    -- Converts hex nibble to 7-segment.
    -- Segments ordered as "GFEDCBA"; '0' is ON, '1' is OFF
    function nibble_to_7seg(
        nibble : std_logic_vector(3 downto 0)
    )
        return std_logic_vector
    is
    begin
        case nibble is
        when X"0"       => return "0000001";
        when X"1"       => return "1001111";
        when X"2"       => return "0010010";
        when X"3"       => return "0000110";
        when X"4"       => return "1001100";
        when X"5"       => return "0100100";
        when X"6"       => return "0100000";
        when X"7"       => return "0001111";
        when X"8"       => return "0000000";
        when X"9"       => return "0000100";
        when X"A"       => return "0001000";
        when X"B"       => return "1100000";
        when X"C"       => return "0110001";
        when X"D"       => return "1000010";
        when X"E"       => return "0110000";
        when X"F"       => return "0111000";
        when others     => return "0111111"; -- can't happen
        end case;
    end function nibble_to_7seg;

begin

    reset <= not SW(9);
    
    LEDR(9) <= SW(9);
    LEDR(8 downto 1) <= (others => '0');
    LEDR(0) <=  clk_10Hz;
    
    LEDG <= p0;
    
    HEX0 <= nibble_to_7seg(p0(3 downto 0));
    HEX1 <= nibble_to_7seg(p0(7 downto  4));
    HEX2 <= (others => '1');
    HEX3 <= (others => '1') when halt = '0' else "1001000";
    
    cpu_clk <= clk_1hz when SW(0) = '0' else clk_100hz;

    -- Generate a 1Hz clock.
    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if reset = '1' then
                clk_1hz <= '0';
                counter_1hz <= (others => '0');
            else
                if conv_integer(counter_1hz) = 25000000 then
                    counter_1hz <= (others => '0');
                    clk_1hz <= not clk_1hz;
                else
                    counter_1hz <= counter_1hz + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Generate a 10Hz clock.
    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if reset = '1' then
                clk_10hz <= '0';
                counter_10hz <= (others => '0');
            else
                if conv_integer(counter_10hz) = 2500000 then
                    counter_10hz <= (others => '0');
                    clk_10hz <= not clk_10hz;
                else
                    counter_10hz <= counter_10hz + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Generate a 100Hz clock.
    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if reset = '1' then
                clk_100hz <= '0';
                counter_100hz <= (others => '0');
            else
                if conv_integer(counter_100hz) = 250000 then
                    counter_100hz <= (others => '0');
                    clk_100hz <= not clk_100hz;
                else
                    counter_100hz <= counter_100hz + 1;
                end if;
            end if;
        end if;
    end process;

    soc: entity work.sap2_cpu
    port map (
        clock   => cpu_clk,
        reset   => reset,
        
        halt_out    => halt,
        p0_out      => p0
    );

end architecture rtl;