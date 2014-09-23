-- DESCRIPTION: SAP-2 - ALU
-- AUTHOR: Jonathan Primeau

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sap2_pkg.all;

entity sap2_alu is
    port (
        a           : in t_data;
        b           : in t_data;
        cin         : in std_logic;
        code        : in std_logic_vector(3 downto 0);
        
        result      : out t_data;
        cout        : out std_logic
    );
end sap2_alu;

architecture ALU74181 of sap2_alu is
    signal tmp_a        : t_data;
    signal tmp_b        : t_data;
    signal tmp_cin      : std_logic;

    procedure full_adder(
        signal a    : in t_data;
        signal b    : in t_data;
        signal cin  : in std_logic;
        signal q    : out t_data;
        signal cout : out std_logic
    ) is
        variable c1, c2, c3, c4, c5, c6, c7 : std_logic;
    begin
        c1 := (a(0) and b(0)) or (a(0) and cin) or (b(0) and cin);
        c2 := (a(1) and b(1)) or (a(1) and c1) or (b(1) and c1);
        c3 := (a(2) and b(2)) or (a(2) and c2) or (b(2) and c2);
        c4 := (a(3) and b(3)) or (a(3) and c3) or (b(3) and c3);
        c5 := (a(4) and b(4)) or (a(4) and c4) or (b(4) and c4);
        c6 := (a(5) and b(5)) or (a(5) and c5) or (b(5) and c5);
        c7 := (a(6) and b(6)) or (a(6) and c6) or (b(6) and c6);
        cout <= (a(7) and b(7)) or (a(7) and c7) or (b(7) and c7);
        q(0) <= a(0) xor b(0) xor cin;
        q(1) <= a(1) xor b(1) xor c1;
        q(2) <= a(2) xor b(2) xor c2;
        q(3) <= a(3) xor b(3) xor c3;
        q(4) <= a(4) xor b(4) xor c4;
        q(5) <= a(5) xor b(5) xor c5;
        q(6) <= a(6) xor b(6) xor c6;
        q(7) <= a(7) xor b(7) xor c7;
    end full_adder;
   
begin
    process(code)
    begin
        case code is
        
        -- Logic operations
        when ALU_NOTA =>
            result <= not a;
        when ALU_NOTB =>
            result <= not b;
        when ALU_AANDB =>
            result <= a and b;
        when ALU_AORB =>
            result <= a or b;
        when ALU_AXORB =>
            result <= a xor b;
        when ALU_ROLA =>
            result <= to_stdlogicvector(to_bitvector(a) rol 1);
        when ALU_RORA =>
            result <= to_stdlogicvector(to_bitvector(a) ror 1);
            
        when ALU_ONES =>
            result <= (others => '1');

        -- Arithmetic operations
        when ALU_INCA =>
            tmp_a <= a;
            tmp_b <= (others=>'0');
            tmp_cin <= '1';
            full_adder(tmp_a, tmp_b, tmp_cin, result, cout);
        when ALU_INCB =>
            tmp_a <= (others=>'0');
            tmp_b <= b;
            tmp_cin <= '1';
            full_adder(tmp_a, tmp_b, tmp_cin, result, cout);
        when ALU_DECA =>
            tmp_a <= a;
            tmp_b <= (others=>'1');
            tmp_cin <= '0';
            full_adder(tmp_a, tmp_b, tmp_cin, result, cout);
        when ALU_DECB =>
            tmp_a <= (others=>'1');
            tmp_b <= b;
            tmp_cin <= '0';
            full_adder(tmp_a, tmp_b, tmp_cin, result, cout);
        when ALU_APLUSB =>
            tmp_a <= a;
            tmp_b <= b;
            tmp_cin <= cin;
            full_adder(tmp_a, tmp_b, tmp_cin, result, cout);
        when ALU_AMINUSB =>
            tmp_a <= a;
            tmp_b <= not b;
            tmp_cin <= '1';
            full_adder(tmp_a, tmp_b, tmp_cin, result, cout);
            
        when others => null;
        end case;

    end process;
end ALU74181;