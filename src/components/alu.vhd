library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.opcodes.all;

entity alu is
    generic(data_width: integer);
    port(
        opcode: in alu_opcode;

        lhs: in std_ulogic_vector((data_width - 1) downto 0);
        rhs: in std_ulogic_vector((data_width - 1) downto 0);
        carry_in: in std_ulogic;

        result: out std_ulogic_vector((data_width - 1) downto 0);
        carry_out: out std_ulogic
    );
end entity;

architecture struct of alu is
begin
    process(opcode, lhs, rhs, carry_in)
        variable add_result: unsigned(data_width downto 0);
    begin
        carry_out <= '0';

        case opcode is
            when ALU_OP_AND =>
                result <= lhs and rhs;

            when ALU_OP_OR =>
                result <= lhs or rhs;

            when ALU_OP_XOR =>
                result <= lhs xor rhs;

            when ALU_OP_NOT =>
                result <= not lhs;

            when ALU_OP_ADD =>
                add_result := unsigned('0' & lhs) + unsigned('0' & rhs) + ("" & carry_in);
                result <= std_ulogic_vector(add_result((data_width - 1) downto 0));
                carry_out <= add_result(data_width);

            when ALU_OP_LSHIFT =>
                carry_out <= lhs(data_width - 1);
                result((data_width - 1) downto 1) <= lhs((data_width - 2) downto 0);
                result(0) <= carry_in;

            when ALU_OP_RSHIFT =>
                carry_out <= lhs(0);
                result((data_width - 2) downto 0) <= lhs((data_width - 1) downto 1);
                result(data_width - 1) <= carry_in;

            when others =>
                result <= (others => 'X');
                carry_out <= 'X';
        end case;
    end process;
end architecture;
