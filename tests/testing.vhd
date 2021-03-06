library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package testing is
    type data_vector is array (integer range <>) of std_ulogic_vector(7 downto 0);
    subtype mem is data_vector(0 to 4095);

    type cpu_type is (BIT_SERIAL, CLASSICAL);
    type test_state is (STATE_RUNNING, STATE_HALTED, STATE_ERRORED);

    function loc(page: integer; index: integer) return integer;
    function value(n: std_ulogic_vector) return string;

    function cpu_msg(cpu: cpu_type; message: string) return string;
    function cpu_min_period(cpu: cpu_type) return time;
end package;

package body testing is
    function loc(page: integer; index: integer) return integer is
    begin
        return (128 * page) + index;
    end function;

    function value(n: std_ulogic_vector) return string is
    begin
        return integer'image(to_integer(unsigned(n)));
    end function;

    function cpu_msg(cpu: cpu_type; message: string) return string is
    begin
        return cpu_type'image(cpu) & ": " & message;
    end function;

    function cpu_min_period(cpu: cpu_type) return time is
    begin
        case cpu is
            when BIT_SERIAL => return 2.962 ns;
            when CLASSICAL => return 4.254 ns;
        end case;
    end function;
end package body;
