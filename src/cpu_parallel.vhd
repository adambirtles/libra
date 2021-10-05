library ieee;
use ieee.std_logic_1164.all;

entity cpu_parallel is
    port(
        clock: in std_ulogic;
        n_reset: in std_ulogic;

        mem_read: in std_ulogic_vector(7 downto 0);
        mem_write: out std_ulogic_vector(7 downto 0);
        mem_addr: out std_ulogic_vector(11 downto 0);
        mem_write_enable: out std_ulogic;

        halted: out std_ulogic
    );
end entity;

architecture rtl of cpu_parallel is
    signal halt: std_ulogic;
    signal carry: std_ulogic;
    signal zero: std_ulogic;

    signal h_in: std_ulogic;
    signal c_in: std_ulogic;
    signal z_in: std_ulogic;

    signal opcode: std_ulogic_vector(4 downto 0);
    signal operand_rx: std_ulogic_vector(3 downto 0);
    signal operand_ry: std_ulogic_vector(3 downto 0);
    signal operand_index: std_ulogic_vector(6 downto 0);
    signal operand_immediate: std_ulogic_vector(10 downto 0);

    signal rx_in: std_ulogic_vector(7 downto 0);
    signal rx_out: std_ulogic_vector(7 downto 0);
    signal ry_out: std_ulogic_vector(7 downto 0);
    signal alu_result: std_ulogic_vector(7 downto 0);

    signal pc_in: std_ulogic_vector(11 downto 0);
    signal pc_out: std_ulogic_vector(11 downto 0);
    signal pc_increment: std_ulogic_vector(11 downto 0);
    signal indexed_addr: std_ulogic_vector(11 downto 0);

    signal ir_out: std_ulogic_vector(15 downto 0);
    signal pg_out: std_ulogic_vector(4 downto 0);

    -- Control lines
    signal alu_opcode: std_ulogic_vector(2 downto 0);
    signal rx_write_enable: std_ulogic;
    signal pc_write_enable: std_ulogic;
    signal pg_write_enable: std_ulogic;
    signal irh_write_enable: std_ulogic;
    signal irl_write_enable: std_ulogic;
    signal h_write_enable: std_ulogic;
    signal c_write_enable: std_ulogic;
    signal z_write_enable: std_ulogic;
    signal addr_select: std_ulogic;
    signal pc_in_select: std_ulogic;
    signal rx_in_select: std_ulogic_vector(1 downto 0);

    -- Select constants
    constant ADDR_SELECT_PC: std_ulogic := '0';
    constant ADDR_SELECT_INDEXED: std_ulogic := '1';

    constant PC_IN_SELECT_INCREMENT: std_ulogic := '0';
    constant PC_IN_SELECT_OPERAND: std_ulogic := '1';

    constant RX_IN_SELECT_LOAD: std_ulogic_vector(1 downto 0) := "00";
    constant RX_IN_SELECT_RESULT: std_ulogic_vector(1 downto 0) := "01";
    constant RX_IN_SELECT_RY: std_ulogic_vector(1 downto 0) := "10";

    type state_t is (
        FETCH_HIGH,
        INC_PC_1,
        FETCH_LOW,
        INC_PC_2,
        DECODE
    );
    signal state: state_t;
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
            opcode => alu_opcode,
            lhs => rx_out,
            rhs => ry_out,
            carry_in => carry,
            result => alu_result,
            carry_out => c_in
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
            data_in => pc_in,
            data_out => pc_out
        );

    pc_inc: entity work.incrementer(struct)
        generic map(data_width => 12)
        port map(
            data_in => pc_out,
            data_out => pc_increment
        );

    -- Flags
    halt_flag: entity work.flag(rtl)
        port map(
            clock => clock,
            n_reset => n_reset,
            write_enable => h_write_enable,
            data_in => h_in,
            data_out => halt
        );
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
        pc_out                 when ADDR_SELECT_PC,
        pg_out & operand_index when ADDR_SELECT_INDEXED,
        (others => 'X')        when others;

    mux_pc_in: with pc_in_select
    select pc_in <=
        pc_increment            when PC_IN_SELECT_INCREMENT,
        operand_immediate & '0' when PC_IN_SELECT_OPERAND,
        (others => 'X')         when others;

    mux_rx_in: with rx_in_select
    select rx_in <=
        mem_read        when RX_IN_SELECT_LOAD,
        alu_result      when RX_IN_SELECT_RESULT,
        ry_out          when RX_IN_SELECT_RY,
        (others => 'X') when others;

    mem_write <= rx_out;
    halted <= halt;

    opcode <= ir_out(15 downto 11);
    operand_rx <= ir_out(10 downto 7);
    operand_ry <= ir_out(6 downto 3);
    operand_index <= ir_out(6 downto 0);
    operand_immediate <= ir_out(10 downto 0);

    process(clock, n_reset)
    begin
        -- Reset all control lines
        alu_opcode <= "000";
        mem_write_enable <= '0';
        rx_write_enable <= '0';
        pc_write_enable <= '0';
        pg_write_enable <= '0';
        irh_write_enable <= '0';
        irl_write_enable <= '0';
        h_write_enable <= '0';
        c_write_enable <= '0';
        z_write_enable <= '0';
        addr_select <= '0';
        pc_in_select <= '0';
        rx_in_select <= "00";

        if n_reset = '0' then
            state <= FETCH_HIGH;
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
                    -- Figure out opcode and set things accordingly
                    state <= FETCH_HIGH;
            end case;
        end if;
    end process;
end architecture;
