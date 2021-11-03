library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library libra;

entity fibonacci_tb is
end entity;

architecture sim of fibonacci_tb is
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

    constant N: std_ulogic_vector(7 downto 0) := x"0a";     -- N = 10
    constant FIB_N: std_ulogic_vector(7 downto 0) := x"37"; -- fib(10) = 55

    constant PROGRAM: data_vector(0 to 37) := (
        x"28", x"01", -- setpg 1
        x"1f", x"83", -- load r15, 3
        x"18", x"00", -- load r0, 0
        x"1a", x"02", -- load r4, 2
        x"c2", x"00", -- and r4, r0
        x"40", x"11", -- jumpz $end
        x"18", x"81", -- load r1, 1
        x"19", x"03", -- load r2, 3
        x"19", x"84", -- load r3, 4
        x"12", x"18", -- copy r4, r3    ($loop)
        x"d2", x"00", -- xor r4, r0
        x"40", x"11", -- jumpz $end
        x"12", x"08", -- copy r4, r1
        x"a0", x"90", -- add r1, r2
        x"11", x"20", -- copy r2, r4
        x"a1", x"f9", -- add r3, r15
        x"30", x"09", -- jump $loop
        x"20", x"81", -- store r1, 1    ($end)
        x"08", x"00"  -- halt
    );

    constant DATA: data_vector(0 to 4) := (
        0 => N,
        1 => x"01",
        2 => x"fe",
        3 => x"01",
        4 => x"02"
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

        function value(n: std_ulogic_vector(7 downto 0)) return string is
        begin
            return integer'image(to_integer(unsigned(n)));
        end function;

        procedure test_cpu(
            constant cpu: in cpu_type;
            signal halted: in std_ulogic;
            signal errored: in std_ulogic
        ) is
            variable result: std_ulogic_vector(7 downto 0);
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

            result := memory(loc(1, 1));
            if result = FIB_N then
                report msg(cpu, "Passed");
            else
                report msg(cpu, "Failed! Expected " & value(FIB_N) & ", got " & value(result)) severity error;
            end if;
        end procedure;
    begin
        test_cpu(PARALLEL, parallel_halted, parallel_errored);
        test_cpu(SERIAL, serial_halted, serial_errored);
        wait;
    end process;
end architecture;
