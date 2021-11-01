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

    constant PROGRAM: data_vector(0 to 35) := (
        x"28", x"01", -- setpg 1
        x"18", x"00", -- load r0, 0
        x"1f", x"82", -- load r15, 2
        x"c7", x"80", -- and r15, r0
        x"40", x"10", -- jumpz $end
        x"18", x"81", -- load r1, 1
        x"19", x"03", -- load r2, 3
        x"19", x"84", -- load r3, 4
        x"17", x"98", -- copy r15, r3   ($loop)
        x"d7", x"80", -- xor r15, r0
        x"40", x"10", -- jumpz $end
        x"12", x"08", -- copy r4, r1
        x"a0", x"90", -- add r1, r2
        x"11", x"20", -- copy r2, r4
        x"a9", x"80", -- inc r3
        x"30", x"08", -- jump $loop
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
    signal halted: std_ulogic;
    signal errored: std_ulogic;
begin
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

    uut: entity libra.cpu_parallel(rtl)
        port map(
            clock => clock,
            n_reset => n_reset,
            mem_read => mem_read,
            mem_write => mem_write,
            mem_addr => mem_addr,
            mem_write_enable => mem_write_enable,
            halted => halted,
            errored => errored
        );

    clock_process: clock <= not clock after PERIOD / 2;

    test_process: process is
    begin
        -- Reset system
        n_reset <= '0';
        wait for PERIOD;

        -- Bring CPU out of reset and let it run until halted
        n_reset <= '1';
        wait until rising_edge(clock);
        report "CPU started";
        wait until halted = '1' or errored = '1';
        assert errored = '0' report "CPU error!" severity failure;
        report "CPU halted";

        -- Check that CPU has correctly calculated fib(N)
        if memory(loc(1, 1)) = FIB_N then
            report "Pass!";
        else
            assert false report "Incorrect result!" severity error;
        end if;
        wait;
    end process;
end architecture;
