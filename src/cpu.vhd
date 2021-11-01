library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.opcodes.all;

entity cpu is
    generic(bit_serial: boolean);
    port(
        clock: in std_ulogic;
        n_reset: in std_ulogic;

        mem_read: in std_ulogic_vector(7 downto 0);
        mem_write: out std_ulogic_vector(7 downto 0);
        mem_addr: out unsigned(11 downto 0);
        mem_write_enable: out std_ulogic;

        halted: out std_ulogic;
        errored: out std_ulogic
    );
end entity;

architecture rtl of cpu is
    signal halt: std_ulogic;
    signal carry: std_ulogic;
    signal zero: std_ulogic;

    signal c_in: std_ulogic;
    signal z_in: std_ulogic;

    signal opcode: cpu_opcode;
    signal operand_rx: std_ulogic_vector(3 downto 0);
    signal operand_ry: std_ulogic_vector(3 downto 0);
    signal operand_index: std_ulogic_vector(6 downto 0);
    signal operand_immediate: std_ulogic_vector(10 downto 0);

    signal rx_in: std_ulogic_vector(7 downto 0);
    signal rx_out: std_ulogic_vector(7 downto 0);
    signal ry_out: std_ulogic_vector(7 downto 0);
    signal alu_result: std_ulogic_vector(7 downto 0);

    signal alu_carry: std_ulogic;

    signal pc_in: unsigned(11 downto 0);
    signal pc_out: unsigned(11 downto 0);
    signal pc_increment: unsigned(11 downto 0);
    signal indexed_addr: unsigned(11 downto 0);

    signal ir_out: std_ulogic_vector(15 downto 0);
    signal pg_out: std_ulogic_vector(4 downto 0);

    signal selected_test: std_ulogic;
    signal test: std_ulogic;

    -- Control lines
    signal rx_write_enable: std_ulogic;
    signal pc_write_enable: std_ulogic;
    signal pg_write_enable: std_ulogic;
    signal irh_write_enable: std_ulogic;
    signal irl_write_enable: std_ulogic;
    signal c_write_enable: std_ulogic;
    signal z_write_enable: std_ulogic;
    signal addr_select: std_ulogic;
    signal pc_in_select: std_ulogic;
    signal rx_in_select: std_ulogic_vector(1 downto 0);
    signal c_in_select: std_ulogic;

    -- Select constants
    constant ADDR_SELECT_PC: std_ulogic := '0';
    constant ADDR_SELECT_INDEXED: std_ulogic := '1';

    constant PC_IN_SELECT_INCREMENT: std_ulogic := '0';
    constant PC_IN_SELECT_OPERAND: std_ulogic := '1';

    constant RX_IN_SELECT_LOAD: std_ulogic_vector(1 downto 0) := "00";
    constant RX_IN_SELECT_RY: std_ulogic_vector(1 downto 0) := "01";
    constant RX_IN_SELECT_ALU: std_ulogic_vector(1 downto 0) := "10";

    constant C_IN_SELECT_CLEAR: std_ulogic := '0';
    constant C_IN_SELECT_ALU: std_ulogic := '1';

    constant TEST_SELECT_ZERO: std_ulogic := '0';
    constant TEST_SELECT_CARRY: std_ulogic := '1';

    type cpu_state is (
        -- Fetch
        FETCH_HIGH,
        INC_PC_1,
        FETCH_LOW,
        INC_PC_2,

        -- Decode
        DECODE,

        -- Execute
        EXECUTE_NOP,
        EXECUTE_HALT,
        EXECUTE_COPY,
        EXECUTE_LOAD,
        EXECUTE_STORE,
        EXECUTE_SET_PAGE,
        EXECUTE_JUMP,
        EXECUTE_TEST,
        EXECUTE_CLEAR_CARRY,
        EXECUTE_ALU_OP,
        EXECUTE_END,

        -- Error
        ERROR
    );
    signal state: cpu_state;
begin
    regfile: entity work.parallel_register_file(rtl)
        generic map(data_width => 8)
        port map(
            clock => clock,
            n_reset => n_reset,
            x_select => operand_rx,
            x_write_enable => rx_write_enable,
            x_in => rx_in,
            std_ulogic_vector(x_out) => rx_out,
            y_select => operand_ry,
            std_ulogic_vector(y_out) => ry_out
        );

    alu: entity work.alu(struct)
        generic map(data_width => 8)
        port map(
            opcode => opcode(2 downto 0),
            lhs => rx_out,
            rhs => ry_out,
            carry_in => carry,
            result => alu_result,
            carry_out => alu_carry
        );

    -- IR is implemented as two 8-bit registers
    reg_irh: entity work.parallel_register(rtl)
        generic map(data_width => 8)
        port map(
            clock => clock,
            n_reset => n_reset,
            write_enable => irh_write_enable,
            data_in => mem_read,
            data_out => ir_out(15 downto 8)
        );
    reg_irl: entity work.parallel_register(rtl)
        generic map(data_width => 8)
        port map(
            clock => clock,
            n_reset => n_reset,
            write_enable => irl_write_enable,
            data_in => mem_read,
            data_out => ir_out(7 downto 0)
        );

    reg_pg: entity work.parallel_register(rtl)
        generic map(data_width => 5)
        port map(
            clock => clock,
            n_reset => n_reset,
            write_enable => pg_write_enable,
            data_in => operand_immediate(4 downto 0),
            data_out => pg_out
        );

    reg_pc: entity work.parallel_register(rtl)
        generic map(data_width => 12)
        port map(
            clock => clock,
            n_reset => n_reset,
            write_enable => pc_write_enable,
            data_in => std_ulogic_vector(pc_in),
            unsigned(data_out) => pc_out
        );

    pc_inc: entity work.incrementer(struct)
        generic map(data_width => 12)
        port map(
            data_in => pc_out,
            data_out => pc_increment
        );

    -- Flags
    carry_flag: entity work.flag(rtl)
        port map(
            clock => clock,
            n_reset => n_reset,
            write_enable => c_write_enable,
            data_in => c_in,
            data_out => carry
        );
    zero_flag: entity work.flag(rtl)
        port map(
            clock => clock,
            n_reset => n_reset,
            write_enable => z_write_enable,
            data_in => z_in,
            data_out => zero
        );

    -- Mux processes
    mux_addr: with addr_select
    select mem_addr <=
        pc_out                           when ADDR_SELECT_PC,
        unsigned(pg_out & operand_index) when ADDR_SELECT_INDEXED,
        (others => 'X')                  when others;

    mux_pc_in: with pc_in_select
    select pc_in <=
        pc_increment                      when PC_IN_SELECT_INCREMENT,
        unsigned(operand_immediate & '0') when PC_IN_SELECT_OPERAND,
        (others => 'X')                   when others;

    mux_rx_in: with rx_in_select
    select rx_in <=
        mem_read        when RX_IN_SELECT_LOAD,
        ry_out          when RX_IN_SELECT_RY,
        alu_result      when RX_IN_SELECT_ALU,
        (others => 'X') when others;

    mux_c_in: with c_in_select
    select c_in <=
        '0'           when C_IN_SELECT_CLEAR,
        alu_carry     when C_IN_SELECT_ALU,
        'X'           when others;


    mux_test: with opcode(0)
    select selected_test <=
        zero  when TEST_SELECT_ZERO,
        carry when TEST_SELECT_CARRY,
        'X'   when others;

    test <= selected_test xor opcode(1);

    z_in <= '1' when alu_result = "00000000" else '0';

    mem_write <= rx_out;

    opcode <= ir_out(15 downto 11);
    operand_rx <= ir_out(10 downto 7);
    operand_ry <= ir_out(6 downto 3);
    operand_index <= ir_out(6 downto 0);
    operand_immediate <= ir_out(10 downto 0);

    process(clock, n_reset)
    begin
        mem_write_enable <= '0';
        rx_write_enable <= '0';
        pc_write_enable <= '0';
        pg_write_enable <= '0';
        irh_write_enable <= '0';
        irl_write_enable <= '0';
        c_write_enable <= '0';
        z_write_enable <= '0';
        addr_select <= '0';
        pc_in_select <= '0';
        rx_in_select <= "00";
        c_in_select <= '0';

        if n_reset = '0' then
            state <= FETCH_HIGH;
            halt <= '0';
            halted <= '0';
            errored <= '0';
        elsif falling_edge(clock) then
            case state is
                when FETCH_HIGH =>
                    irh_write_enable <= '1';
                    addr_select <= ADDR_SELECT_PC;
                    state <= INC_PC_1;

                when INC_PC_1 =>
                    pc_write_enable <= '1';
                    pc_in_select <= PC_IN_SELECT_INCREMENT;
                    state <= FETCH_LOW;

                when FETCH_LOW =>
                    irl_write_enable <= '1';
                    addr_select <= ADDR_SELECT_PC;
                    state <= INC_PC_2;

                when INC_PC_2 =>
                    pc_write_enable <= '1';
                    pc_in_select <= PC_IN_SELECT_INCREMENT;
                    state <= DECODE;

                when DECODE =>
                    case opcode is
                        when OP_NOP =>
                            state <= EXECUTE_NOP;
                        when OP_HALT =>
                            state <= EXECUTE_HALT;
                        when OP_COPY =>
                            state <= EXECUTE_COPY;
                        when OP_LOAD =>
                            state <= EXECUTE_LOAD;
                        when OP_STORE =>
                            state <= EXECUTE_STORE;
                        when OP_SET_PAGE =>
                            state <= EXECUTE_SET_PAGE;
                        when OP_JUMP =>
                            state <= EXECUTE_JUMP;
                        when OP_JUMP_Z | OP_JUMP_C | OP_JUMP_NZ | OP_JUMP_NC =>
                            state <= EXECUTE_TEST;
                        when OP_ADD | OP_INC | OP_LSHIFT | OP_RSHIFT =>
                            state <= EXECUTE_CLEAR_CARRY;
                        when OP_AND | OP_OR | OP_XOR | OP_NOT | OP_ADD_C | OP_INC_C | OP_LSHIFT_C | OP_RSHIFT_C =>
                            state <= EXECUTE_ALU_OP;
                        when others =>
                            state <= ERROR;
                    end case;

                when EXECUTE_NOP =>
                    -- This case is intentionally left blank
                    state <= EXECUTE_END;

                when EXECUTE_HALT =>
                    halt <= '1';
                    state <= EXECUTE_END;

                when EXECUTE_COPY =>
                    rx_write_enable <= '1';
                    rx_in_select <= RX_IN_SELECT_RY;
                    state <= EXECUTE_END;

                when EXECUTE_LOAD =>
                    rx_write_enable <= '1';
                    addr_select <= ADDR_SELECT_INDEXED;
                    rx_in_select <= RX_IN_SELECT_LOAD;
                    state <= EXECUTE_END;

                when EXECUTE_STORE =>
                    mem_write_enable <= '1';
                    addr_select <= ADDR_SELECT_INDEXED;
                    state <= EXECUTE_END;

                when EXECUTE_SET_PAGE =>
                    pg_write_enable <= '1';
                    state <= EXECUTE_END;

                when EXECUTE_JUMP =>
                    pc_write_enable <= '1';
                    pc_in_select <= PC_IN_SELECT_OPERAND;
                    state <= EXECUTE_END;

                when EXECUTE_TEST =>
                    if test = '1' then
                        state <= EXECUTE_JUMP;
                    else
                        state <= EXECUTE_END;
                    end if;

                when EXECUTE_CLEAR_CARRY =>
                    c_write_enable <= '1';
                    c_in_select <= C_IN_SELECT_CLEAR;
                    state <= EXECUTE_ALU_OP;

                when EXECUTE_ALU_OP =>
                    rx_write_enable <= '1';
                    c_write_enable <= '1';
                    z_write_enable <= '1';
                    rx_in_select <= RX_IN_SELECT_ALU;
                    c_in_select <= C_IN_SELECT_ALU;
                    state <= EXECUTE_END;

                when EXECUTE_END =>
                    if halt = '0' then
                        state <= FETCH_HIGH;
                    else
                        halted <= halt;
                    end if;

                when ERROR =>
                    -- oh no!
                    errored <= '1';
            end case;
        end if;
    end process;
end architecture;
