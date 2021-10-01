library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity incrementer is
    generic(data_width: integer);
    port(
        data_in: in std_ulogic_vector((data_width - 1) downto 0);
        data_out: out std_ulogic_vector((data_width - 1) downto 0)
    );
end entity;

architecture struct of incrementer is
begin
    data_out <= std_ulogic_vector(unsigned(data_in) + to_unsigned(1, data_width));
end architecture;
