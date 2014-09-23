-- DESCRIPTION: SAP-2 - CPU
-- AUTHOR: Jonathan Primeau

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.sap2_pkg.all;

entity sap2_cpu is
    port (
        clock       : in std_logic;
        reset       : in std_logic;

        halt_out    : out std_logic;
        p0_out      : out std_logic_vector(7 downto 0)
    );
end entity sap2_cpu;

architecture microcoded of sap2_cpu is

    signal clk  : std_logic;

    type t_ram is array (0 to 255) of t_data;

    signal ram : t_ram := (
        x"C3",x"50",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00H
        x"3A",x"FF",x"06",x"02",x"80",x"D3",x"00",x"00", -- 08H
        x"3A",x"FE",x"0E",x"04",x"81",x"D3",x"00",x"00", -- 10H
        x"3E",x"FF",x"06",x"0F",x"0E",x"0A",x"A0",x"D3", -- 18H
        x"A1",x"D3",x"E6",x"02",x"D3",x"76",x"FF",x"FF", -- 20H
        x"3E",x"AB",x"32",x"FF",x"3E",x"00",x"3A",x"FF", -- 28H
        x"D3",x"76",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 30H
        x"3E",x"01",x"17",x"D3",x"1F",x"D3",x"76",x"FF", -- 38H
        x"3E",x"FF",x"FA",x"48",x"3E",x"0A",x"D3",x"76", -- 40H
        x"3E",x"0B",x"D3",x"76",x"FF",x"FF",x"FF",x"FF", -- 48H
        x"CD",x"58",x"3E",x"AB",x"D3",x"76",x"FF",x"FF", -- 50H
        x"3A",x"FF",x"D3",x"76",x"FF",x"FF",x"FF",x"FF", -- 58H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 60H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 68H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 70H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"02",x"01", -- 78H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 80H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 88H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 90H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 98H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- A0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- A8H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- B0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- B8H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- C0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- C8H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- D0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- D8H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- E0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- E8H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- F0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"03",x"01"  -- F8H
    );

    signal ns, ps   : t_cpu_state;

    signal ACC_reg  : t_data;
    signal TMP_reg  : t_data;
    signal B_reg    : t_data;
    signal C_reg    : t_data;
    signal PC_reg   : t_address;
    signal MAR_reg  : t_address;
    signal MDR_reg  : t_data;
    signal I_reg    : t_data;
    signal O_reg    : t_data;
    
    signal w_bus    : t_address;
    
    signal op_code  : t_opcode;
    
    signal alu_code : t_alucode;
    
    signal alu_result   : t_data;

    signal con      : std_logic_vector(20 downto 0) := (others => '0');
    
    signal flag_z   : std_logic;
    signal flag_s   : std_logic;
    
begin

    halt_out <= con(HALT);
    p0_out <= O_reg;
    
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
    process (clk, reset, con)
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
        if con(Ep) = '1' then
            w_bus <= PC_reg;
        else
            w_bus <= (others => 'Z');
        end if;
    end process program_counter;
    
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
    
    memory:
    process (clk, con)
    begin
        if clk'event and clk = '0' then
            if con(Mw) = '1' then
                ram(conv_integer(MAR_reg)) <= w_bus;
            end if;
        end if;
        if con(Emdr) = '1' then
            w_bus <= ram(conv_integer(MAR_reg));
        else
            w_bus <= (others => 'Z');
        end if;
    end process memory;
    
--    MDR_register:
--    process (clk)
--    begin
--        if reset = '1' then
--            MDR_reg <= (others => '0');
--        elsif clk'event and clk = '0' then
--            if con(Lmdr) = '1' then
--                MDR_reg <= w_bus;
--            end if;
--        end if;
--    end process MDR_register;
    
    ACC_register:
    process (clk, reset, con)
    begin
        if reset = '1' then
            ACC_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(La) = '1' then
                ACC_reg <= w_bus;
            end if;
        end if;
        if con(Ea) = '1' then
            w_bus <= ACC_reg;
        else
            w_bus <= (others => 'Z');
        end if;
    end process ACC_register;
    
    TMP_register:
    process (clk, reset, con)
    begin
        if reset = '1' then
            TMP_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lt) = '1' then
                TMP_reg <= w_bus;
            end if;
        end if;
        if con(Et) = '1' then
            w_bus <= TMP_reg;
        else
            w_bus <= (others => 'Z');
        end if;
    end process TMP_register;
    
    B_register:
    process (clk, reset, con)
    begin
        if reset = '1' then
            B_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lb) = '1' then
                B_reg <= w_bus;
            end if;
        end if;
        if con(Eb) = '1' then
            w_bus <= B_reg;
        else
            w_bus <= (others => 'Z');
        end if;
    end process B_register;
    
    C_register:
    process (clk, reset, con)
    begin
        if reset = '1' then
            C_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lc) = '1' then
                C_reg <= w_bus;
            end if;
        end if;
        if con(Ec) = '1' then
            w_bus <= C_reg;
        else
            w_bus <= (others => 'Z');
        end if;
    end process C_register;
    
    I_register:
    process (clk, reset, con)
    begin
        if reset = '1' then
            I_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Li) = '1' then
                I_reg <= w_bus;
            end if;
        end if;
        if con(Ei) = '1' then
            w_bus <= I_reg;
        else
            w_bus <= (others => 'Z');
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
                O_reg <= w_bus;
            end if;
        end if;
    end process O_register;

    arithmetic_logic_unit:
    process (clk, con)
    begin
        if con(Eu) = '1' then
            w_bus <= alu_result;
        else
            w_bus <= (others => 'Z');
        end if;
    end process arithmetic_logic_unit;
    
    alu: entity work.sap2_alu
    port map (
        a           => ACC_reg,
        b           => TMP_reg,
        cin         => '0',
        code        => alu_code,
        result      => alu_result,
        cout        => open
    );
    
    flags:
    process (clk)
    begin
        if clk'event and clk = '1' then
            if ACC_reg(7) = '1' then
                flag_s <= '1';
            else
                flag_s <= '0';
            end if;
            if ACC_reg = "0" then
                flag_z <= '1';
            else
                flag_z <= '0';
            end if;
        end if;
    end process flags;
    
    cpu_state_machine_reg:
    process (clk)
    begin
        if reset = '1' then
            ps <= fetch_address;
        elsif clk'event and clk='1' then
            ps <= ns;
        end if;
    end process cpu_state_machine_reg;
    
    cpu_state_machine_transitions:
    process (ps)
    begin
        con <= (others => '0');
        case ps is
        
		when fetch_address =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
			ns <= increment_pc_load_instruction;
            
		when increment_pc_load_instruction =>
            con(Cp) <= '1';
            con(Emdr) <= '1';
            con(Li) <= '1';
			ns <= decode_instruction;
            
		when decode_instruction =>
            case op_code is
            when ADDB =>
                ns <= addb_0;
            when ADDC =>
                ns <= addc_0;
            when ANAB =>
                ns <= anab_0;
            when ANAC =>
                ns <= anac_0;
            when ANI =>
                ns <= ani_0;
            when CALL =>
                ns <= call_0;
            when CMA =>
                ns <= cma_0;
            when DCRA =>
                ns <= dcra_0;
            when DCRB =>
                ns <= dcrb_0;
            when DCRC =>
                ns <= dcrc_0;
            when HLT =>
                ns <= hlt_0;
            when INRA =>
                ns <= inra_0;
            when INRB =>
                ns <= inrb_0;
            when INRC =>
                ns <= inrc_0;
            when JM =>
                ns <= jm_0;
            when JMP =>
                ns <= jmp_0;
            when JNZ =>
                ns <= jnz_0;
            when JZ =>
                ns <= jz_0;
            when LDA =>
                ns <= lda_0;
            when MOVAB =>
                ns <= movab_0;
            when MOVAC =>
                ns <= movac_0;
            when MOVBA =>
                ns <= movba_0;
            when MOVBC =>
                ns <= movbc_0;
            when MOVCA =>
                ns <= movca_0;
            when MOVCB =>
                ns <= movcb_0;
            when MVIA =>
                ns <= mvia_0;
            when MVIB =>
                ns <= mvib_0;
            when MVIC =>
                ns <= mvic_0;
            when NOP =>
                ns <= nop_0;
            when ORAB =>
                ns <= orab_0;
            when ORAC =>
                ns <= orac_0;
            when ORI =>
                ns <= ori_0;
            when OUTB =>
                ns <= out_0;
            when RAL =>
                ns <= ral_0;
            when RAR =>
                ns <= rar_0;
            when STA =>
                ns <= sta_0;
            when SUBB =>
                ns <= subb_0;
            when SUBC =>
                ns <= subc_0;
            when XRAB =>
                ns <= xrab_0;
            when XRAC =>
                ns <= xrac_0;
            when XRI =>
                ns <= xri_0;
            when others =>
                ns <= fetch_address;
            end case;
            
        -- ***** ADD B
        when addb_0 =>
            con(Eb) <= '1';
            con(Lt) <= '1';
            ns <= add_1;
            
        -- ***** ADD C
        when addc_0 =>
            con(Ec) <= '1';
            con(Lt) <= '1';
            ns <= add_1;
            
        when add_1 =>
            alu_code <= ALU_APLUSB;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
            
        -- ***** ANA B
        when anab_0 =>
            con(Eb) <= '1';
            con(Lt) <= '1';
            ns <= ana_1;
            
        -- ***** ANA C
        when anac_0 =>
            con(Ec) <= '1';
            con(Lt) <= '1';
            ns <= ana_1;
            
        when ana_1 =>
            alu_code <= ALU_AANDB;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
            
        -- ***** ANI byte
        when ani_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= ani_1;
        when ani_1 =>
            con(Cp) <= '1';
            ns <= ani_2;
        when ani_2 =>
            con(Emdr) <= '1';
            con(Lt) <= '1';
            ns <= ani_3;
        when ani_3 =>
            alu_code <= ALU_AANDB;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
            
        -- ***** CALL address
        when call_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= call_0w;
        when call_0w =>
            ns <= call_1; -- SLEEP
        when call_1 =>
            con(Cp) <= '1';
            ns <= call_1w;
        when call_1w =>
            ns <= call_2; -- SLEEP
        when call_2 =>
            con(Ep) <= '1';
            con(Lt) <= '1';
            ns <= call_2w;
        when call_2w =>
            ns <= call_3; -- SLEEP
        when call_3 =>
            con(Emdr) <= '1';
            con(Lp) <= '1';
            ns <= call_3w;
        when call_3w =>
            ns <= call_4; -- SLEEP
        when call_4 =>
            alu_code <= ALU_ONES;
            con(Eu) <= '1';
            con(Lmar) <= '1';
            ns <= call_4w;
        when call_4w =>
            ns <= call_5; -- SLEEP
        when call_5 =>
            con(Et) <= '1';
            con(Mw) <= '1';
            ns <= call_5w;
        when call_5w =>
            ns <= fetch_address; -- SLEEP
            
        -- ***** CMA
        when cma_0 =>
            alu_code <= ALU_NOTA;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
            
        -- ***** DCR A
        when dcra_0 =>
            con(Ea) <= '1';
            con(Lt) <= '1';
            ns <= dcra_1;
        when dcra_1 =>
            alu_code <= ALU_DECB;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
            
        -- ***** DCR B
        when dcrb_0 =>
            con(Eb) <= '1';
            con(Lt) <= '1';
            ns <= dcrb_1;
        when dcrb_1 =>
            alu_code <= ALU_DECB;
            con(Eu) <= '1';
            con(Lb) <= '1';
            ns <= fetch_address;
            
        -- ***** DCR C
        when dcrc_0 =>
            con(Ec) <= '1';
            con(Lt) <= '1';
            ns <= dcrc_1;
        when dcrc_1 =>
            alu_code <= ALU_DECB;
            con(Eu) <= '1';
            con(Lc) <= '1';
            ns <= fetch_address;
            
        -- ***** HLT
        when hlt_0 =>
            con(HALT) <= '1';
            ns <= fetch_address;
            
        -- ***** INR A
        when inra_0 =>
            con(Ea) <= '1';
            con(Lt) <= '1';
            ns <= inra_1;
        when inra_1 =>
            alu_code <= ALU_INCB;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
            
        -- ***** INR B
        when inrb_0 =>
            con(Eb) <= '1';
            con(Lt) <= '1';
            ns <= inrb_1;
        when inrb_1 =>
            alu_code <= ALU_INCB;
            con(Eu) <= '1';
            con(Lb) <= '1';
            ns <= fetch_address;
            
        -- ***** INR C
        when inrc_0 =>
            con(Ec) <= '1';
            con(Lt) <= '1';
            ns <= inrc_1;
        when inrc_1 =>
            alu_code <= ALU_INCB;
            con(Eu) <= '1';
            con(Lc) <= '1';
            ns <= fetch_address;
            
        -- ***** JM address
        when jm_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= jm_1;
        when jm_1 =>
            con(Cp) <= '1';
            ns <= jm_2;
        when jm_2 =>
            if flag_s = '1' then
                con(Emdr) <= '1';
                con(Lp) <= '1';
            end if;
            ns <= fetch_address;
            
        -- ***** JMP address
        when jmp_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= jmp_1;
        when jmp_1 =>
            con(Cp) <= '1';
            ns <= jmp_2;
        when jmp_2 =>
            con(Emdr) <= '1';
            con(Lp) <= '1';
            ns <= fetch_address;
            
        -- ***** JNZ address
        when jnz_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= jnz_1;
        when jnz_1 =>
            con(Cp) <= '1';
            ns <= jnz_2;
        when jnz_2 =>
            if flag_z = '1' then
                con(Emdr) <= '1';
                con(Lp) <= '1';
            end if;
            ns <= fetch_address;
            
        -- ***** JZ address
        when jz_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= jz_1;
        when jz_1 =>
            con(Cp) <= '1';
            ns <= jz_2;
        when jz_2 =>
            if flag_z = '0' then
                con(Emdr) <= '1';
                con(Lp) <= '1';
            end if;
            ns <= fetch_address;
	
        -- ***** LDA address
        when lda_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= lda_1;
        when lda_1 =>
            con(Cp) <= '1';
            ns <= lda_2;
        when lda_2 =>
            con(Emdr) <= '1';
            con(Lmar) <= '1';
            ns <= lda_3;
        when lda_3 =>
            ns <= lda_4; -- Sleep 1 cycle
        when lda_4 =>
            con(Emdr) <= '1';
            con(La) <= '1';
            ns <= fetch_address;

        -- ***** MOVSD
        when movab_0 =>
            con(Ea) <= '1';
            con(Lb) <= '1';
            ns <= fetch_address;
        when movac_0 =>
            con(Ea) <= '1';
            con(Lc) <= '1';
            ns <= fetch_address;
        when movba_0 =>
            con(Eb) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
        when movbc_0 =>
            con(Eb) <= '1';
            con(Lc) <= '1';
            ns <= fetch_address;
        when movca_0 =>
            con(Ec) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
        when movcb_0 =>
            con(Ec) <= '1';
            con(Lb) <= '1';
            ns <= fetch_address;
            
        -- ***** MVIA byte
        when mvia_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= mvia_1;
        when mvia_1 =>
            con(Cp) <= '1';
            ns <= mvia_2;
        when mvia_2 =>
            con(Emdr) <= '1';
            con(La) <= '1';
            ns <= fetch_address;

        -- ***** MVIB byte
        when mvib_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= mvib_1;
        when mvib_1 =>
            con(Cp) <= '1';
            ns <= mvib_2;
        when mvib_2 =>
            con(Emdr) <= '1';
            con(Lb) <= '1';
            ns <= fetch_address;

        -- ***** MVIC byte
        when mvic_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= mvic_1;
        when mvic_1 =>
            con(Cp) <= '1';
            ns <= mvic_2;
        when mvic_2 =>
            con(Emdr) <= '1';
            con(Lc) <= '1';
            ns <= fetch_address;

        -- ***** NOP
        when nop_0 =>
            ns <= fetch_address;
            
        -- ***** ORA B
        when orab_0 =>
            con(Eb) <= '1';
            con(Lt) <= '1';
            ns <= ora_1;
            
        -- ***** ORA C
        when orac_0 =>
            con(Ec) <= '1';
            con(Lt) <= '1';
            ns <= ora_1;
            
        when ora_1 =>
            alu_code <= ALU_AORB;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
            
        -- ***** ORI byte
        when ori_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= ori_1;
        when ori_1 =>
            con(Cp) <= '1';
            ns <= ori_2;
        when ori_2 =>
            con(Emdr) <= '1';
            con(Lt) <= '1';
            ns <= ori_3;
        when ori_3 =>
            alu_code <= ALU_AORB;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;

        -- ***** OUT byte
        when out_0 =>
            con(Ea) <= '1';
            con(Lo) <= '1';
            ns <= fetch_address;
        
        -- ***** RAL
        when ral_0 =>
            alu_code <= ALU_ROLA;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
        
        -- ***** RAR
        when rar_0 =>
            alu_code <= ALU_RORA;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
            
        -- ***** STA address
        when sta_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= sta_1;
        when sta_1 =>
            con(Cp) <= '1';
            ns <= sta_2;
        when sta_2 =>
            con(Emdr) <= '1';
            con(Lmar) <= '1';
            ns <= sta_3;
        when sta_3 =>
            con(Ea) <= '1';
            con(Mw) <= '1';
            ns <= fetch_address;
            
        -- ***** SUB B
        when subb_0 =>
            con(Eb) <= '1';
            con(Lt) <= '1';
            ns <= sub_1;
            
        -- ***** SUB C
        when subc_0 =>
            con(Ec) <= '1';
            con(Lt) <= '1';
            ns <= sub_1;
            
        when sub_1 =>
            alu_code <= ALU_AMINUSB;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
            
        -- ***** XRA B
        when xrab_0 =>
            con(Eb) <= '1';
            con(Lt) <= '1';
            ns <= xra_1;
            
        -- ***** XRA C
        when xrac_0 =>
            con(Ec) <= '1';
            con(Lt) <= '1';
            ns <= xra_1;
            
        when xra_1 =>
            alu_code <= ALU_AXORB;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;
            
        -- ***** XRI byte
        when xri_0 =>
            con(Ep) <= '1';
            con(Lmar) <= '1';
            ns <= xri_1;
        when xri_1 =>
            con(Cp) <= '1';
            ns <= ori_2;
        when xri_2 =>
            con(Emdr) <= '1';
            con(Lt) <= '1';
            ns <= xri_3;
        when xri_3 =>
            alu_code <= ALU_AXORB;
            con(Eu) <= '1';
            con(La) <= '1';
            ns <= fetch_address;

		when others =>
			con <= (others=>'0');
			ns <= fetch_address;
		end case;
    end process cpu_state_machine_transitions;

end architecture microcoded;