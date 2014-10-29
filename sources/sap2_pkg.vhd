-- DESCRIPTION: SAP-2 - PKG
-- AUTHOR: Jonathan Primeau

library ieee;
use ieee.std_logic_1164.all;

package sap2_pkg is

    subtype t_wire is std_logic;
    subtype t_bus is std_logic_vector(15 downto 0);
    subtype t_address is std_logic_vector(15 downto 0);
    subtype t_data is std_logic_vector(7 downto 0);
    subtype t_opcode is std_logic_vector(7 downto 0);
    subtype t_control is std_logic_vector(21 downto 0);
    subtype t_alucode is std_logic_vector(3 downto 0);

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
    constant EmdrH  : integer := 06;
    constant Wr     : integer := 07;
    constant Li     : integer := 08;
    constant La     : integer := 09;
    constant Ea     : integer := 10;
    constant Lt     : integer := 11;
    constant Et     : integer := 12;
    constant Lb     : integer := 13;
    constant Eb     : integer := 14;
    constant Lc     : integer := 15;
    constant Ec     : integer := 16;
    constant Eu     : integer := 17;
    constant Lu     : integer := 18;
    constant Lo     : integer := 19;
    constant Lsz    : integer := 20;
    constant HALT   : integer := 21;

    type t_cpu_state is (
        reset_state, address_state, increment_state, memory_state, decode_instruction,
        add_1, add_2, ana_1,ana_2, ani_1, ani_2, ani_3,
        call_1, call_2, call_3, call_4, call_5, call_6,
        dcra_1, dcra_2, dcrb_1, dcrb_2, dcrc_1, dcrc_2,
        inrb_1, inrc_1, jm_1, jm_2, jm_3, jm_4, jmp_1, jmp_2, jmp_3, jmp_4,
        jnz_1, jnz_2, jnz_3, jnz_4, jz_1, jz_2, jz_3, jz_4,
        lda_1, lda_2, lda_3, lda_4, lda_5, lda_6,
        mvia_1, mvia_2, mvib_1, mvib_2, mvic_1, mvic_2,
        ora_1, ori_1, ori_2, ori_3,
        ret_1, ret_2, sta_1, sta_2, sta_3, sta_4, sta_5, sta_6, sub_1,
        xra_1, xri_1, xri_2, xri_3
    );
    
    constant ALU_NOT        : t_alucode := x"0";
    constant ALU_AND        : t_alucode := x"1";
    constant ALU_OR         : t_alucode := x"2";
    constant ALU_XOR        : t_alucode := x"3";
    constant ALU_ROL        : t_alucode := x"4";
    constant ALU_ROR        : t_alucode := x"5";
    constant ALU_INC        : t_alucode := x"6";
    constant ALU_DEC        : t_alucode := x"7";
    constant ALU_ADD        : t_alucode := x"8";
    constant ALU_SUB        : t_alucode := x"9";
    constant ALU_ONES       : t_alucode := x"A";

end package sap2_pkg;
