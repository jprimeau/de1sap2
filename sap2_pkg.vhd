-- DESCRIPTION: SAP-2 - PKG
-- AUTHOR: Jonathan Primeau

library ieee;
use ieee.std_logic_1164.all;

package sap2_pkg is

    subtype t_address is std_logic_vector(7 downto 0);
    subtype t_data is std_logic_vector(7 downto 0);
    
    subtype t_opcode is std_logic_vector(7 downto 0);

    -- Op code
    constant ADDB   : t_opcode := x"80";
    constant ADDC   : t_opcode := x"81";
    constant ANAB   : t_opcode := x"A0";
    constant ANAC   : t_opcode := x"A1";
    constant ANI    : t_opcode := x"E6";
    constant CALL   : t_opcode := x"CD";
    constant CMA    : t_opcode := x"2F";
    constant DCRA   : t_opcode := x"3D";
    constant DCRB   : t_opcode := x"05";
    constant DCRC   : t_opcode := x"0D";
    constant HLT    : t_opcode := x"76";
    constant INB    : t_opcode := x"DB";
    constant INRA   : t_opcode := x"3C";
    constant INRB   : t_opcode := x"04";
    constant INRC   : t_opcode := x"0C";
    constant JM     : t_opcode := x"FA";
    constant JMP    : t_opcode := x"C3";
    constant JNZ    : t_opcode := x"C2";
    constant JZ     : t_opcode := x"CA";
    constant LDA    : t_opcode := x"3A";
    constant MOVAB  : t_opcode := x"78";
    constant MOVAC  : t_opcode := x"79";
    constant MOVBA  : t_opcode := x"47";
    constant MOVBC  : t_opcode := x"41";
    constant MOVCA  : t_opcode := x"4F";
    constant MOVCB  : t_opcode := x"48";
    constant MVIA   : t_opcode := x"3E";
    constant MVIB   : t_opcode := x"06";
    constant MVIC   : t_opcode := x"0E";
    constant NOP    : t_opcode := x"00";
    constant ORAB   : t_opcode := x"B0";
    constant ORAC   : t_opcode := x"B1";
    constant ORI    : t_opcode := x"F6";
    constant OUTB   : t_opcode := x"D3";
    constant RAL    : t_opcode := x"17";
    constant RAR    : t_opcode := x"1F";
    constant RET    : t_opcode := x"C9";
    constant STA    : t_opcode := x"32";
    constant SUBB   : t_opcode := x"90";
    constant SUBC   : t_opcode := x"91";
    constant XRAB   : t_opcode := x"A8";
    constant XRAC   : t_opcode := x"A9";
    constant XRI    : t_opcode := x"EE";
    
    constant Lp     : integer := 00;
    constant Cp     : integer := 01;
    constant Ep     : integer := 02;
    constant Lmar   : integer := 03;
    constant Lmdr   : integer := 04;
    constant Emdr   : integer := 05;
    constant Mw     : integer := 06;
    constant Li     : integer := 07;
    constant Ei     : integer := 08;
    constant La     : integer := 09;
    constant Ea     : integer := 10;
    constant Lt     : integer := 11;
    constant Et     : integer := 12;
    constant Lb     : integer := 13;
    constant Eb     : integer := 14;
    constant Lc     : integer := 15;
    constant Ec     : integer := 16;
    constant Eu     : integer := 17;
    constant Su     : integer := 18;
    constant Lo     : integer := 19;
    constant HALT   : integer := 20;
    
    type t_cpu_state is (
        
        fetch_address,
        
        increment_pc_load_instruction,
        
        decode_instruction,
        
        addb_0,
        addc_0,
        add_1,
        
        anab_0,
        anac_0,
        ana_1,
        
        ani_0,
        ani_1,
        ani_2,
        ani_3,
        
        call_0,
        call_1,
        call_2,
        call_3,
        call_4,
        call_5,
        
        call_0w,
        call_1w,
        call_2w,
        call_3w,
        call_4w,
        call_5w,
        
        cma_0,
        
        dcra_0,
        dcra_1,
        
        dcrb_0,
        dcrb_1,
        
        dcrc_0,
        dcrc_1,
        
        hlt_0,
        
        inra_0,
        inra_1,
        
        inrb_0,
        inrb_1,
        
        inrc_0,
        inrc_1,
        
        jm_0,
        jm_1,
        jm_2,
        
        jmp_0,
        jmp_1,
        jmp_2,
        
        jnz_0,
        jnz_1,
        jnz_2,
        
        jz_0,
        jz_1,
        jz_2,
        
        lda_0,
        lda_1,
        lda_2,
        lda_3,
        lda_4,
        
        movab_0,
        movac_0,
        movba_0,
        movbc_0,
        movca_0,
        movcb_0,
        
        mvia_0,
        mvia_1,
        mvia_2,
        mvib_0,
        mvib_1,
        mvib_2,
        mvic_0,
        mvic_1,
        mvic_2,
        
        nop_0,
        
        orab_0,
        orac_0,
        ora_1,
        
        ori_0,
        ori_1,
        ori_2,
        ori_3,
        
        out_0,
        
        ral_0,
        rar_0,
        
        sta_0,
        sta_1,
        sta_2,
        sta_3,
        
        subb_0,
        subc_0,
        sub_1,
        
        xrab_0,
        xrac_0,
        xra_1,
        
        xri_0,
        xri_1,
        xri_2,
        xri_3
    );
    
    subtype t_alucode is std_logic_vector(3 downto 0);
    
    constant ALU_NOTA       : t_alucode := x"0";
    constant ALU_NOTB       : t_alucode := x"1";
    constant ALU_AANDB      : t_alucode := x"2";
    constant ALU_AORB       : t_alucode := x"3";
    constant ALU_AXORB      : t_alucode := x"4";
    constant ALU_ROLA       : t_alucode := x"5";
    constant ALU_RORA       : t_alucode := x"6";
    constant ALU_INCA       : t_alucode := x"7";
    constant ALU_INCB       : t_alucode := x"8";
    constant ALU_DECA       : t_alucode := x"9";
    constant ALU_DECB       : t_alucode := x"A";
    constant ALU_APLUSB     : t_alucode := x"B";
    constant ALU_AMINUSB    : t_alucode := x"C";
    constant ALU_ONES       : t_alucode := x"D";

end package sap2_pkg;
