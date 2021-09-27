library ieee;
use ieee.std_logic_1164.all;

entity parallel_register_file is
    generic(data_width: integer);
    port(
        clock: in std_ulogic;
        n_reset: in std_ulogic;

        x_select: in std_ulogic_vector(3 downto 0);
        x_write_enable: in std_ulogic;
        x_in: in std_ulogic_vector((data_width - 1) downto 0);
        x_out: out std_logic_vector((data_width - 1) downto 0);

        y_select: in std_ulogic_vector(3 downto 0);
        y_out: out std_logic_vector((data_width - 1) downto 0)
    );
end entity;

architecture rtl of parallel_register_file is
    type std_ulogic_vector_vector is array(integer range <>) of std_ulogic_vector((data_width - 1) downto 0);

    signal reg_outs: std_ulogic_vector_vector(0 to 15);
    signal write_enabled: std_ulogic_vector(0 to 15);
    signal x_selected: std_ulogic_vector(0 to 15);
    signal y_selected: std_ulogic_vector(0 to 15);
begin
    x_decoder: entity work.binary_decoder(struct)
        generic map(binary_width => 4)
        port map(
            binary => x_select,
            decoded => x_selected
        );

    y_decoder: entity work.binary_decoder(struct)
        generic map(binary_width => 4)
        port map(
            binary => y_select,
            decoded => y_selected
        );

    gen_regs: for r in 0 to 15 generate
        write_enabled(r) <= x_write_enable and x_selected(r);

        reg: entity work.parallel_register(rtl)
            generic map(data_width => data_width)
            port map(
                clock => clock,
                n_reset => n_reset,
                write_enable => write_enabled(r),
                data_in => x_in,
                data_out => reg_outs(r)
            );

        x_buf: entity work.tristate_buffer(struct)
            generic map(data_width => data_width)
            port map(
                enable => x_selected(r),
                data_in => reg_outs(r),
                data_out => x_out
            );

        y_buf: entity work.tristate_buffer(struct)
            generic map(data_width => data_width)
            port map(
                enable => y_selected(r),
                data_in => reg_outs(r),
                data_out => y_out
            );
    end generate;
end architecture;

