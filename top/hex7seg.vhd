library ieee;
use ieee.std_logic_1164.all;

entity hex7seg is
    port (
        hex_in  : in  std_logic_vector(3 downto 0);
        blank   : in  std_logic := '0';  -- '1' = apagar todos los segmentos
        minus   : in  std_logic := '0';  -- '1' = mostrar signo negativo '-' (segmento g)
        seg_out : out std_logic_vector(6 downto 0)
    );
end entity hex7seg;

architecture rtl of hex7seg is
begin

    -- Proceso 100% combinacional con todas las entradas en lista de sensibilidad
    process(hex_in, blank, minus)
    begin
        if blank = '1' then
            seg_out <= "1111111";  -- Todos los segmentos apagados
        elsif minus = '1' then
            seg_out <= "0111111";  -- Solo segmento g encendido ('-')
        else
            case hex_in is
                --                      gfedcba
                when x"0"   => seg_out <= "1000000";  -- 0
                when x"1"   => seg_out <= "1111001";  -- 1
                when x"2"   => seg_out <= "0100100";  -- 2
                when x"3"   => seg_out <= "0110000";  -- 3
                when x"4"   => seg_out <= "0011001";  -- 4
                when x"5"   => seg_out <= "0010010";  -- 5
                when x"6"   => seg_out <= "0000010";  -- 6
                when x"7"   => seg_out <= "1111000";  -- 7
                when x"8"   => seg_out <= "0000000";  -- 8
                when x"9"   => seg_out <= "0010000";  -- 9
                when x"A"   => seg_out <= "0001000";  -- A
                when x"B"   => seg_out <= "0000011";  -- b
                when x"C"   => seg_out <= "1000110";  -- C
                when x"D"   => seg_out <= "0100001";  -- d
                when x"E"   => seg_out <= "0000110";  -- E
                when x"F"   => seg_out <= "0001110";  -- F
                when others => seg_out <= "1111111";  -- Apagado por defecto
            end case;
        end if;
    end process;

end architecture rtl;
