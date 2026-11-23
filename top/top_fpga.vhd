library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_fpga is
    generic (
        DEBOUNCE_FILTER : integer := 1_000_000  -- 20 ms @ 50 MHz en síntesis
    );
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(2 downto 0);    -- Activos en bajo
        SW       : in  std_logic_vector(9 downto 0);    -- 10 switches integrados
        EXT_SW   : in  std_logic_vector(11 downto 0);   -- DIP switch externo GPIO0
        LEDG     : out std_logic_vector(9 downto 0);    -- LEDs verdes
        HEX0     : out std_logic_vector(6 downto 0);    -- Display 7-seg (activo en bajo)
        HEX1     : out std_logic_vector(6 downto 0);
        HEX2     : out std_logic_vector(6 downto 0);
        HEX3     : out std_logic_vector(6 downto 0)
    );
end entity top_fpga;

architecture rtl of top_fpga is

    -- Señales internas de la ALU
    signal A          : std_logic_vector(7 downto 0);
    signal B          : std_logic_vector(7 downto 0);
    signal ALU_Sel    : std_logic_vector(2 downto 0);
    signal ALU_Result : std_logic_vector(7 downto 0);
    signal NZVC       : std_logic_vector(3 downto 0);

    -- Señales de control y bus de memoria
    signal address    : std_logic_vector(7 downto 0);
    signal data_in    : std_logic_vector(7 downto 0);
    signal data_out   : std_logic_vector(7 downto 0);
    signal write_sig  : std_logic;
    signal mem_write  : std_logic;
    signal reset_n    : std_logic;
    signal clock_en   : std_logic;
    signal signed_mode: std_logic;
    signal disp_mode  : std_logic;

    -- Señales del conversor BCD
    signal bcd_in     : std_logic_vector(8 downto 0);
    signal bcd_hund   : std_logic_vector(3 downto 0);
    signal bcd_tens   : std_logic_vector(3 downto 0);
    signal bcd_units  : std_logic_vector(3 downto 0);
    signal neg_sign   : std_logic;

    -- Señales multiplexadas para displays de 7 segmentos (VHDL-1993 compatible)
    signal hex0_in    : std_logic_vector(3 downto 0);
    signal hex1_in    : std_logic_vector(3 downto 0);
    signal hex2_in    : std_logic_vector(3 downto 0);
    signal hex3_in    : std_logic_vector(3 downto 0);
    signal hex3_blank : std_logic;
    signal hex3_minus : std_logic;

    -- Conexión de todos los 16 puertos de entrada de memoria (sin señales flotantes)
    signal port_in_00  : std_logic_vector(7 downto 0);
    signal port_in_01  : std_logic_vector(7 downto 0);
    signal port_in_02  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_03  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_04  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_05  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_06  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_07  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_08  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_09  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_10  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_11  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_12  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_13  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_14  : std_logic_vector(7 downto 0) := (others => '0');
    signal port_in_15  : std_logic_vector(7 downto 0) := (others => '0');

    -- Conexión de todos los 16 puertos de salida de memoria (cero puertos 'open')
    signal port_out_00 : std_logic_vector(7 downto 0);
    signal port_out_01 : std_logic_vector(7 downto 0);
    signal port_out_02 : std_logic_vector(7 downto 0);
    signal port_out_03 : std_logic_vector(7 downto 0);
    signal port_out_04 : std_logic_vector(7 downto 0);
    signal port_out_05 : std_logic_vector(7 downto 0);
    signal port_out_06 : std_logic_vector(7 downto 0);
    signal port_out_07 : std_logic_vector(7 downto 0);
    signal port_out_08 : std_logic_vector(7 downto 0);
    signal port_out_09 : std_logic_vector(7 downto 0);
    signal port_out_10 : std_logic_vector(7 downto 0);
    signal port_out_11 : std_logic_vector(7 downto 0);
    signal port_out_12 : std_logic_vector(7 downto 0);
    signal port_out_13 : std_logic_vector(7 downto 0);
    signal port_out_14 : std_logic_vector(7 downto 0);
    signal port_out_15 : std_logic_vector(7 downto 0);

    -- Señal interna de switches externos
    signal ext_sw_int : std_logic_vector(11 downto 0);

begin

    -- -------------------------------------------------------------------------
    -- Asignaciones de control y buses
    -- -------------------------------------------------------------------------
    ext_sw_int  <= EXT_SW;
    reset_n     <= KEY(0);              -- Reset maestro activo en bajo
    write_sig   <= ext_sw_int(9);       -- 1=Escribir, 0=Leer
    signed_mode <= ext_sw_int(10);      -- 0=Sin signo, 1=Complemento a 2
    disp_mode   <= ext_sw_int(11);      -- 0=Decimal ALU, 1=Debug Hex memoria

    -- Operandos ALU
    A       <= SW(7 downto 0);
    B       <= ext_sw_int(7 downto 0);
    ALU_Sel <= ext_sw_int(8) & SW(9 downto 8);  -- "000" = suma A+B

    -- Bus de memoria
    address <= SW(7 downto 0);
    data_in <= ext_sw_int(7 downto 0);

    -- Puertos mapeados de entrada
    port_in_00 <= SW(7 downto 0);
    port_in_01 <= ext_sw_int(7 downto 0);

    -- Habilitación limpia de escritura sincronizada con el pulso del debouncer
    mem_write <= write_sig and clock_en;

    -- -------------------------------------------------------------------------
    -- Debouncer para KEY[1] (pulso limpio de 1 ciclo CLOCK_50)
    -- -------------------------------------------------------------------------
    u_debouncer : entity work.debouncer
        generic map (
            FILTER_COUNT => DEBOUNCE_FILTER
        )
        port map (
            CLOCK_50  => CLOCK_50,
            reset_n   => reset_n,
            btn_in    => KEY(1),
            pulse_out => clock_en
        );

    -- -------------------------------------------------------------------------
    -- Unidad Aritmético-Lógica (100% combinacional)
    -- -------------------------------------------------------------------------
    u_alu : entity work.alu
        generic map (
            CARRY_IS_NOT_BORROW => true
        )
        port map (
            A          => A,
            B          => B,
            ALU_Sel    => ALU_Sel,
            ALU_Result => ALU_Result,
            NZVC       => NZVC
        );

    -- -------------------------------------------------------------------------
    -- Subsistema de Memoria (ROM + RAM + 16 Puertos I/O)
    -- -------------------------------------------------------------------------
    u_memory : entity work.memory
        port map (
            clock       => CLOCK_50,
            reset       => reset_n,
            write       => mem_write,
            address     => address,
            data_in     => data_in,
            data_out    => data_out,
            port_in_00  => port_in_00,
            port_in_01  => port_in_01,
            port_in_02  => port_in_02,
            port_in_03  => port_in_03,
            port_in_04  => port_in_04,
            port_in_05  => port_in_05,
            port_in_06  => port_in_06,
            port_in_07  => port_in_07,
            port_in_08  => port_in_08,
            port_in_09  => port_in_09,
            port_in_10  => port_in_10,
            port_in_11  => port_in_11,
            port_in_12  => port_in_12,
            port_in_13  => port_in_13,
            port_in_14  => port_in_14,
            port_in_15  => port_in_15,
            port_out_00 => port_out_00,
            port_out_01 => port_out_01,
            port_out_02 => port_out_02,
            port_out_03 => port_out_03,
            port_out_04 => port_out_04,
            port_out_05 => port_out_05,
            port_out_06 => port_out_06,
            port_out_07 => port_out_07,
            port_out_08 => port_out_08,
            port_out_09 => port_out_09,
            port_out_10 => port_out_10,
            port_out_11 => port_out_11,
            port_out_12 => port_out_12,
            port_out_13 => port_out_13,
            port_out_14 => port_out_14,
            port_out_15 => port_out_15
        );

    -- -------------------------------------------------------------------------
    -- Conversor BCD (Double Dabble)
    -- El 9° bit de acarreo (NZVC(0)) solo se concatena en SUMA sin signo (0-510).
    -- En resta y demás operaciones, el resultado es de 8 bits (bit 8 = '0').
    -- -------------------------------------------------------------------------
    bcd_in <= NZVC(0) & ALU_Result when (signed_mode = '0' and ALU_Sel = "000") else
              '0'     & ALU_Result;

    u_bcd : entity work.bin8_to_bcd
        port map (
            bin_in      => bcd_in,
            signed_mode => signed_mode,
            hundreds    => bcd_hund,
            tens        => bcd_tens,
            bcd_units   => bcd_units,
            neg_sign    => neg_sign
        );

    -- -------------------------------------------------------------------------
    -- Multiplexación combinacional para Displays (VHDL-1993 compatible)
    -- -------------------------------------------------------------------------
    -- En modo decimal (disp_mode = '0'):
    --   HEX3: signo negativo '-' si neg_sign='1', apagado si positivo
    --   HEX2: centenas BCD
    --   HEX1: decenas BCD
    --   HEX0: unidades BCD
    -- En modo debug hex (disp_mode = '1'):
    --   HEX3:HEX2 = data_out de memoria (MSB : LSB)
    --   HEX1:HEX0 = ALU_Result (MSB : LSB)

    hex0_in <= ALU_Result(3 downto 0) when disp_mode = '1' else bcd_units;
    hex1_in <= ALU_Result(7 downto 4) when disp_mode = '1' else bcd_tens;
    hex2_in <= data_out(3 downto 0)   when disp_mode = '1' else bcd_hund;
    hex3_in <= data_out(7 downto 4);

    hex3_blank <= '1' when (disp_mode = '0' and neg_sign = '0') else '0';
    hex3_minus <= '1' when (disp_mode = '0' and neg_sign = '1') else '0';

    u_hex0 : entity work.hex7seg
        port map (
            hex_in  => hex0_in,
            blank   => '0',
            minus   => '0',
            seg_out => HEX0
        );

    u_hex1 : entity work.hex7seg
        port map (
            hex_in  => hex1_in,
            blank   => '0',
            minus   => '0',
            seg_out => HEX1
        );

    u_hex2 : entity work.hex7seg
        port map (
            hex_in  => hex2_in,
            blank   => '0',
            minus   => '0',
            seg_out => HEX2
        );

    u_hex3 : entity work.hex7seg
        port map (
            hex_in  => hex3_in,
            blank   => hex3_blank,
            minus   => hex3_minus,
            seg_out => HEX3
        );

    -- -------------------------------------------------------------------------
    -- Salidas a LEDs de la placa DE0
    -- -------------------------------------------------------------------------
    LEDG(3 downto 0) <= NZVC;                     -- Banderas de estado ALU
    LEDG(4)          <= disp_mode;                -- 0=Decimal, 1=Hexadecimal
    LEDG(5)          <= write_sig;                -- Interruptor de escritura
    LEDG(9 downto 6) <= port_out_00(3 downto 0);  -- Puerto de salida mapeado

end architecture rtl;
