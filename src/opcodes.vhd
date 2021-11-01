library ieee;
use ieee.std_logic_1164.all;

package opcodes is
    -- ALU opcodes
    subtype alu_opcode is std_ulogic_vector(2 downto 0);

    constant ALU_OP_AND:    alu_opcode := "000";
    constant ALU_OP_OR:     alu_opcode := "001";
    constant ALU_OP_XOR:    alu_opcode := "010";
    constant ALU_OP_NOT:    alu_opcode := "011";
    constant ALU_OP_ADD:    alu_opcode := "100";
    constant ALU_OP_INC:    alu_opcode := "101";
    constant ALU_OP_LSHIFT: alu_opcode := "110";
    constant ALU_OP_RSHIFT: alu_opcode := "111";

    -- CPU opcodes
    subtype cpu_opcode is std_ulogic_vector(4 downto 0);

    constant OP_NOP:      cpu_opcode := "00000";
    constant OP_HALT:     cpu_opcode := "00001";
    constant OP_COPY:     cpu_opcode := "00010";
    constant OP_LOAD:     cpu_opcode := "00011";
    constant OP_STORE:    cpu_opcode := "00100";
    constant OP_SET_PAGE: cpu_opcode := "00101";
    constant OP_JUMP:     cpu_opcode := "00110";
    constant OP_JUMP_Z:   cpu_opcode := "01000";
    constant OP_JUMP_C:   cpu_opcode := "01001";
    constant OP_JUMP_NZ:  cpu_opcode := "01010";
    constant OP_JUMP_NC:  cpu_opcode := "01011";
    constant OP_ADD:      cpu_opcode := "10" & ALU_OP_ADD;
    constant OP_INC:      cpu_opcode := "10" & ALU_OP_INC;
    constant OP_LSHIFT:  cpu_opcode  := "10" & ALU_OP_LSHIFT;
    constant OP_RSHIFT:  cpu_opcode  := "10" & ALU_OP_RSHIFT;
    constant OP_AND:      cpu_opcode := "11" & ALU_OP_AND;
    constant OP_OR:       cpu_opcode := "11" & ALU_OP_OR;
    constant OP_XOR:      cpu_opcode := "11" & ALU_OP_XOR;
    constant OP_NOT:      cpu_opcode := "11" & ALU_OP_NOT;
    constant OP_ADD_C:    cpu_opcode := "11" & ALU_OP_ADD;
    constant OP_INC_C:    cpu_opcode := "11" & ALU_OP_INC;
    constant OP_LSHIFT_C: cpu_opcode := "11" & ALU_OP_LSHIFT;
    constant OP_RSHIFT_C: cpu_opcode := "11" & ALU_OP_RSHIFT;
end package;
