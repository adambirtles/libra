library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity memory is
    generic(
        data_width: integer;
        addr_width: integer
    );
    port(
        clock: in std_ulogic;
        n_reset: in std_ulogic;

        write_enable: in std_ulogic;
        addr: in unsigned((addr_width - 1) downto 0);
        data_in: in std_ulogic_vector((data_width - 1) downto 0);
        data_out: out std_ulogic_vector((data_width - 1) downto 0)
    );
end entity;

architecture rtl of memory is
    constant MAX_ADDR: integer := (2 ** addr_width) - 1;

    type data_vector is array(integer range <>) of std_ulogic_vector((data_width - 1) downto 0);

    signal data: data_vector(0 to MAX_ADDR);
begin
    process(clock)
    begin
        if rising_edge(clock) and n_reset /= '0' then
            if write_enable = '1' then
                data(to_integer(addr)) <= data_in;
            end if;
        end if;
    end process;

    data_out <= data(to_integer(addr));

    process(n_reset)
    begin
        if n_reset = '0' then
            data <= (others => (others => '0'));
        end if;
    end process;
end architecture;
