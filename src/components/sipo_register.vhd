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

    process(clock, n_reset)
    begin
        if n_reset = '0' then
            data <= (others => '0');
        elsif rising_edge(clock) then
            if shift_enable = '1' then
                data((data_width - 2) downto 0) <= data((data_width - 1) downto 1);
                data(data_width - 1) <= data_in;
            end if;
        end if;
    end process;
end architecture;
