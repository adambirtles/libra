library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity binary_decoder is
    generic(binary_width: integer);
    port(
        binary: in std_ulogic_vector((binary_width - 1) downto 0);
        decoded: out std_ulogic_vector(0 to ((2 ** binary_width) - 1))
    );
end entity;

architecture struct of binary_decoder is
begin
    process(binary)
    begin
        decoded <= (others => '0');
        decoded(to_integer(unsigned(binary))) <= '1';
    end process;
end architecture;
