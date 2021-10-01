library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    generic(data_width: integer);
    port(
        opcode: in std_ulogic_vector(2 downto 0);

        lhs: in std_ulogic_vector((data_width - 1) downto 0);
        rhs: in std_ulogic_vector((data_width - 1) downto 0);
        carry_in: in std_ulogic;

        result: out std_ulogic_vector((data_width - 1) downto 0);
        carry_out: out std_ulogic
    );
end entity;

architecture struct of alu is
    constant OPCODE_AND: std_ulogic_vector(2 downto 0) := "000";
    constant OPCODE_OR:  std_ulogic_vector(2 downto 0) := "001";
    constant OPCODE_XOR: std_ulogic_vector(2 downto 0) := "010";
    constant OPCODE_NOT: std_ulogic_vector(2 downto 0) := "011";
    constant OPCODE_ADD: std_ulogic_vector(2 downto 0) := "100";
    constant OPCODE_INC: std_ulogic_vector(2 downto 0) := "101";
begin
    process(opcode, lhs, rhs, carry_in)
        variable lhs_unsigned: unsigned(data_width downto 0);
        variable carry: unsigned(0 downto 0);

        procedure arithmetic_result(
            constant res: in unsigned(data_width downto 0)
        ) is
        begin
            result <= std_ulogic_vector(res((data_width - 1) downto 0));
            carry_out <= res(data_width);
        end procedure;
    begin
        lhs_unsigned := unsigned('0' & lhs);
        carry := (0 => carry_in);

        case opcode is
            when OPCODE_AND =>
                result <= lhs and rhs;

            when OPCODE_OR =>
                result <= lhs or rhs;

            when OPCODE_XOR =>
                result <= lhs xor rhs;

            when OPCODE_NOT =>
                result <= not lhs;

            when OPCODE_ADD =>
                arithmetic_result(lhs_unsigned + unsigned('0' & rhs) + carry);

            when OPCODE_INC =>
                arithmetic_result(lhs_unsigned + to_unsigned(1, data_width + 1) + carry);

            when others =>
                result <= (others => 'X');
        end case;
    end process;
end architecture;
