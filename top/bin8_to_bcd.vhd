library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin8_to_bcd is
    port (
        bin_in      : in  std_logic_vector(8 downto 0);  -- {C, ALU_Result} o {0,val}
        signed_mode : in  std_logic;                       -- '0'=sin signo, '1'=complemento a 2
        hundreds    : out std_logic_vector(3 downto 0);
        tens        : out std_logic_vector(3 downto 0);
        bcd_units   : out std_logic_vector(3 downto 0);    -- Evita palabra reservada 'units'
        neg_sign    : out std_logic                        -- '1' = número negativo
    );
end entity bin8_to_bcd;

architecture rtl of bin8_to_bcd is
begin

    -- Proceso 100% combinacional con todas las entradas en lista de sensibilidad
    process(bin_in, signed_mode)
        variable magnitude : unsigned(8 downto 0);
        variable shift_reg : unsigned(8 downto 0);
        variable bcd_full  : unsigned(11 downto 0);  -- 12 bits BCD (3 dígitos × 4 bits)
        variable is_neg    : std_logic;
    begin
        is_neg := '0';

        if signed_mode = '1' then
            -- Modo con signo: solo los 8 bits bajos son el valor en complemento a dos
            if bin_in(7) = '1' then
                -- Negativo: calcular magnitud absoluta = NOT(val) + 1
                magnitude := unsigned('0' & (not bin_in(7 downto 0))) + 1;
                is_neg    := '1';
            else
                magnitude := unsigned('0' & bin_in(7 downto 0));
                is_neg    := '0';
            end if;
        else
            -- Modo sin signo: valor completo de 9 bits (0 a 510)
            magnitude := unsigned(bin_in);
            is_neg    := '0';
        end if;

        -- Algoritmo Double Dabble: 9 iteraciones para los 9 bits de entrada
        bcd_full  := (others => '0');
        shift_reg := magnitude;

        for i in 0 to 8 loop
            -- Ajuste BCD: si cualquier dígito >= 5, sumar 3
            if bcd_full(3 downto 0) >= 5 then
                bcd_full(3 downto 0) := bcd_full(3 downto 0) + 3;
            end if;
            if bcd_full(7 downto 4) >= 5 then
                bcd_full(7 downto 4) := bcd_full(7 downto 4) + 3;
            end if;
            if bcd_full(11 downto 8) >= 5 then
                bcd_full(11 downto 8) := bcd_full(11 downto 8) + 3;
            end if;
            -- Desplazamiento a la izquierda
            bcd_full  := bcd_full(10 downto 0) & shift_reg(8);
            shift_reg := shift_reg(7 downto 0) & '0';
        end loop;

        -- Asignación incondicional a salidas (cero latches)
        hundreds  <= std_logic_vector(bcd_full(11 downto 8));
        tens      <= std_logic_vector(bcd_full(7  downto 4));
        bcd_units <= std_logic_vector(bcd_full(3  downto 0));
        neg_sign  <= is_neg;

    end process;

end architecture rtl;
