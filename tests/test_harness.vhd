library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library libra;

use work.testing.all;

entity test_harness is
    generic(cpu: cpu_type);
    port(
        start: in boolean;
        image: in mem;

        state: out test_state;
        memory: inout mem
    );
end entity;

architecture sim of test_harness is
    constant IS_BIT_SERIAL: boolean := cpu = BIT_SERIAL;
    constant PERIOD: time := cpu_min_period(cpu);

    signal clock: std_logic := '1';
    signal n_reset: std_ulogic := '0';
    signal mem_write: std_ulogic_vector(7 downto 0);
    signal mem_read: std_ulogic_vector(7 downto 0);
    signal mem_addr: unsigned(11 downto 0);
    signal mem_write_enable: std_ulogic;
    signal halted: std_ulogic;
    signal errored: std_ulogic;
begin
    cpu_inst: entity libra.cpu(rtl)
        generic map(bit_serial => IS_BIT_SERIAL)
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

    clock <= not clock after PERIOD / 2;

    mem_read <= memory(to_integer(mem_addr));

    process(clock, n_reset)
    begin
        if n_reset = '0' then
            -- Reprogram memory on reset
            memory <= image;
        elsif rising_edge(clock) and mem_write_enable = '1' then
            memory(to_integer(mem_addr)) <= mem_write;
        end if;
    end process;

    test: process is
    begin
        wait until start;

        n_reset <= '0';
        wait for PERIOD;

        n_reset <= '1';
        state <= STATE_RUNNING;
        report cpu_msg(cpu, "Started");
        wait until halted = '1' or errored = '1';

        if errored = '1' then
            report cpu_msg(cpu, "CPU error!") severity failure;
            state <= STATE_ERRORED;
        else
            state <= STATE_HALTED;
        end if;
        wait;
    end process;
end architecture;
