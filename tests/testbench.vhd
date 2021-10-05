library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library libra;

entity testbench is
end entity;

architecture sim of testbench is
    constant FREQUENCY: integer := 100e6; -- 100 MHz
    constant PERIOD: time := 1 sec / FREQUENCY;

    signal clock: std_logic := '1';
    signal n_reset: std_ulogic := '0';
    
    type data_vector is array (integer range <>) of std_ulogic_vector(7 downto 0);
    signal memory: data_vector(0 to 4095) := (others => x"00");
    
    signal mem_read: std_ulogic_vector(7 downto 0);
    signal mem_write: std_ulogic_vector(7 downto 0);
    signal mem_addr: unsigned(11 downto 0);
    signal mem_write_enable: std_ulogic;
    signal halted: std_ulogic;
begin
    mem_read <= memory(to_integer(mem_addr));
     
    uut: entity libra.cpu_parallel(rtl)
        port map(
            clock => clock,
            n_reset => n_reset,
            mem_read => mem_read,
            mem_write => mem_write,
            unsigned(mem_addr) => mem_addr,
            mem_write_enable => mem_write_enable,
            halted => halted
        );

    clock_process: clock <= not clock after PERIOD / 2;

    test_process: process is
        variable m: data_vector(0 to 255);
    begin
        for i in 0 to 255 loop
            m(i) := std_ulogic_vector(to_unsigned(i, 8));
        end loop;
        memory(0 to 255) <= m;
        
        -- Bring CPU out of reset and let it run until halted 
        n_reset <= '1';
        wait until rising_edge(clock);
        
        report "CPU started";
        wait until halted = '1';
        report "CPU halted";
        wait;
    end process;
end architecture;
