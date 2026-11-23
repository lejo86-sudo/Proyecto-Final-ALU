library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debouncer is
    generic (
        FILTER_COUNT : integer := 1_000_000  -- 20 ms @ 50 MHz
    );
    port (
        CLOCK_50  : in  std_logic;
        reset_n   : in  std_logic;   -- Activo en bajo
        btn_in    : in  std_logic;   -- Botón activo en bajo
        pulse_out : out std_logic    -- Pulso limpio, 1 ciclo, activo en alto
    );
end entity debouncer;

architecture rtl of debouncer is

    signal counter   : integer range 0 to FILTER_COUNT - 1 := 0;
    signal btn_sync0 : std_logic := '1';
    signal btn_sync1 : std_logic := '1';
    signal btn_prev  : std_logic := '1';
    signal btn_clean : std_logic := '1';

begin

    -- Doble flip-flop para sincronización metaestabilidad
    process(CLOCK_50, reset_n)
    begin
        if reset_n = '0' then
            btn_sync0 <= '1';
            btn_sync1 <= '1';
        elsif rising_edge(CLOCK_50) then
            btn_sync0 <= btn_in;
            btn_sync1 <= btn_sync0;
        end if;
    end process;

    -- Contador de filtrado y generación de señal limpia
    process(CLOCK_50, reset_n)
    begin
        if reset_n = '0' then
            counter   <= 0;
            btn_clean <= '1';
        elsif rising_edge(CLOCK_50) then
            if btn_sync1 /= btn_clean then
                if counter = FILTER_COUNT - 1 then
                    -- Estable durante FILTER_COUNT ciclos → actualizar estado limpio
                    btn_clean <= btn_sync1;
                    counter   <= 0;
                else
                    counter   <= counter + 1;
                end if;
            else
                counter <= 0;
            end if;
        end if;
    end process;

    -- Generación del pulso de 1 ciclo (flanco de bajada del botón = presionado)
    process(CLOCK_50, reset_n)
    begin
        if reset_n = '0' then
            btn_prev  <= '1';
            pulse_out <= '0';
        elsif rising_edge(CLOCK_50) then
            btn_prev <= btn_clean;
            -- Detecta flanco de bajada (botón presionado)
            if btn_clean = '0' and btn_prev = '1' then
                pulse_out <= '1';
            else
                pulse_out <= '0';
            end if;
        end if;
    end process;

end architecture rtl;
