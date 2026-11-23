-- Operaciones según ALU_Sel (3 bits):
--   "000" : ADD  – A + B
--   "001" : SUB  – A - B
--   "010" : AND  – A AND B
--   "011" : OR   – A OR  B
--   "100" : XOR  – A XOR B
--   "101" : INC  – A + 1
--   "110" : DEC  – A - 1
--   "111" : NOT  – NOT A
--
-- Banderas NZVC (bit 3=N, 2=Z, 1=V, 0=C):
--   N – Negative  : Result(7)
--   Z – Zero      : '1' cuando Result = 0x00
--   V – Overflow  : desbordamiento en complemento a 2
--   C – Carry     : acarreo sin signo (generic CARRY_IS_NOT_BORROW)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    generic (
        -- true  → convención ARM: C='1' cuando A >= B (sin préstamo)
        -- false → convención Borrow: C='1' cuando hay préstamo (A < B)
        CARRY_IS_NOT_BORROW : boolean := true
    );
    port (
        A          : in  std_logic_vector(7 downto 0);
        B          : in  std_logic_vector(7 downto 0);
        ALU_Sel    : in  std_logic_vector(2 downto 0);
        ALU_Result : out std_logic_vector(7 downto 0);
        NZVC       : out std_logic_vector(3 downto 0)  -- (3)=N (2)=Z (1)=V (0)=C
    );
end entity alu;

architecture rtl of alu is
begin

    -- Proceso 100% combinacional con todas las entradas en lista de sensibilidad
    process(A, B, ALU_Sel)
        variable A_uns   : unsigned(8 downto 0);
        variable B_uns   : unsigned(8 downto 0);
        variable Sum_uns : unsigned(8 downto 0);
        variable Result  : std_logic_vector(7 downto 0);
        variable N_flag  : std_logic;
        variable Z_flag  : std_logic;
        variable V_flag  : std_logic;
        variable C_flag  : std_logic;
    begin
        -- Extensión a 9 bits sin signo para captura exacta de carry/borrow
        A_uns := unsigned('0' & A);
        B_uns := unsigned('0' & B);

        -- Inicializaciones por defecto para garantizar cero latches inferidos
        Sum_uns := (others => '0');
        Result  := (others => '0');
        N_flag  := '0';
        Z_flag  := '0';
        V_flag  := '0';
        C_flag  := '0';

        case ALU_Sel is

            -- ----------------------------------------------------------------
            -- "000" : ADD  –  A + B
            -- ----------------------------------------------------------------
            when "000" =>
                Sum_uns := A_uns + B_uns;
                Result  := std_logic_vector(Sum_uns(7 downto 0));
                -- Carry sin signo: bit 8 de suma extendida
                C_flag  := Sum_uns(8);
                -- Overflow C2: regla estricta (A=0,B=0,R=1) o (A=1,B=1,R=0)
                V_flag  := (not A(7) and not B(7) and Result(7)) or
                           (A(7) and B(7) and not Result(7));

            -- ----------------------------------------------------------------
            -- "001" : SUB  –  A - B
            -- ----------------------------------------------------------------
            when "001" =>
                Sum_uns := A_uns - B_uns;
                Result  := std_logic_vector(Sum_uns(7 downto 0));
                -- Carry/Borrow sin signo según convención seleccionada
                if CARRY_IS_NOT_BORROW then
                    -- ARM: C='1' cuando A >= B (sin préstamo)
                    C_flag := not Sum_uns(8);
                else
                    -- Borrow estándar: C='1' cuando A < B
                    C_flag := Sum_uns(8);
                end if;
                -- Overflow C2: regla estricta (A=0,B=1,R=1) o (A=1,B=0,R=0)
                V_flag := (not A(7) and B(7) and Result(7)) or
                          (A(7) and not B(7) and not Result(7));

            -- ----------------------------------------------------------------
            -- "010" : AND
            -- ----------------------------------------------------------------
            when "010" =>
                Result := A and B;
                C_flag := '0';
                V_flag := '0';

            -- ----------------------------------------------------------------
            -- "011" : OR
            -- ----------------------------------------------------------------
            when "011" =>
                Result := A or B;
                C_flag := '0';
                V_flag := '0';

            -- ----------------------------------------------------------------
            -- "100" : XOR
            -- ----------------------------------------------------------------
            when "100" =>
                Result := A xor B;
                C_flag := '0';
                V_flag := '0';

            -- ----------------------------------------------------------------
            -- "101" : INC  –  A + 1
            -- ----------------------------------------------------------------
            when "101" =>
                Sum_uns := A_uns + to_unsigned(1, 9);
                Result  := std_logic_vector(Sum_uns(7 downto 0));
                C_flag  := Sum_uns(8);
                -- Overflow C2: 0x7F (+127) + 1 = 0x80 (-128)
                V_flag  := (not A(7)) and Result(7);

            -- ----------------------------------------------------------------
            -- "110" : DEC  –  A - 1
            -- ----------------------------------------------------------------
            when "110" =>
                Sum_uns := A_uns - to_unsigned(1, 9);
                Result  := std_logic_vector(Sum_uns(7 downto 0));
                if CARRY_IS_NOT_BORROW then
                    C_flag := not Sum_uns(8);
                else
                    C_flag := Sum_uns(8);
                end if;
                -- Overflow C2: 0x80 (-128) - 1 = 0x7F (+127)
                V_flag := A(7) and (not Result(7));

            -- ----------------------------------------------------------------
            -- "111" : NOT A
            -- ----------------------------------------------------------------
            when others =>  -- "111"
                Result := not A;
                C_flag := '0';
                V_flag := '0';

        end case;

        -- Banderas N y Z universales
        N_flag := Result(7);
        if Result = x"00" then
            Z_flag := '1';
        else
            Z_flag := '0';
        end if;

        -- Asignación final a salidas
        ALU_Result <= Result;
        NZVC       <= N_flag & Z_flag & V_flag & C_flag;

    end process;

end architecture rtl;
