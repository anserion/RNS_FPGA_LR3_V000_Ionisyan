----------------------------------------------------------------------------------
-- Company: SKFU, 4PMI
-- Engineer: prepod, Ionisyan A.S.
-- Project Name: LR3_var(000) testbench
-- formula: c=(a+b)^3-7a+b
-- a,b,c - 32bit BSS numbers
-- RNS primes is (173,229,181,233,239)
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.RNS_defs_pkg.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
 
ENTITY tb_LR3_V000_Ionisyan IS
END tb_LR3_V000_Ionisyan;
 
ARCHITECTURE behavior OF tb_LR3_V000_Ionisyan IS 
 
component LR3_V000_Ionisyan is
    Port ( a : in  T_bin_data;
           b : in  T_bin_data;
           c : out  T_bin_data;
           clk : in  std_logic);
end component;
    

   --Inputs
   signal clock : std_logic := '0';
   signal a,b : T_bin_data := (others => '0');
 	--Outputs
   signal c : T_bin_data := (others => '0');
   -- Clock period definitions
   constant clock_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   LR3_v000_Ionisyan_chip: LR3_V000_Ionisyan PORT MAP (a,b,c,clock);

   -- Clock process definitions
   clk_process :process
   begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
      wait for (clock_period*9)/10;	
      A<="00000000000000000000000000000110";
      B<="00000000000000000000000000000011";
      wait for clock_period/10;
   end process;
END;
