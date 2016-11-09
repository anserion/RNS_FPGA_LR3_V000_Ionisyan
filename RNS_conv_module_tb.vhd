LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.RNS_defs_pkg.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
 
ENTITY RNS_conv_module_tb IS
END RNS_conv_module_tb;
 
ARCHITECTURE behavior OF RNS_conv_module_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT PSS_RNS_module
    Port (clock: std_logic; A: in T_bin_data; result: out T_RNS_vector);
    END COMPONENT;
    
   component RNS_PSS_module
   Port (clock: std_logic; A: in T_RNS_vector; result: out T_bin_data);
   end component;

   component RNS_OPSS_module is
      Port (clock: std_logic; A: in T_RNS_vector; result: out T_RNS_vector);
   end component;

   component OPSS_RNS_module is
      Port (clock: std_logic; A: in T_RNS_vector; result: out T_RNS_vector);
   end component;

   component OPSS_PSS_module is
   Port (clock: std_logic; A: in T_RNS_vector; result: out T_bin_data);
   end component;

   --Inputs
   signal clock : std_logic := '0';
   signal A : T_bin_data := (others => '0');

 	--Outputs
   signal result_RNS,result_OPSS,result_OPSS_RNS : T_RNS_vector;
   signal result_OPSS_PSS, result_PSS: T_bin_data;

   -- Clock period definitions
   constant clock_period : time := 100 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut_PSS_RNS: PSS_RNS_module PORT MAP (clock => clock, A => A, result => result_RNS);
   uut_RNS_PSS: RNS_PSS_module PORT MAP (clock => clock, A => result_RNS, result => result_PSS);
   uut_RNS_OPSS: RNS_OPSS_module PORT MAP (clock => clock, A => result_RNS, result => result_OPSS);
   uut_OPSS_RNS: OPSS_RNS_module PORT MAP (clock => clock, A => result_OPSS, result => result_OPSS_RNS);
   uut_OPSS_PSS: OPSS_PSS_module PORT MAP (clock => clock, A => result_OPSS, result => result_OPSS_PSS);

   -- Clock process definitions
   clock_process :process
   begin
		clock <= '1';
		wait for clock_period/2;
		clock <= '0';
		wait for clock_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for (clock_period*9)/10;	

      -- insert stimulus here 
      A<=A+1;

      wait for clock_period/10;
   end process;

END;
