library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.testing.all;

entity hashing_tb is
end entity;

architecture sim of hashing_tb is
    constant MESSAGE: data_vector(0 to 42) := (
        x"54", x"68", x"65", x"20", x"71", x"75", x"69", x"63", x"6b", x"20", x"62", x"72", x"6f", x"77", x"6e", x"20",
        x"66", x"6f", x"78", x"20", x"6a", x"75", x"6d", x"70", x"73", x"20", x"6f", x"76", x"65", x"72", x"20", x"74",
        x"68", x"65", x"20", x"6c", x"61", x"7a", x"79", x"20", x"64", x"6f", x"67"
    );

    constant DIGEST: data_vector(0 to 15) := (
        x"03", x"d8", x"5a", x"0d", x"62", x"9d", x"2c", x"44", x"2e", x"98", x"75", x"25", x"31", x"9f", x"c4", x"71"
    );

    constant PROGRAM: data_vector(0 to 247) := (
        x"28", x"02", -- setpg 2
        x"1f", x"81", -- load r15, 1
        x"1f", x"02", -- load r14, 2
        x"1e", x"83", -- load r13, 3
        x"1e", x"04", -- load r12, 4
        x"1d", x"85", -- load r11, 5
        x"1d", x"06", -- load r10, 6
        x"1c", x"87", -- load r9, 7
        x"18", x"00", -- load r0, 0
        x"11", x"68", -- copy r2, r13
        x"18", x"88", -- load r1, 8
        x"c0", x"80", -- and r1, r0
        x"d8", x"80", -- not r1
        x"a0", x"f8", -- add r1, r15
        x"a1", x"08", -- add r2, r1
        x"10", x"90", -- copy r1, r2
        x"28", x"00", -- setpg $op1.page            (loop1: 16)
        x"20", x"27", -- store r0, $op1.index
        x"28", x"05", -- setpg 5
        x"21", x"00", -- store r2, <op1: 0,39>
        x"a0", x"78", -- add r0, r15
        x"a0", x"f0", -- add r1, r14
        x"50", x"10", -- jumpnz $loop1
        x"d1", x"10", -- xor r2, r2
        x"d0", x"88", -- xor r1, r1
        x"d1", x"98", -- xor r3, r3                 (loop2: 25)
        x"12", x"88", -- copy r5, r1                (loop2a: 26)
        x"a2", x"98", -- add r5, r3
        x"28", x"00", -- setpg $op2.page
        x"22", x"bf", -- store r5, $op2.index
        x"28", x"05", -- setpg 5
        x"1a", x"00", -- load r4, <op2: 0,63>
        x"13", x"80", -- copy r7, r0
        x"a3", x"98", -- add r7, r3
        x"28", x"00", -- setpg $op12.page
        x"23", x"cb", -- store r7, $op12.index
        x"28", x"05", -- setpg 5
        x"1c", x"00", -- load r8, <op12: 0,75>
        x"12", x"a0", -- copy r5, r4
        x"d2", x"90", -- xor r5, r2
        x"13", x"28", -- copy r6, r5
        x"c3", x"60", -- and r6, r12
        x"28", x"00", -- setpg $op3.page
        x"23", x"65", -- store r6, $op3.index
        x"13", x"28", -- copy r6, r5
        x"c3", x"58", -- and r6, r11
        x"50", x"31", -- jumpnz $upper1
        x"28", x"03", -- setpg 3
        x"30", x"32", -- jump $skip1
        x"28", x"04", -- setpg 4                    (upper1: 49)
        x"19", x"00", -- load r2, <op3: 0,101>      (skip1: 50)
        x"d1", x"40", -- xor r2, r8
        x"28", x"00", -- setpg $op4.page
        x"23", x"ef", -- store r7, $op4.index
        x"28", x"05", -- setpg 5
        x"21", x"00", -- store r2, <op4: 0,111>
        x"a1", x"f8", -- add r3, r15
        x"12", x"98", -- copy r5, r3
        x"d2", x"e8", -- xor r5, r13
        x"50", x"1a", -- jumpnz $loop2a
        x"a0", x"e8", -- add r1, r13
        x"12", x"88", -- copy r5, r1
        x"d2", x"80", -- xor r5, r0
        x"50", x"19", -- jumpnz $loop2
        x"a0", x"68", -- add r0, r13
        x"d0", x"88", -- xor r1, r1
        x"d1", x"98", -- xor r3, r3                 (loop3: 66)
        x"13", x"08", -- copy r6, r1                (loop3a: 67)
        x"a3", x"18", -- add r6, r3
        x"28", x"01", -- setpg $op5.page
        x"23", x"11", -- store r6, $op5.index
        x"28", x"05", -- setpg 5
        x"19", x"00", -- load r2, <op5: 1,17>
        x"13", x"68", -- copy r6, r13
        x"a3", x"18", -- add r6, r3
        x"28", x"01", -- setpg $op6.page
        x"23", x"23", -- store r6, $op6.index
        x"a3", x"68", -- add r6, r13
        x"21", x"a5", -- store r3, $op7.index
        x"23", x"29", -- store r6, $op8.index
        x"28", x"06", -- setpg 6
        x"21", x"00", -- store r2, <op6: 1,35>
        x"1b", x"00", -- load r6, <op7: 1,37>
        x"d3", x"10", -- xor r6, r2
        x"23", x"00", -- store r6 <op8: 1,41>
        x"a1", x"f8", -- add r3, r15
        x"13", x"18", -- copy r6, r3
        x"d3", x"68", -- xor r6, r13
        x"50", x"43", -- jumpnz $loop3a
        x"d2", x"20", -- xor r4, r4
        x"d1", x"98", -- xor r3, r3
        x"d2", x"a8", -- xor r5, r5                 (loop3b: 91)
        x"28", x"01", -- setpg $op9.page            (loop3c: 92)
        x"22", x"d7", -- store r5, $op9.index
        x"22", x"db", -- store r5, $op11.index
        x"13", x"20", -- copy r6, r4
        x"c3", x"60", -- and r6, r12
        x"28", x"01", -- setpg $op10.page
        x"23", x"53", -- store r6, $op10.index
        x"13", x"20", -- copy r6, r4
        x"c3", x"58", -- and r6, r11
        x"50", x"68", -- jumpnz $upper2
        x"28", x"03", -- setpg 3
        x"30", x"69", -- jump $skip2
        x"28", x"04", -- setpg 4                    (upper2: 104)
        x"1c", x"00", -- load r8, <op10: 1,83>      (skip2: 105)
        x"28", x"06", -- setpg 6
        x"1a", x"00", -- load r4, <op9: 1,87>
        x"d2", x"40", -- xor r4, r8
        x"22", x"00", -- store r4, <op11: 1,91>
        x"a2", x"f8", -- add r5, r15
        x"13", x"28", -- copy r6, r5
        x"d3", x"50", -- xor r6, r10
        x"50", x"5c", -- jumpnz $loop3c
        x"a2", x"18", -- add r4, r3
        x"a1", x"f8", -- add r3, r15
        x"13", x"18", -- copy r6, r3
        x"d3", x"48", -- xor r6, r9
        x"50", x"5b", -- jumpnz $loop3b
        x"a0", x"e8", -- add r1, r13
        x"13", x"08", -- copy r6, r1
        x"d3", x"00", -- xor r6, r0
        x"50", x"42", -- jumpnz $loop3
        x"08", x"00"  -- halt
    );

    constant DATA: data_vector(0 to 8) := (
        0 => std_ulogic_vector(to_unsigned(MESSAGE'length, 8)),
        1 => x"01",
        2 => x"ff",
        3 => x"10",
        4 => x"7f",
        5 => x"80",
        6 => x"30",
        7 => x"12",
        8 => x"0f"
    );

    constant S_BOX: data_vector(0 to 255) := (
        x"29", x"2e", x"43", x"c9", x"a2", x"d8", x"7c", x"01", x"3d", x"36", x"54", x"a1", x"ec", x"f0", x"06", x"13",
        x"62", x"a7", x"05", x"f3", x"c0", x"c7", x"73", x"8c", x"98", x"93", x"2b", x"d9", x"bc", x"4c", x"82", x"ca",
        x"1e", x"9b", x"57", x"3c", x"fd", x"d4", x"e0", x"16", x"67", x"42", x"6f", x"18", x"8a", x"17", x"e5", x"12",
        x"be", x"4e", x"c4", x"d6", x"da", x"9e", x"de", x"49", x"a0", x"fb", x"f5", x"8e", x"bb", x"2f", x"ee", x"7a",
        x"a9", x"68", x"79", x"91", x"15", x"b2", x"07", x"3f", x"94", x"c2", x"10", x"89", x"0b", x"22", x"5f", x"21",
        x"80", x"7f", x"5d", x"9a", x"5a", x"90", x"32", x"27", x"35", x"3e", x"cc", x"e7", x"bf", x"f7", x"97", x"03",
        x"ff", x"19", x"30", x"b3", x"48", x"a5", x"b5", x"d1", x"d7", x"5e", x"92", x"2a", x"ac", x"56", x"aa", x"c6",
        x"4f", x"b8", x"38", x"d2", x"96", x"a4", x"7d", x"b6", x"76", x"fc", x"6b", x"e2", x"9c", x"74", x"04", x"f1",
        x"45", x"9d", x"70", x"59", x"64", x"71", x"87", x"20", x"86", x"5b", x"cf", x"65", x"e6", x"2d", x"a8", x"02",
        x"1b", x"60", x"25", x"ad", x"ae", x"b0", x"b9", x"f6", x"1c", x"46", x"61", x"69", x"34", x"40", x"7e", x"0f",
        x"55", x"47", x"a3", x"23", x"dd", x"51", x"af", x"3a", x"c3", x"5c", x"f9", x"ce", x"ba", x"c5", x"ea", x"26",
        x"2c", x"53", x"0d", x"6e", x"85", x"28", x"84", x"09", x"d3", x"df", x"cd", x"f4", x"41", x"81", x"4d", x"52",
        x"6a", x"dc", x"37", x"c8", x"6c", x"c1", x"ab", x"fa", x"24", x"e1", x"7b", x"08", x"0c", x"bd", x"b1", x"4a",
        x"78", x"88", x"95", x"8b", x"e3", x"63", x"e8", x"6d", x"e9", x"cb", x"d5", x"fe", x"3b", x"00", x"1d", x"39",
        x"f2", x"ef", x"b7", x"0e", x"66", x"58", x"d0", x"e4", x"a6", x"77", x"72", x"f8", x"eb", x"75", x"4b", x"0a",
        x"31", x"44", x"50", x"b4", x"8f", x"ed", x"1f", x"1a", x"db", x"99", x"8d", x"33", x"9f", x"11", x"83", x"14"
    );

    signal image: mem;
    signal start: boolean := false;

    signal state_classical: test_state;
    signal memory_classical: mem;

    signal state_bit_serial: test_state;
    signal memory_bit_serial: mem;
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
        image(loc(2, 0) to loc(2, DATA'length - 1)) <= DATA;
        image(loc(3, 0) to loc(4, 127)) <= S_BOX;
        image(loc(5, 0) to loc(5, MESSAGE'length - 1)) <= MESSAGE;
        start <= true;
        wait;
    end process;

    classical: process is
        variable result: data_vector(0 to 15);
    begin
        wait until state_classical = STATE_HALTED;

        result := memory_classical(loc(6, 0) to loc(6, 15));
        if result = DIGEST then
            report "classical: Passed";
        else
            report "classical: Failed!" severity error;
        end if;
        wait;
    end process;

    bit_serial: process is
        variable result: data_vector(0 to 15);
    begin
        wait until state_bit_serial = STATE_HALTED;

        result := memory_bit_serial(loc(6, 0) to loc(6, 15));
        if result = DIGEST then
            report "bit_serial: Passed";
        else
            report "bit_serial: Failed!" severity error;
        end if;
        wait;
    end process;
end architecture;


