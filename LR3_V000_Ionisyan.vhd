----------------------------------------------------------------------------------
-- Company: SKFU, 4PMI
-- Engineer: prepod, Ionisyan A.S.
-- Project Name: LR3_var(000)
-- formula: c=(a+b)^3-7a+b
-- a,b,c - 32bit BSS numbers
-- RNS primes is (173,229,181,233,239)
----------------------------------------------------------------------------------
library IEEE;
USE ieee.std_logic_1164.ALL;
USE work.RNS_defs_pkg.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity LR3_V000_Ionisyan is
    Port ( a : in  T_bin_data;
           b : in  T_bin_data;
           c : out  T_bin_data;
           clk : in  std_logic);
end LR3_V000_Ionisyan;

architecture Behavioral of LR3_V000_Ionisyan is
   COMPONENT PSS_RNS_module
    Port (clock: std_logic; A: in T_bin_data; result: out T_RNS_vector);
    END COMPONENT;
    
   component RNS_PSS_module
   Port (clock: std_logic; A: in T_RNS_vector; result: out T_bin_data);
   end component;

   component RNS_ALU_neg is
      Port (clock: std_logic; A: in T_RNS_vector; result: out T_RNS_vector);
   end component;

   component RNS_ALU_inv is
      Port (clock: std_logic; A: in T_RNS_vector; result: out T_RNS_vector);
   end component;

   component RNS_ALU_add is
      Port (clock: std_logic; op1, op2: in T_RNS_vector; result: out T_RNS_vector);
   end component;

   component RNS_ALU_mul is
      Port (clock: std_logic; op1, op2: in T_RNS_vector; result: out T_RNS_vector);
   end component;

   component RNS_ALU_cmp_equ
      Port (clock: std_logic; op1, op2: in T_RNS_vector; result: out STD_LOGIC);
   end component;

   component RNS_ALU_cmp_g
      Port (clock: std_logic; op1, op2: in T_RNS_vector; result: out STD_LOGIC);
   end component;
      
   signal a_RNS,b_RNS,c_RNS:T_RNS_vector;
   signal a_plus_b,a_plus_b_pow2,a_plus_b_pow3: T_RNS_vector;
   signal apbp3_minus_am7,neg_a_mul_7,a_mul_7,seven_RNS:T_RNS_vector;
   signal seven:T_bin_data;
   
begin

--c=(a+b)^3-7a+b
--0) a_RNS=PSS_to_SOK(a); b_RNS=PSS_to_SOK(b)
a_to_aRNS_chip: PSS_RNS_module port map(clk,a,a_RNS);
b_to_bRNS_chip: PSS_RNS_module port map(clk,b,b_RNS);
--1) a_plus_b=a_RNS+b_RNS
a_plus_b_chip: RNS_ALU_add port map(clk,a_RNS,b_RNS,a_plus_b);
--2) a_plus_b_pow2=a_plus_b*a_plus_b
a_plus_b_pow2_chip: RNS_ALU_mul port map(clk,a_plus_b,a_plus_b,a_plus_b_pow2);
--3) a_plus_b_pow3=a_plus_b*a_plus_b_pow2
a_plus_b_pow3_chip: RNS_ALU_mul port map(clk,a_plus_b_pow2,a_plus_b,a_plus_b_pow3);
--4) a_mul_7=a_RNS*7
seven<="00000000000000000000000000000111";
seven_to_RNS_chip: PSS_RNS_module port map(clk,seven,seven_RNS);
a_mul_7_chip: RNS_ALU_mul port map(clk,a_RNS,seven_RNS,a_mul_7);
--5) apbp3_minus_am7=a_plus_b_pow3-a_mul_7
neg_apbp3_minus_am7_chip: RNS_ALU_neg port map(clk,a_mul_7,neg_a_mul_7);
apbp3_minus_am7_chip: RNS_ALU_add port map(clk,a_plus_b_pow3,neg_a_mul_7,apbp3_minus_am7);
--6) c_RNS=apbp3_minus_am7+b
cRNS_chip: RNS_ALU_add port map(clk,apbp3_minus_am7,b_RNS,c_RNS);
--7) c=RNS_to_PSS(c_RNS);
cRNS_to_c_chip: RNS_PSS_module port map(clk,c_RNS,c);
end Behavioral;
