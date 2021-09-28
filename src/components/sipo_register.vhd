library ieee;
use ieee.std_logic_1164.all;

-- Serial in, parallel out (SIPO) shift register
-- Shifts downwards/rightwards on the rising edge of `clock` when `shift_enable`
-- is high.
entity sipo_register is
    generic(data_width: integer);
    port (
        clock: in std_ulogic;
        n_reset: in std_ulogic;

        shift_enable: in std_ulogic;

        data_in: in std_ulogic;
        data_out: out std_ulogic_vector((data_width - 1) downto 0)
    );
end entity;

architecture rtl of sipo_register is
    signal data: std_ulogic_vector((data_width - 1) downto 0);
begin
    data_out <= data;

    process(clock)
    begin
        if rising_edge(clock) and n_reset /= '0' then
            if shift_enable = '1' then
                for i in 0 to (data_width - 2) loop
                    data(i) <= data(i + 1);
                end loop;
                data(data_width - 1) <= data_in;
            end if;
        end if;
    end process;

    process(n_reset)
    begin
        if n_reset = '0' then
            data <= (others => '0');
        end if;
    end process;
end architecture;
