library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.testing.all;

entity multiplication_tb is
end entity;

architecture sim of multiplication_tb is
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

    signal image: mem;
    signal start: boolean := false;

    signal state_classical: test_state;
    signal memory_classical: mem;

    signal state_bit_serial: test_state;
    signal memory_bit_serial: mem;

    procedure check_result(constant cpu: in cpu_type; signal memory: in mem) is
        variable result: std_ulogic_vector(15 downto 0);
    begin
        result := memory(loc(1, 2)) & memory(loc(1, 3));
        if result = P then
            report cpu_msg(cpu, "Passed");
        else
            report cpu_msg(cpu, "Failed! Expected " & value(P) & ", got " & value(result)) severity error;
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

