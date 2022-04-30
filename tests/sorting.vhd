library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.testing.all;

entity sorting_tb is
end entity;

architecture sim of sorting_tb is
    constant ARRAY_UNSORTED: data_vector(0 to 11) := (
        x"2c", x"65", x"cc", x"a9", x"b4", x"06",
        x"60", x"2c", x"93", x"7d", x"28", x"4e"
    );

    constant ARRAY_SORTED: data_vector(0 to 11) := (
        x"06", x"28", x"2c", x"2c", x"4e", x"60",
        x"65", x"7d", x"93", x"a9", x"b4", x"cc"
    );

    constant COUNT: integer := ARRAY_UNSORTED'length;

    constant PROGRAM: data_vector(0 to 79) := (
        x"28", x"01", -- setpg 1
        x"d7", x"f8", -- xor r15, r15
        x"1f", x"01", -- load r14, 1
        x"1e", x"82", -- load r13, 2
        x"18", x"00", -- load r0, 0                 ; count := COUNT
        x"18", x"81", -- load r1, 1                 ; i := 1
        x"d0", x"78", -- xor r0, r15                ; if count = 0, goto $end
        x"40", x"28", -- jumpz $end
        x"13", x"08", -- copy r6, r1    ($outer)    ; if i = count, goto $end
        x"d3", x"00", -- xor r6, r0
        x"40", x"28", -- jumpz $end
        x"28", x"00", -- setpg 0                    ; value := array[i]
        x"20", x"9d", -- store r1, $op1
        x"28", x"02", -- setpg 2
        x"19", x"00", -- load r2, <op1>
        x"11", x"88", -- copy r3, r1                ; dest := i
        x"12", x"98", -- copy r5, r3    ($inner)    ; cmp := array[dest - 1]
        x"a2", x"e8", -- add r5, r13
        x"28", x"00", -- setpg 0
        x"22", x"ab", -- store r5, $op2
        x"28", x"02", -- setpg 2
        x"1a", x"00", -- load r4, <op2>
        x"13", x"10", -- copy r6, r2                ; if cmp < value, goto $insert
        x"db", x"00", -- not r6                     ; (cmp < value = (~value + 1) + cmp < 256)
        x"a3", x"70", -- add r6, r14
        x"a3", x"20", -- add r6, r4
        x"58", x"21", -- jumpnc $insert
        x"28", x"00", -- setpg 0                    ; array[dest] := cmp
        x"21", x"bd", -- store r3, $op3
        x"28", x"02", -- setpg 2
        x"22", x"00", -- store r4, <op3>
        x"a1", x"e8", -- add r3, r13                ; dest := dest - 1
        x"50", x"10", -- jumpnz $inner              ; if dest != 0, goto $inner
        x"28", x"00", -- setpg 0        ($insert)   ; array[dest] := value
        x"21", x"c9", -- store r3, $op4
        x"28", x"02", -- setpg 2
        x"21", x"00", -- store r2 <op4>
        x"a0", x"f0", -- add r1, r14                ; i := i + 1
        x"30", x"08", -- jump $outer                ; goto outer
        x"08", x"00"  -- halt           ($end)
    );

    constant CONSTS: data_vector(0 to 2) := (
        0 => std_ulogic_vector(to_unsigned(COUNT, 8)),
        1 => x"01",
        2 => x"ff"
    );

    signal image: mem;
    signal start: boolean := false;

    signal state_classical: test_state;
    signal memory_classical: mem;
    shared variable result_classical: data_vector(0 to 11);

    signal state_bit_serial: test_state;
    signal memory_bit_serial: mem;
    shared variable result_bit_serial: data_vector(0 to 11);
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
        image(loc(1, 0) to loc(1, CONSTS'length - 1)) <= CONSTS;
        image(loc(2, 0) to loc(2, COUNT - 1)) <= ARRAY_UNSORTED;
        start <= true;
        wait;
    end process;

    classical: process is
    begin
        wait until state_classical = STATE_HALTED;

        result_classical := memory_classical(loc(2, 0) to loc(2, COUNT - 1));
        if result_classical = ARRAY_SORTED then
            report "classical: Passed";
        else
            report "classical: Failed!" severity error;
        end if;
        wait;
    end process;

    bit_serial: process is
    begin
        wait until state_bit_serial = STATE_HALTED;

        result_bit_serial := memory_bit_serial(loc(2, 0) to loc(2, COUNT - 1));
        if result_bit_serial = ARRAY_SORTED then
            report "bit_serial: Passed";
        else
            report "bit_serial: Failed!" severity error;
        end if;
        wait;
    end process;
end architecture;

