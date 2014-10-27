-- DESCRIPTION: SAP-2 - Top (SoC)
-- AUTHOR: Jonathan Primeau

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.sap2_pkg.all;
use work.all;

entity sap2_top is
    port (
        clock       : in t_wire;
        reset       : in t_wire;
        data_in     : in t_data;
        addr_out    : out t_address;
        data_out    : out t_data;
        read_out    : out t_wire;
        write_out   : out t_wire;
        
        -- BEGIN: SIMULATION ONLY
        load_pgm    : in t_wire;
        pgm_select  : in t_data;
        
        Lp_out      : out t_wire;
        Cp_out      : out t_wire;
        Ep_out      : out t_wire;
        Lmar_out    : out t_wire;
        Emdr_out    : out t_wire;
        --Rd_out      : out t_wire;
        Wr_out      : out t_wire;
        Li_out      : out t_wire;
        La_out      : out t_wire;
        Ea_out      : out t_wire;
        Lt_out      : out t_wire;
        Et_out      : out t_wire;
        Lb_out      : out t_wire;
        Eb_out      : out t_wire;
        Lc_out      : out t_wire;
        Ec_out      : out t_wire;
        Lu_out      : out t_wire;
        Eu_out      : out t_wire;
        Lo_out      : out t_wire;
        Lsz_out     : out t_wire;
        halt_out    : out t_wire;
        
        bus_out     : out t_bus;
        acc_out     : out t_data;
        tmp_out     : out t_data;
        alu_out     : out t_data;
        b_out       : out t_data;
        c_out       : out t_data
        -- END: SIMULATION ONLY
    );
end entity sap2_top;

architecture behv of sap2_top is

    signal clk      : t_wire;

    type t_ram is array (0 to 255) of t_data;
    signal ram : t_ram := (others=>x"FF");
--    signal ram : t_ram := (
--        x"3E",x"AB",x"32",x"0A",x"3E",x"00",x"3A",x"0A", -- 00H
--        x"76",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 08H
----        x"3E",x"AB",x"76",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00H
----        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 08H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 10H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 18H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 20H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 28H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 30H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 38H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 40H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 48H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 50H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 58H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 60H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 68H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 70H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 78H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 80H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 88H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 90H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 98H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- A0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- A8H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- B0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- B8H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- C0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- C8H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- D0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- D8H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- E0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- E8H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- F0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF"  -- F8H
--    );
    
    signal cpu_data_in  : t_data;
    signal cpu_data_out : t_data;
    signal cpu_addr     : t_address;
    signal cpu_read     : t_wire;
    signal cpu_write    : t_wire;
    
    signal cpu_con      : t_control := (others => '0');
    signal cpu_bus      : t_address;
    signal cpu_acc      : t_data;
    signal cpu_tmp      : t_data;
    signal cpu_alu      : t_data;
    signal cpu_b        : t_data;
    signal cpu_c        : t_data;
    
    signal ram_write    : t_wire;
    
begin
    addr_out    <= cpu_addr;
    data_out    <= cpu_data_out;
    read_out    <= cpu_read;
    write_out   <= cpu_write;
    
    -- BEGIN: SIMULATION ONLY
    Lp_out      <= cpu_con(Lp);
    Cp_out      <= cpu_con(Cp);
    Ep_out      <= cpu_con(Ep);
    Lmar_out    <= cpu_con(Lmar);
    Emdr_out    <= cpu_con(Emdr);
    --Rd_out      <= cpu_con(Rd);
    Wr_out      <= cpu_con(Wr);
    Li_out      <= cpu_con(Li);
    La_out      <= cpu_con(La);
    Ea_out      <= cpu_con(Ea);
    Lt_out      <= cpu_con(Lt);
    Et_out      <= cpu_con(Et);
    Lb_out      <= cpu_con(Lb);
    Eb_out      <= cpu_con(Eb);
    Lc_out      <= cpu_con(Lc);
    Ec_out      <= cpu_con(Ec);
    Lu_out      <= cpu_con(Lu);
    Eu_out      <= cpu_con(Eu);
    Lo_out      <= cpu_con(Lo);
    Lsz_out     <= cpu_con(Lsz);
    halt_out    <= cpu_con(HALT);
    
    bus_out     <= cpu_bus;
    acc_out     <= cpu_acc;
    tmp_out     <= cpu_tmp;
    alu_out     <= cpu_alu;
    b_out       <= cpu_b;
    c_out       <= cpu_c;
    -- END: SIMULATION ONLY

    ram_write <= cpu_write when reset = '0' else load_pgm;
    memory:
    process (ram_write)
    begin
        if ram_write'event and ram_write = '1' then
            if load_pgm = '0' then
                ram(conv_integer(cpu_addr)) <= cpu_data_out;
            else
                if pgm_select = x"00" then
                    ram <= (
                        -- 00 MVI A,ABH
                        -- 02 HLT
                        x"3E",x"AB",x"76",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00H
                        others=>x"FF"
                    );
                elsif pgm_select = x"01" then
                    ram <= (
                        -- 00 MVI A,ABH
                        -- 02 STA 0AH
                        -- 04 MVI A,00H
                        -- 06 LDA 0AH
                        -- 08 HLT
                        -- 09 FF
                        x"3E",x"AB",x"32",x"0A",x"3E",x"00",x"3A",x"0A", -- 00H
                        x"76",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 08H
                        others=>x"FF"
                    ); 
                end if;
            end if;
        end if;
    end process memory;
    cpu_data_in <= ram(conv_integer(cpu_addr)) when cpu_read = '1' else (others => 'Z');

    cpu : entity work.sap2_cpu
    port map (
        clock       => clock,
        reset       => reset,
        data_in     => cpu_data_in,
        addr_out    => cpu_addr,
        data_out    => cpu_data_out,
        read_out    => cpu_read,
        write_out   => cpu_write,
        
        -- BEGIN: SIMULATION ONLY
        con_out     => cpu_con,
        bus_out     => cpu_bus,
        acc_out     => cpu_acc,
        tmp_out     => cpu_tmp,
        alu_out     => cpu_alu,
        b_out       => cpu_b,
        c_out       => cpu_c
        -- END: SIMULATION ONLY
    );

end architecture behv;