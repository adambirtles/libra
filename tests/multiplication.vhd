library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library libra;

entity multiplication_tb is
end entity;

architecture sim of multiplication_tb is
    constant FREQUENCY: integer := 100e6; -- 100 MHz
    constant PERIOD: time := 1 sec / FREQUENCY;

    signal clock: std_logic := '0';
    signal n_reset: std_ulogic;

    type data_vector is array (integer range <>) of std_ulogic_vector(7 downto 0);
    signal memory: data_vector(0 to 4095);

    function loc(page: integer; index: integer) return integer is
    begin
        return (128 * page) + index;
    end function;

    constant A: std_ulogic_vector(7 downto 0) := x"34";     -- A = 52
    constant B: std_ulogic_vector(7 downto 0) := x"6e";     -- B = 110
    constant P: std_ulogic_vector(15 downto 0) := x"1658";  -- P = A * B = 5720

    constant PROGRAM: data_vector(0 to 37) := (
        x"28", x"01", -- setpg 1
        x"18", x"00", -- load r0, 0             ; a := A
        x"d0", x"88", -- xor r1, r1             ; b_high := 0
        x"19", x"01", -- load r2, 1             ; b_low := B
        x"d1", x"98", -- xor r3, r3             ; prod_high := 0
        x"d2", x"20", -- xor r4, r4             ; prod_low := 0
        x"d7", x"f8", -- xor r15, r15           ; zero := 0
        x"d0", x"78", -- xor r0, r15    ($loop) ; a := a xor zero
        x"40", x"10", -- jumpz $end             ; if a = 0, goto $end
        x"b8", x"00", -- rsh r0                 ; a := a >> 1
        x"58", x"0d", -- jumpnc $skip           ; if not carry, goto $skip
        x"a2", x"10", -- add r4, r2             ; prod := prod + b
        x"e1", x"88", -- addc r3, r1
        x"b1", x"00", -- lsh r2         ($skip) ; b := b << 1
        x"f0", x"80", -- lshc r1
        x"30", x"07", -- jump $loop             ; goto $loop
        x"21", x"82", -- store r3, 2    ($end)  ; PH := prod_high
        x"22", x"03", -- store r4, 3            ; PL := prod_low
        x"08", x"00"  -- halt
    );

    constant DATA: data_vector(0 to 3) := (
        0 => A,
        1 => B,
        2 => x"00",
        3 => x"00"
    );

    signal mem_read: std_ulogic_vector(7 downto 0);
    signal mem_write: std_ulogic_vector(7 downto 0);
    signal mem_addr: unsigned(11 downto 0);
    signal mem_write_enable: std_ulogic;

    type cpu_type is (PARALLEL, SERIAL);
    signal cpu_select: cpu_type;

    signal parallel_n_reset: std_ulogic;
    signal parallel_mem_write: std_ulogic_vector(7 downto 0);
    signal parallel_mem_addr: unsigned(11 downto 0);
    signal parallel_mem_write_enable: std_ulogic;
    signal parallel_halted: std_ulogic;
    signal parallel_errored: std_ulogic;

    signal serial_n_reset: std_ulogic;
    signal serial_mem_write: std_ulogic_vector(7 downto 0);
    signal serial_mem_addr: unsigned(11 downto 0);
    signal serial_mem_write_enable: std_ulogic;
    signal serial_halted: std_ulogic;
    signal serial_errored: std_ulogic;
begin
    -- Memory
    mem_read <= memory(to_integer(mem_addr));

    process(clock, n_reset)
    begin
        if n_reset = '0' then
            -- Reprogram memory on reset
            memory <= (others => x"00");
            memory(loc(0, 0) to loc(0, PROGRAM'length - 1)) <= PROGRAM;
            memory(loc(1, 0) to loc(1, DATA'length - 1)) <= DATA;
        elsif rising_edge(clock) and mem_write_enable = '1' then
            memory(to_integer(mem_addr)) <= mem_write;
        end if;
    end process;

    -- CPUs
    cpu_parallel: entity libra.cpu(rtl)
        generic map(bit_serial => false)
        port map(
            clock => clock,
            n_reset => parallel_n_reset,
            mem_read => mem_read,
            mem_write => parallel_mem_write,
            mem_addr => parallel_mem_addr,
            mem_write_enable => parallel_mem_write_enable,
            halted => parallel_halted,
            errored => parallel_errored
        );

    cpu_serial: entity libra.cpu(rtl)
        generic map(bit_serial => true)
        port map(
            clock => clock,
            n_reset => serial_n_reset,
            mem_read => mem_read,
            mem_write => serial_mem_write,
            mem_addr => serial_mem_addr,
            mem_write_enable => serial_mem_write_enable,
            halted => serial_halted,
            errored => serial_errored
        );

    -- CPU selection logic
    process(cpu_select, n_reset) is
    begin
        parallel_n_reset <= '0';
        serial_n_reset <= '0';

        case cpu_select is
            when PARALLEL =>
                parallel_n_reset <= n_reset;
            when SERIAL =>
                serial_n_reset <= n_reset;
        end case;
    end process;

    with cpu_select
    select mem_write <=
        parallel_mem_write when PARALLEL,
        serial_mem_write   when SERIAL;

    with cpu_select
    select mem_addr <=
        parallel_mem_addr when PARALLEL,
        serial_mem_addr   when SERIAL;

    with cpu_select
    select mem_write_enable <=
        parallel_mem_write_enable when PARALLEL,
        serial_mem_write_enable   when SERIAL;

    clock_process: clock <= not clock after PERIOD / 2;

    test_process: process is
        function msg(cpu: cpu_type; message: string) return string is
        begin
            return cpu_type'image(cpu) & ": " & message;
        end function;

        function value(n: std_ulogic_vector(15 downto 0)) return string is
        begin
            return integer'image(to_integer(unsigned(n)));
        end function;

        procedure test_cpu(
            constant cpu: in cpu_type;
            signal halted: in std_ulogic;
            signal errored: in std_ulogic
        ) is
            variable result: std_ulogic_vector(15 downto 0);
        begin
            -- Reset system and switch to selected CPU
            n_reset <= '0';
            cpu_select <= cpu;
            wait for PERIOD;

            -- Bring system out of reset and run until CPU halts (or errors)
            n_reset <= '1';
            report msg(cpu, "Started");
            wait until halted = '1' or errored = '1';

            -- Check the results
            assert errored = '0' report msg(cpu, "CPU error!") severity failure;

            result := memory(loc(1, 2)) & memory(loc(1, 3));
            if result = P then
                report msg(cpu, "Passed");
            else
                report msg(cpu, "Failed! Expected " & value(P) & ", got " & value(result)) severity error;
            end if;
        end procedure;
    begin
        test_cpu(PARALLEL, parallel_halted, parallel_errored);
        test_cpu(SERIAL, serial_halted, serial_errored);
        wait;
    end process;
end architecture;

