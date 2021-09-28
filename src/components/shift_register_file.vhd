library ieee;
use ieee.std_logic_1164.all;

entity shift_register_file is
    generic(data_width: integer);
    port(
        clock: in std_ulogic;
        n_reset: in std_ulogic;

        shift_enable: in std_ulogic;

        x_select: in std_ulogic_vector(3 downto 0);
        x_in: in std_ulogic;
        x_out: out std_logic_vector((data_width - 1) downto 0);

        y_select: in std_ulogic_vector(3 downto 0);
        y_out: out std_logic_vector((data_width - 1) downto 0)
    );
end entity;

architecture rtl of shift_register_file is
    type std_ulogic_vector_vector is array(integer range <>) of std_ulogic_vector((data_width - 1) downto 0);

    signal reg_ins: std_ulogic_vector(0 to 15);
    signal reg_outs: std_ulogic_vector_vector(0 to 15);
    signal reg_shift_enables: std_ulogic_vector(0 to 15);

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
        reg_shift_enables(r) <= shift_enable and (selected_x(r) or selected_y(r));

        with selected_x(r) select reg_ins(r) <=
            x_in           when '1',
            reg_outs(r)(0) when '0';

        reg: entity work.sipo_register(rtl)
            generic map(data_width => data_width)
            port map(
                clock => clock,
                n_reset => n_reset,
                shift_enable => reg_shift_enables(r),
                data_in => reg_ins(r),
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

