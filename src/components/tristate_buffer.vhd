library ieee;
use ieee.std_logic_1164.all;

entity tristate_buffer is
    generic(data_width: integer);
    port(
        enable: in std_ulogic;
        data_in: in std_ulogic_vector((data_width - 1) downto 0);
        data_out: out std_logic_vector((data_width - 1) downto 0)
    );
end entity;

architecture struct of tristate_buffer is
begin
    with enable
    select data_out <=
        std_logic_vector(data_in) when '1',
        (others => 'Z')           when '0',
        (others => 'X')           when others;
end architecture;
