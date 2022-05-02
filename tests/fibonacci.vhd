library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.testing.all;

entity fibonacci_tb is
end entity;

architecture sim of fibonacci_tb is
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

    signal image: mem;
    signal start: boolean := false;

    signal state_classical: test_state;
    signal memory_classical: mem;

    signal state_bit_serial: test_state;
    signal memory_bit_serial: mem;

    procedure check_result(constant cpu: in cpu_type; signal memory: in mem) is
        variable result: std_ulogic_vector(7 downto 0);
    begin
        result := memory(loc(1, 1));
        if result = FIB_N then
            report cpu_msg(cpu, "Passed");
        else
            report cpu_msg(cpu, "Failed! Expected " & value(FIB_N) & ", got " & value(result)) severity error;
        end if;
    end procedure;
begin
    harness_classical: entity work.test_harness
        generic map(cpu => CLASSICAL)
        port map(
            start => start,
            image => image,
            state => state_classical,
            memory => memory_classical
        );

    harness_bit_serial: entity work.test_harness
        generic map(cpu => BIT_SERIAL)
        port map(
            start => start,
            image => image,
            state => state_bit_serial,
            memory => memory_bit_serial
        );

    init: process is
    begin
        image <= (others => x"00");
        image(loc(0, 0) to loc(0, PROGRAM'length - 1)) <= PROGRAM;
        image(loc(1, 0) to loc(1, DATA'length - 1)) <= DATA;
        start <= true;
        wait;
    end process;

    test_classical: process is
    begin
        wait until state_classical = STATE_HALTED;
        check_result(CLASSICAL, memory_classical);
        wait;
    end process;

    test_bit_serial: process is
    begin
        wait until state_bit_serial = STATE_HALTED;
        check_result(BIT_SERIAL, memory_bit_serial);
        wait;
    end process;
end architecture;
