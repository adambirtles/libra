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
    type data_vector is array(integer range <>) of std_ulogic_vector((data_width - 1) downto 0);

    signal reg_outs: data_vector(0 to 15);
    signal reg_write_enables: std_ulogic_vector(0 to 15);

    signal selected_x: std_ulogic_vector(0 to 15);
    signal selected_y: std_ulogic_vector(0 to 15);
begin
    x_decoder: entity work.binary_decoder(struct)
        generic map(binary_width => 4)
        port map(
            binary => x_select,
            decoded => selected_x
        );

    y_decoder: entity work.binary_decoder(struct)
        generic map(binary_width => 4)
        port map(
            binary => y_select,
            decoded => selected_y
        );

    gen_regs: for r in 0 to 15 generate
        reg_write_enables(r) <= x_write_enable and selected_x(r);

        reg: entity work.parallel_register(rtl)
            generic map(data_width => data_width)
            port map(
                clock => clock,
                n_reset => n_reset,
                write_enable => reg_write_enables(r),
                data_in => x_in,
                data_out => reg_outs(r)
            );

        x_buf: entity work.tristate_buffer(struct)
            generic map(data_width => data_width)
            port map(
                enable => selected_x(r),
                data_in => reg_outs(r),
                data_out => x_out
            );

        y_buf: entity work.tristate_buffer(struct)
            generic map(data_width => data_width)
            port map(
                enable => selected_y(r),
                data_in => reg_outs(r),
                data_out => y_out
            );
    end generate;
end architecture;

