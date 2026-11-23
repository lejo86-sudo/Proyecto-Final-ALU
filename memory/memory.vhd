library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
    port (
        clock      : in  std_logic;
        reset      : in  std_logic;                     -- Activo en bajo ('0')
        write      : in  std_logic;
        address    : in  std_logic_vector(7 downto 0);
        data_in    : in  std_logic_vector(7 downto 0);
        data_out   : out std_logic_vector(7 downto 0);
        -- 16 puertos de entrada (0xF0-0xFF)
        port_in_00 : in  std_logic_vector(7 downto 0);
        port_in_01 : in  std_logic_vector(7 downto 0);
        port_in_02 : in  std_logic_vector(7 downto 0);
        port_in_03 : in  std_logic_vector(7 downto 0);
        port_in_04 : in  std_logic_vector(7 downto 0);
        port_in_05 : in  std_logic_vector(7 downto 0);
        port_in_06 : in  std_logic_vector(7 downto 0);
        port_in_07 : in  std_logic_vector(7 downto 0);
        port_in_08 : in  std_logic_vector(7 downto 0);
        port_in_09 : in  std_logic_vector(7 downto 0);
        port_in_10 : in  std_logic_vector(7 downto 0);
        port_in_11 : in  std_logic_vector(7 downto 0);
        port_in_12 : in  std_logic_vector(7 downto 0);
        port_in_13 : in  std_logic_vector(7 downto 0);
        port_in_14 : in  std_logic_vector(7 downto 0);
        port_in_15 : in  std_logic_vector(7 downto 0);
        -- 16 puertos de salida (0xE0-0xEF)
        port_out_00 : out std_logic_vector(7 downto 0);
        port_out_01 : out std_logic_vector(7 downto 0);
        port_out_02 : out std_logic_vector(7 downto 0);
        port_out_03 : out std_logic_vector(7 downto 0);
        port_out_04 : out std_logic_vector(7 downto 0);
        port_out_05 : out std_logic_vector(7 downto 0);
        port_out_06 : out std_logic_vector(7 downto 0);
        port_out_07 : out std_logic_vector(7 downto 0);
        port_out_08 : out std_logic_vector(7 downto 0);
        port_out_09 : out std_logic_vector(7 downto 0);
        port_out_10 : out std_logic_vector(7 downto 0);
        port_out_11 : out std_logic_vector(7 downto 0);
        port_out_12 : out std_logic_vector(7 downto 0);
        port_out_13 : out std_logic_vector(7 downto 0);
        port_out_14 : out std_logic_vector(7 downto 0);
        port_out_15 : out std_logic_vector(7 downto 0)
    );
end entity memory;

architecture rtl of memory is

    -- Señales internas ROM y RAM
    signal rom_data_out : std_logic_vector(7 downto 0);
    signal ram_data_out : std_logic_vector(7 downto 0);

    -- Registros de los puertos de salida (reset asíncrono activo en bajo)
    signal port_out_reg_00 : std_logic_vector(7 downto 0);
    signal port_out_reg_01 : std_logic_vector(7 downto 0);
    signal port_out_reg_02 : std_logic_vector(7 downto 0);
    signal port_out_reg_03 : std_logic_vector(7 downto 0);
    signal port_out_reg_04 : std_logic_vector(7 downto 0);
    signal port_out_reg_05 : std_logic_vector(7 downto 0);
    signal port_out_reg_06 : std_logic_vector(7 downto 0);
    signal port_out_reg_07 : std_logic_vector(7 downto 0);
    signal port_out_reg_08 : std_logic_vector(7 downto 0);
    signal port_out_reg_09 : std_logic_vector(7 downto 0);
    signal port_out_reg_10 : std_logic_vector(7 downto 0);
    signal port_out_reg_11 : std_logic_vector(7 downto 0);
    signal port_out_reg_12 : std_logic_vector(7 downto 0);
    signal port_out_reg_13 : std_logic_vector(7 downto 0);
    signal port_out_reg_14 : std_logic_vector(7 downto 0);
    signal port_out_reg_15 : std_logic_vector(7 downto 0);

begin

    -- -------------------------------------------------------------------------
    -- Instancia ROM 128×8
    -- -------------------------------------------------------------------------
    u_rom : entity work.rom_128x8_sync
        port map (
            clock    => clock,
            address  => address,
            data_out => rom_data_out
        );

    -- -------------------------------------------------------------------------
    -- Instancia RAM 96×8
    -- -------------------------------------------------------------------------
    u_ram : entity work.rw_96x8_sync
        port map (
            clock    => clock,
            write    => write,
            address  => address,
            data_in  => data_in,
            data_out => ram_data_out
        );

    -- -------------------------------------------------------------------------
    -- Puertos de salida (0xE0-0xEF) con reset asíncrono activo en bajo
    -- -------------------------------------------------------------------------
    process(clock, reset)
        variable addr_int : integer;
    begin
        if reset = '0' then
            -- Reset asíncrono: todos los puertos a cero
            port_out_reg_00 <= x"00";
            port_out_reg_01 <= x"00";
            port_out_reg_02 <= x"00";
            port_out_reg_03 <= x"00";
            port_out_reg_04 <= x"00";
            port_out_reg_05 <= x"00";
            port_out_reg_06 <= x"00";
            port_out_reg_07 <= x"00";
            port_out_reg_08 <= x"00";
            port_out_reg_09 <= x"00";
            port_out_reg_10 <= x"00";
            port_out_reg_11 <= x"00";
            port_out_reg_12 <= x"00";
            port_out_reg_13 <= x"00";
            port_out_reg_14 <= x"00";
            port_out_reg_15 <= x"00";
        elsif rising_edge(clock) then
            addr_int := to_integer(unsigned(address));
            if write = '1' then
                case addr_int is
                    when 224 => port_out_reg_00 <= data_in;  -- 0xE0
                    when 225 => port_out_reg_01 <= data_in;  -- 0xE1
                    when 226 => port_out_reg_02 <= data_in;  -- 0xE2
                    when 227 => port_out_reg_03 <= data_in;  -- 0xE3
                    when 228 => port_out_reg_04 <= data_in;  -- 0xE4
                    when 229 => port_out_reg_05 <= data_in;  -- 0xE5
                    when 230 => port_out_reg_06 <= data_in;  -- 0xE6
                    when 231 => port_out_reg_07 <= data_in;  -- 0xE7
                    when 232 => port_out_reg_08 <= data_in;  -- 0xE8
                    when 233 => port_out_reg_09 <= data_in;  -- 0xE9
                    when 234 => port_out_reg_10 <= data_in;  -- 0xEA
                    when 235 => port_out_reg_11 <= data_in;  -- 0xEB
                    when 236 => port_out_reg_12 <= data_in;  -- 0xEC
                    when 237 => port_out_reg_13 <= data_in;  -- 0xED
                    when 238 => port_out_reg_14 <= data_in;  -- 0xEE
                    when 239 => port_out_reg_15 <= data_in;  -- 0xEF
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    -- Conexiones de puertos de salida
    port_out_00 <= port_out_reg_00;
    port_out_01 <= port_out_reg_01;
    port_out_02 <= port_out_reg_02;
    port_out_03 <= port_out_reg_03;
    port_out_04 <= port_out_reg_04;
    port_out_05 <= port_out_reg_05;
    port_out_06 <= port_out_reg_06;
    port_out_07 <= port_out_reg_07;
    port_out_08 <= port_out_reg_08;
    port_out_09 <= port_out_reg_09;
    port_out_10 <= port_out_reg_10;
    port_out_11 <= port_out_reg_11;
    port_out_12 <= port_out_reg_12;
    port_out_13 <= port_out_reg_13;
    port_out_14 <= port_out_reg_14;
    port_out_15 <= port_out_reg_15;

    -- -------------------------------------------------------------------------
    -- Multiplexor combinacional de data_out (sin latches)
    -- -------------------------------------------------------------------------
    process(address, rom_data_out, ram_data_out,
            port_in_00, port_in_01, port_in_02, port_in_03,
            port_in_04, port_in_05, port_in_06, port_in_07,
            port_in_08, port_in_09, port_in_10, port_in_11,
            port_in_12, port_in_13, port_in_14, port_in_15)
        variable addr_int : integer;
    begin
        addr_int := to_integer(unsigned(address));
        -- Valor por defecto para evitar latches inferidos
        data_out <= x"00";

        if    addr_int >= 0   and addr_int <= 127 then
            data_out <= rom_data_out;           -- 0x00-0x7F : ROM
        elsif addr_int >= 128 and addr_int <= 223 then
            data_out <= ram_data_out;           -- 0x80-0xDF : RAM
        elsif addr_int >= 240 and addr_int <= 255 then
            -- 0xF0-0xFF : puertos de entrada
            case addr_int is
                when 240 => data_out <= port_in_00;
                when 241 => data_out <= port_in_01;
                when 242 => data_out <= port_in_02;
                when 243 => data_out <= port_in_03;
                when 244 => data_out <= port_in_04;
                when 245 => data_out <= port_in_05;
                when 246 => data_out <= port_in_06;
                when 247 => data_out <= port_in_07;
                when 248 => data_out <= port_in_08;
                when 249 => data_out <= port_in_09;
                when 250 => data_out <= port_in_10;
                when 251 => data_out <= port_in_11;
                when 252 => data_out <= port_in_12;
                when 253 => data_out <= port_in_13;
                when 254 => data_out <= port_in_14;
                when 255 => data_out <= port_in_15;
                when others => data_out <= x"00";
            end case;
        else
            data_out <= x"00";                  -- 0xE0-0xEF y otros → 0x00
        end if;
    end process;

end architecture rtl;
