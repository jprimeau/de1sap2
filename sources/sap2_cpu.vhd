-- DESCRIPTION: SAP-2 - CPU
-- AUTHOR: Jonathan Primeau

-- TODO:
--  o Use 16-bit address
--  o Implement IN byte
--  o Implement PS/2 interface
--  o Fix OUT byte (output selection)
--  o Use external SRAM
--  o Implement serial interface

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.sap2_pkg.all;

entity sap2_cpu is
    port (
        clock       : in t_wire;
        reset       : in t_wire;
        data_in     : in t_data;
        addr_out    : out t_address;
        data_out    : out t_data;
        read_out    : out t_wire;
        write_out   : out t_wire;
        
        -- BEGIN: SIMULATION ONLY
        con_out     : out t_control;
        bus_out     : out t_bus;
        acc_out     : out t_data;
        tmp_out     : out t_data;
        alu_out     : out t_data;
        b_out       : out t_data;
        c_out       : out t_data
        -- END: SIMULATION ONLY
    );
end entity sap2_cpu;

architecture behv of sap2_cpu is

    signal clk      : t_wire;

    signal ns, ps   : t_cpu_state;

    signal ACC_reg  : t_data;
    signal TMP_reg  : t_data;
    signal ALU_reg  : t_data;
    signal B_reg    : t_data;
    signal C_reg    : t_data;
    signal PC_reg   : t_address;
    signal MAR_reg  : t_address;
    signal MDR_reg  : t_data;
    signal I_reg    : t_data;
    signal O_reg    : t_data;
    
    signal w_bus    : t_bus;
    signal w_bus_h  : t_data;
    signal w_bus_l  : t_data;
    
    signal op_code  : t_opcode;
    
    signal alu_code : t_alucode;

    signal con      : t_control := (others => '0');
    
    signal flag_z   : t_wire;
    signal flag_s   : t_wire;
    
begin
    w_bus_h     <= w_bus(15 downto 8);
    w_bus_l     <= w_bus(7 downto 0);
    
    addr_out    <= MAR_reg;
    data_out    <= MDR_reg;
    read_out    <= not con(Wr);
    write_out   <= con(Wr);
    
    -- BEGIN: SIMULATION ONLY
    con_out     <= con;
    bus_out     <= w_bus;
    acc_out     <= ACC_reg;
    tmp_out     <= TMP_reg;
    alu_out     <= ALU_reg;
    -- END: SIMULATION ONLY

    run:
    process (clock, reset, con)
    begin
        if reset = '1' then
            clk <= '0';
        else
            if con(HALT) = '1' then
                clk <= '0';
            else
                clk <= clock;
            end if;
        end if;
    end process run;

    program_counter:
    process (clk, reset)
    begin
        if reset = '1' then
            PC_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if con(Cp) = '1' then
                PC_reg <= PC_reg + 1;
            elsif con(Lp) = '1' then
                PC_reg <= w_bus;
            end if;
        end if;
    end process program_counter;
    w_bus <= PC_reg when con(Ep) = '1' else (others => 'Z');
    
    MAR_register:
    process (clk, reset)
    begin
        if reset = '1' then
            MAR_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lmar) = '1' then
                MAR_reg <= w_bus;
            end if;
        end if;
    end process MAR_register;
    
    MDR_register:
    process (clk, reset)
    begin
        if reset = '1' then
            MDR_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if con(Lmdr) = '1' then
                MDR_reg <= w_bus_l;
            else
                MDR_reg <= data_in;
            end if;
        end if;
    end process MDR_register;
    w_bus_l <= MDR_reg when con(Emdr) = '1' else (others => 'Z');
    w_bus_h <= MDR_reg when con(EmdrH) = '1' else (others => 'Z');
    
    ACC_register:
    process (clk, reset)
    begin
        if reset = '1' then
            ACC_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(La) = '1' then
                ACC_reg <= w_bus_l;
            end if;
        end if;
    end process ACC_register;
    w_bus_l <= ACC_reg when con(Ea) = '1' else (others => 'Z');
    
    TMP_register:
    process (clk, reset)
    begin
        if reset = '1' then
            TMP_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lt) = '1' then
                TMP_reg <= w_bus_l;
            end if;
        end if;
    end process TMP_register;
    w_bus_l <= TMP_reg when con(Et) = '1' else (others => 'Z');
    
    B_register:
    process (clk, reset)
    begin
        if reset = '1' then
            B_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lb) = '1' then
                B_reg <= w_bus_l;
            end if;
        end if;
    end process B_register;
    w_bus_l <= B_reg when con(Eb) = '1' else (others => 'Z');
    
    C_register:
    process (clk, reset)
    begin
        if reset = '1' then
            C_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lc) = '1' then
                C_reg <= w_bus_l;
            end if;
        end if;
    end process C_register;
    w_bus_l <= C_reg when con(Ec) = '1' else (others => 'Z');
    
    I_register:
    process (clk, reset)
    begin
        if reset = '1' then
            I_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Li) = '1' then
                I_reg <= w_bus_l;
            end if;
        end if;
    end process I_register;
    op_code <= I_reg;

    O_register:
    process (clk, reset)
    begin
        if reset = '1' then
            O_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if con(Lo) = '1' then
                O_reg <= w_bus_l;
            end if;
        end if;
    end process O_register;
    
    arithmetic_logic_unit:
    process (clk, reset)
        variable a  : t_data;
        variable b  : t_data;
    begin
        if reset = '1' then
            ALU_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lu) = '1' then
                a := w_bus_l;
                b := TMP_reg;
                case alu_code is
                when ALU_NOT =>
                    ALU_reg <= not a;
                when ALU_AND =>
                    ALU_reg <= a and b;
                when ALU_OR =>
                    ALU_reg <= a or b;
                when ALU_XOR =>
                    ALU_reg <= a xor b;
                when ALU_ROL =>
                    ALU_reg <= to_stdlogicvector(to_bitvector(a) rol 1);
                when ALU_ROR =>
                    ALU_reg <= to_stdlogicvector(to_bitvector(a) ror 1);
                when ALU_ONES =>
                    ALU_reg <= (others => '1');
                when ALU_INC =>
                    ALU_reg <= a + 1;
                when ALU_DEC =>
                    ALU_reg <= a - 1;
                when ALU_ADD =>
                    ALU_reg <= a + b;
                when ALU_SUB =>
                    ALU_reg <= a - b;
                when others =>
                    null;
                end case;
            end if;
        end if;
    end process arithmetic_logic_unit;
    w_bus_l <= ALU_reg when con(Eu) = '1' else (others => 'Z');
    
    flags:
    process (clk, con)
    begin
        if clk'event and clk = '1' then
            if con(Lsz) = '1' then
                if ALU_reg(7) = '1' then
                    flag_s <= '1';
                else
                    flag_s <= '0';
                end if;
                if ALU_reg = "0" then
                    flag_z <= '1';
                else
                    flag_z <= '0';
                end if;
            end if;
        end if;
    end process flags;
    
    cpu_state_machine_reg:
    process (clk, reset)
    begin
        if reset = '1' then
            ps <= reset_state;
        elsif clk'event and clk='0' then
            ps <= ns;
        end if;
    end process cpu_state_machine_reg;
    
    cpu_state_machine_transitions:
    process (ps, op_code)
    begin
        con <= (others => '0');
        case ps is
        
        when reset_state =>
            ns <= address_state;
        
		when address_state =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
			ns <= increment_state;
            
		when increment_state =>
            con(Cp) <= '1';
			ns <= memory_state;
            
		when memory_state =>
            con(Emdr) <= '1';
            con(Li) <= '1';
			ns <= decode_instruction;
            
		when decode_instruction =>
            case op_code is
            when ADDB =>
                con(Eb) <= '1';
                con(Lt) <= '1';
                ns <= add_1;
            when ADDC =>
                con(Ec) <= '1';
                con(Lt) <= '1';
                ns <= add_1;
            when ANAB =>
                con(Eb) <= '1';
                con(Lt) <= '1';
                ns <= ana_1;
            when ANAC =>
                con(Ec) <= '1';
                con(Lt) <= '1';
                ns <= ana_1;
            when ANI =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= ani_1;
            when CALL =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= call_1;
            when CMA =>
                alu_code <= ALU_NOT;
                con(Eu) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when DCRA =>
                alu_code <= ALU_DEC;
                con(Ea) <= '1';
                con(Lu) <= '1';
                ns <= dcra_1;
            when DCRB =>
                alu_code <= ALU_DEC;
                con(Eb) <= '1';
                con(Lu) <= '1';
                ns <= dcrb_1;
            when DCRC =>
                alu_code <= ALU_DEC;
                con(Ec) <= '1';
                con(Lu) <= '1';
                ns <= dcrc_1;
            when HLT =>
                con(HALT) <= '1';
                ns <= address_state;
            when INRA =>
                alu_code <= ALU_INC;
                con(Eu) <= '1';
                con(La) <= '1';
                con(Lsz) <= '1';
                ns <= address_state;
            when INRB =>
                con(Eb) <= '1';
                con(La) <= '1';
                ns <= inrb_1;
            when INRC =>
                con(Ec) <= '1';
                con(La) <= '1';
                ns <= inrc_1;
            when JM =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= jm_1;
            when JMP =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= jmp_1;
            when JNZ =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= jnz_1;
            when JZ =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= jz_1;
            when LDA =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= lda_1;
            when MOVAB =>
                con(Ea) <= '1';
                con(Lb) <= '1';
                ns <= address_state;
            when MOVAC =>
                con(Ea) <= '1';
                con(Lc) <= '1';
                ns <= address_state;
            when MOVBA =>
                con(Eb) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when MOVBC =>
                con(Eb) <= '1';
                con(Lc) <= '1';
                ns <= address_state;
            when MOVCA =>
                con(Ec) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when MOVCB =>
                con(Ec) <= '1';
                con(Lb) <= '1';
                ns <= address_state;
            when MVIA =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= mvia_1;
            when MVIB =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= mvib_1;
            when MVIC =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= mvic_1;
            when NOP =>
                ns <= address_state;
            when ORAB =>
                con(Eb) <= '1';
                con(Lt) <= '1';
                ns <= ora_1;
            when ORAC =>
                con(Ec) <= '1';
                con(Lt) <= '1';
                ns <= ora_1;
            when ORI =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= ori_1;
            when OUTB =>
                con(Ea) <= '1';
                con(Lo) <= '1';
                ns <= address_state;
            when RAL =>
                alu_code <= ALU_ROL;
                con(Eu) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when RAR =>
                alu_code <= ALU_ROR;
                con(Eu) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when RET =>
                alu_code <= ALU_ONES;
                con(Eu) <= '1';
                con(Lmar) <= '1';
                ns <= ret_1;
            when STA =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= sta_1;
            when SUBB =>
                con(Eb) <= '1';
                con(Lt) <= '1';
                ns <= sub_1;
            when SUBC =>
                con(Ec) <= '1';
                con(Lt) <= '1';
                ns <= sub_1;
            when XRAB =>
                con(Eb) <= '1';
                con(Lt) <= '1';
                ns <= xra_1;
            when XRAC =>
                con(Ec) <= '1';
                con(Lt) <= '1';
                ns <= xra_1;
            when XRI =>
                con(Ep) <= '1';
                con(Lmar) <= '1';
                ns <= xri_1;
            when others =>
                ns <= address_state;
            end case;

        when add_1 =>
            alu_code <= ALU_ADD;
            con(Ea) <= '1';
            con(Lu) <= '1';
            ns <= add_2;
        when add_2 =>
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;
       
        when ana_1 =>
            alu_code <= ALU_AND;
            con(Ea) <= '1';
            con(Lu) <= '1';
            ns <= ana_2;
        when ana_2 =>
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when ani_1 =>
            con(Cp) <= '1';
            ns <= ani_2;
        when ani_2 =>
            con(Emdr) <= '1';
            con(Lt) <= '1';
            ns <= ani_3;
        when ani_3 =>
            alu_code <= ALU_AND;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when call_1 =>
            con(Cp) <= '1';
            ns <= call_2;
        when call_2 =>
            con(Ep) <= '1';
            con(Lt) <= '1';
            ns <= call_3;
        when call_3 =>
            con(Emdr) <= '1';
            con(Lp) <= '1';
            ns <= call_4;
        when call_4 =>
            alu_code <= ALU_ONES;
            con(Eu) <= '1';
            con(Lmar) <= '1';
            ns <= call_5;
        when call_5 =>
            ns <= call_6; -- Sleep 1 cycle
        when call_6 =>
            con(Et) <= '1';
            con(Wr) <= '1';
            ns <= address_state;

        when dcra_1 =>
            ns <= dcra_2;
        when dcra_2 =>
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when dcrb_1 =>
            ns <= dcrb_2;
        when dcrb_2 =>
            con(Eu) <= '1';
            con(Lb) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when dcrc_1 =>
            ns <= dcrc_2;
        when dcrc_2 =>
            con(Eu) <= '1';
            con(Lc) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when inrb_1 =>
            alu_code <= ALU_INC;
            con(Eu) <= '1';
            con(Lb) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when inrc_1 =>
            alu_code <= ALU_INC;
            con(Eu) <= '1';
            con(Lc) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when jm_1 =>
            con(Cp) <= '1';
            ns <= jm_2;
        when jm_2 =>
            if flag_s = '1' then
                con(Emdr) <= '1';
                con(Lp) <= '1';
            end if;
            ns <= address_state;

        when jmp_1 =>
            con(Cp) <= '1';
            ns <= jmp_2;
        when jmp_2 =>
            con(Emdr) <= '1';
            con(Lt) <= '1';
            ns <= jmp_3;
        when jmp_3 =>
            con(Cp) <= '1';
            ns <= jmp_4;
        when jmp_4 =>
            con(EmdrH) <= '1';
            con(Et) <= '1';
            con(Lp) <= '1';
            ns <= address_state;

        when jnz_1 =>
            con(Cp) <= '1';
            ns <= jnz_2;
        when jnz_2 =>
            if flag_z = '0' then
                con(Emdr) <= '1';
                con(Lp) <= '1';
            end if;
            ns <= address_state;

        when jz_1 =>
            con(Cp) <= '1';
            ns <= jz_2;
        when jz_2 =>
            if flag_z = '1' then
                con(Emdr) <= '1';
                con(Lp) <= '1';
            end if;
            ns <= address_state;

        when lda_1 =>
            con(Cp) <= '1';
            ns <= lda_2;
        when lda_2 =>
            con(Emdr) <= '1';
            con(Lt) <= '1';
            ns <= lda_3;
        when lda_3 =>
            con(Cp) <= '1';
            ns <= lda_4;
        when lda_4 =>
            con(EmdrH) <= '1';
            con(Et) <= '1';
            con(Lmar) <= '1';
            ns <= lda_5;
        when lda_5 =>
            con(Emdr) <= '1';
            con(La) <= '1';
            ns <= address_state;

        when mvia_1 =>
            con(Cp) <= '1';
            ns <= mvia_2;
        when mvia_2 =>
            con(Emdr) <= '1';
            con(La) <= '1';
            ns <= address_state;

        when mvib_1 =>
            con(Cp) <= '1';
            ns <= mvib_2;
        when mvib_2 =>
            con(Emdr) <= '1';
            con(Lb) <= '1';
            ns <= address_state;

        when mvic_1 =>
            con(Cp) <= '1';
            ns <= mvic_2;
        when mvic_2 =>
            con(Emdr) <= '1';
            con(Lc) <= '1';
            ns <= address_state;

        when ora_1 =>
            alu_code <= ALU_OR;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when ori_1 =>
            con(Cp) <= '1';
            ns <= ori_2;
        when ori_2 =>
            con(Emdr) <= '1';
            con(Lt) <= '1';
            ns <= ori_3;
        when ori_3 =>
            alu_code <= ALU_OR;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when ret_1 =>
            ns <= ret_2; -- Sleep 1 cycle
        when ret_2 =>
            con(Emdr) <= '1';
            con(Lp) <= '1';
            ns <= address_state;

        when sta_1 =>
            con(Cp) <= '1';
            ns <= sta_2;
        when sta_2 =>
            con(Emdr) <= '1';
            con(Lt) <= '1';
            ns <= sta_3;
        when sta_3 =>
            con(Cp) <= '1';
            ns <= sta_4;
        when sta_4 =>
            con(EmdrH) <= '1';
            con(Et) <= '1';
            con(Lmar) <= '1';
            ns <= sta_5;
        when sta_5 =>
            con(Ea) <= '1';
            con(Lmdr) <= '1';
            ns <= sta_6;
        when sta_6 =>
            con(Wr) <= '1';
            ns <= address_state;

        when sub_1 =>
            alu_code <= ALU_SUB;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;
  
        when xra_1 =>
            alu_code <= ALU_XOR;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when xri_1 =>
            con(Cp) <= '1';
            ns <= ori_2;
        when xri_2 =>
            con(Emdr) <= '1';
            con(Lt) <= '1';
            ns <= xri_3;
        when xri_3 =>
            alu_code <= ALU_XOR;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

		when others =>
			con <= (others=>'0');
			ns <= address_state;
		end case;
    end process cpu_state_machine_transitions;

end architecture behv;