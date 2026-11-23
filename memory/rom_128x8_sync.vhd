library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom_128x8_sync is
    port (
        clock    : in  std_logic;
        address  : in  std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0)
    );
end entity rom_128x8_sync;

architecture rtl of rom_128x8_sync is

    -- Opcodes del microcontrolador
    constant LDA_IMM : std_logic_vector(7 downto 0) := x"86";
    constant LDA_DIR : std_logic_vector(7 downto 0) := x"87";
    constant LDB_IMM : std_logic_vector(7 downto 0) := x"88";
    constant LDB_DIR : std_logic_vector(7 downto 0) := x"89";
    constant STA_DIR : std_logic_vector(7 downto 0) := x"96";
    constant STB_DIR : std_logic_vector(7 downto 0) := x"97";
    constant ADD_AB  : std_logic_vector(7 downto 0) := x"42";
    constant SUB_AB  : std_logic_vector(7 downto 0) := x"43";
    constant AND_AB  : std_logic_vector(7 downto 0) := x"44";
    constant OR_AB   : std_logic_vector(7 downto 0) := x"45";
    constant INCA    : std_logic_vector(7 downto 0) := x"46";
    constant BRA     : std_logic_vector(7 downto 0) := x"20";
    constant BEQ     : std_logic_vector(7 downto 0) := x"23";

    type rom_type is array (0 to 127) of std_logic_vector(7 downto 0);

    -- Programa de prueba: LDA_IMM 0xAA → STA_DIR 0xE0 → BRA 0x00 (loop)
    constant ROM_DATA : rom_type := (
        0  => LDA_IMM,  -- LDA #0xAA
        1  => x"AA",
        2  => STA_DIR,  -- STA 0xE0  (port_out_00)
        3  => x"E0",
        4  => BRA,      -- BRA 0x00  (loop infinito)
        5  => x"00",
        others => x"00"
    );

    -- Señal interna EN: activa ('1') exclusivamente en rango 0..127
    signal EN : std_logic;

    -- Señal de salida interna registrada
    signal data_reg : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- Condición de rango para evitar accesos fuera de límites del arreglo
    EN <= '1' when (to_integer(unsigned(address)) >= 0 and to_integer(unsigned(address)) <= 127) else '0';

    process(clock)
        variable addr_int : integer;
    begin
        if rising_edge(clock) then
            if EN = '1' then
                addr_int := to_integer(unsigned(address));
                data_reg <= ROM_DATA(addr_int);
            else
                data_reg <= (others => '0');
            end if;
        end if;
    end process;

    data_out <= data_reg;

end architecture rtl;
