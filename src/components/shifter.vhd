library ieee;
use ieee.std_logic_1164.all;

entity shifter is
    generic(data_width: integer);
    port(
        rightwards: in std_ulogic;
        carry_in: in std_ulogic;
        data_in: in std_ulogic_vector((data_width - 1) downto 0);
        data_out: out std_ulogic_vector((data_width - 1) downto 0);
        carry_out: out std_ulogic
    );
end entity;

architecture struct of shifter is
begin
    process(rightwards, carry_in, data_in) is
    begin
        if rightwards = '1' then
            carry_out <= data_in(0);
            data_out((data_width - 2) downto 0) <= data_in((data_width - 1) downto 1);
            data_out(data_width - 1) <= carry_in;
        else
            carry_out <= data_in(data_width - 1);
            data_out((data_width - 1) downto 1) <= data_in((data_width - 2) downto 0);
            data_out(0) <= carry_in;
        end if;
    end process;
end architecture;
