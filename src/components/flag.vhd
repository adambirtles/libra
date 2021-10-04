library ieee;
use ieee.std_logic_1164.all;

-- Convenience wrapper around a 1-bit register
entity flag is
    port(
        clock: in std_ulogic;
        n_reset: in std_ulogic;

        write_enable: in std_ulogic;
        data_in: in std_ulogic;
        data_out: out std_ulogic
    );
end entity;

architecture rtl of flag is
begin
    reg: entity work.parallel_register(rtl)
        generic map(data_width => 1)
        port map(
            clock => clock,
            n_reset => n_reset,
            write_enable => write_enable,
            data_in(0) => data_in,
            data_out(0) => data_out
        );
end architecture;

