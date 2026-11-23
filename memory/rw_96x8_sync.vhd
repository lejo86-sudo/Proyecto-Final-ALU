library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rw_96x8_sync is
    port (
        clock    : in  std_logic;
        write    : in  std_logic;
        address  : in  std_logic_vector(7 downto 0);
        data_in  : in  std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0)
    );
end entity rw_96x8_sync;

architecture rtl of rw_96x8_sync is

    type rw_type is array (128 to 223) of std_logic_vector(7 downto 0);
    signal RAM : rw_type := (others => (others => '0'));

    -- Señal interna EN: activa ('1') exclusivamente en rango 128..223
    signal EN : std_logic;

    -- Señal de salida interna registrada
    signal data_reg : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- Condición de rango para proteger acceso al arreglo RAM(128 to 223)
    EN <= '1' when (to_integer(unsigned(address)) >= 128 and to_integer(unsigned(address)) <= 223) else '0';

    process(clock)
        variable addr_int : integer;
    begin
        if rising_edge(clock) then
            if EN = '1' then
                addr_int := to_integer(unsigned(address));
                if write = '1' then
                    RAM(addr_int) <= data_in;
                else
                    data_reg <= RAM(addr_int);
                end if;
            else
                data_reg <= (others => '0');
            end if;
        end if;
    end process;

    data_out <= data_reg;

end architecture rtl;
