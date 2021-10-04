library ieee;
use ieee.std_logic_1164.all;

entity cpu_serial is
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

architecture rtl of cpu_serial is
    signal halt: std_ulogic;
    signal carry: std_ulogic;
    signal zero: std_ulogic;

    signal h_in: std_ulogic;
    signal c_in: std_ulogic;
    signal z_in: std_ulogic;

    signal operand_rx: std_ulogic_vector(3 downto 0);
    signal operand_ry: std_ulogic_vector(3 downto 0);
    signal operand_index: std_ulogic_vector(6 downto 0);
    signal operand_immediate: std_ulogic_vector(10 downto 0);

    signal rx_in: std_ulogic;
    signal rx_out: std_ulogic;
    signal ry_out: std_ulogic;
    signal alu_result: std_ulogic;
    signal ld_out: std_ulogic;

    signal rx_parallel_out: std_ulogic_vector(7 downto 0);

    signal pc_in: std_ulogic_vector(11 downto 0);
    signal pc_out: std_ulogic_vector(11 downto 0);
    signal pc_increment: std_ulogic_vector(11 downto 0);
    signal indexed_addr: std_ulogic_vector(11 downto 0);

    signal ir_out: std_ulogic_vector(15 downto 0);
    signal pg_out: std_ulogic_vector(4 downto 0);

    signal alu_opcode: std_ulogic_vector(2 downto 0);
    signal regfile_shift_enable: std_ulogic;
    signal ld_write_enable: std_ulogic;
    signal ld_shift_enable: std_ulogic;
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
begin
    regfile: entity work.shift_register_file(rtl)
        generic map(data_width => 8)
        port map(
            clock => clock,
            n_reset => n_reset,
            shift_enable => regfile_shift_enable,
            x_select => operand_rx,
            x_in => rx_in,
            x_out => rx_parallel_out,
            y_select => operand_ry,
            y_out(0) => ry_out
        );

    alu: entity work.alu(struct)
        generic map(data_width => 1)
        port map(
            opcode => alu_opcode,
            lhs(0) => rx_out,
            rhs(0) => ry_out,
            carry_in => carry,
            result(0) => alu_result,
            carry_out => c_in
        );

    reg_ld: entity work.piso_register(rtl)
        generic map(data_width => 8)
        port map(
            clock => clock,
            n_reset => n_reset,
            write_enable => ld_write_enable,
            shift_enable => ld_shift_enable,
            shift_in => '0',
            data_in => mem_read,
            data_out => ld_out
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

    -- Muxes
    mux_addr: with addr_select
    select mem_addr <=
        pc_out                 when '0',
        pg_out & operand_index when '1',
        (others => 'X')        when others;

    mux_pc_in: with pc_in_select
    select pc_in <=
        pc_increment            when '0',
        operand_immediate & '0' when '1',
        (others => 'X')         when others;

    mux_rx_in: with rx_in_select
    select rx_in <=
        ld_out     when "00",
        alu_result when "01",
        ry_out     when "10",
        'X'        when others;

    halted <= halt;
    mem_write <= rx_parallel_out;
    rx_out <= rx_parallel_out(0);

    process(clock)
    begin
        if n_reset /= '0' and rising_edge(clock) and halt = '0' then
            -- TODO: control logic
        end if;
    end process;
end architecture;

