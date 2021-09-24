library ieee;
use ieee.std_logic_1164.all;

entity parallel_register is
    generic(data_width: integer);
    port(
        clock: in std_ulogic;
        n_reset: in std_ulogic;

        write_enable: in std_ulogic;

        data_in: in std_ulogic_vector((data_width - 1) downto 0);
        data_out: out std_ulogic_vector((data_width - 1) downto 0)
    );
end entity;

architecture rtl of parallel_register is
begin
    process(clock)
    begin
        if rising_edge(clock) then
            if n_reset = '0' then
                data_out <= (others => '0');
            elsif write_enable = '1' then
                data_out <= data_in;
            end if;
        end if;
    end process;
end architecture;
