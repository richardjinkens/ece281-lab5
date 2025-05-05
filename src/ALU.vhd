----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    
    component ripple_adder
        Port (
            A       : in std_logic_vector(3 downto 0);
            B       : in std_logic_vector(3 downto 0);
            Cin     : in std_logic;
            S       : out std_logic_vector(3 downto 0);
            Cout    : out std_logic
        );
    end component;
    
    
    signal w_A1, w_B1, w_A2, w_B2, w_S1, w_S2 : std_logic_vector(3 downto 0);
    signal w_Cin1, w_Cin2, w_Cout1, w_Cout2 : std_logic;

    signal w_A      : std_logic_vector(7 downto 0);
    signal w_B      : std_logic_vector(7 downto 0);
    signal w_B_inv  : std_logic_vector(7 downto 0);
    
    signal w_ALU_op : std_logic_vector(2 downto 0);
    signal w_SUM    : std_logic;
    signal w_FLAG   : std_logic_vector(3 downto 0);
    
    signal w_ripple_result : std_logic_vector(7 downto 0);
    
    signal w_RESULT : std_logic_vector(7 downto 0);
    
    
    --signals to help flags
    signal w_overflow1  : std_logic;
    signal w_overflow2  : std_logic;
    signal w_OVERFLOW   : std_logic;
    
    signal w_CARRY      : std_logic;
    signal w_NEGATIVE   : std_logic;
    signal w_ZERO       : std_logic;
    
    --signals for first mux
    signal w_MUX_out    : std_logic_vector(7 downto 0);
    
    --signals for second larger mux
    signal w_MUX_in1           : std_logic_vector(7 downto 0);
    signal w_MUX_in2           : std_logic_vector(7 downto 0);
    signal w_MUX_in3           : std_logic_vector(7 downto 0);
    signal w_MUX_in4           : std_logic_vector(7 downto 0);
    
    
    
begin
    adder_low: ripple_adder
        port map(
            A      => w_A(3 downto 0),
            B      => w_B_inv(3 downto 0),
            Cin    => w_ALU_op(0),
            S      => w_ripple_result(3 downto 0),
            Cout   => w_Cin2
            
        );
    adder_high: ripple_adder
        port map(
            A      => w_A(7 downto 4),
            B      => w_B_inv(7 downto 4),
            Cin    => w_Cin2,
            S      => w_ripple_result(7 downto 4),
            Cout   => w_Cout2
            
        );
--signal declartions 
        w_A <= i_A;
        w_B <= i_B;
        w_B_inv <= w_MUX_out;
        o_result <= w_RESULT;
        w_ALU_op <= i_op;
        w_SUM <= w_ripple_result(7);
        
--right side of figure 5.17
    --this inverts B or not
    w_MUX_out <= not w_B when w_ALU_op(0) = '1' else w_B;
    
    
    --larger mux in the figure
    w_MUX_in4 <= w_A OR w_B;
    w_MUX_in3 <= w_A AND w_B;
    w_MUX_in2 <= w_ripple_result;
    w_MUX_in1 <= w_ripple_result;
    
    with w_ALU_op(1 downto 0) select
        w_RESULT <= w_MUX_in4 when "11",
                    w_MUX_in3 when "10",
                    w_MUX_in2 when "01",
                    w_MUX_in1 when others;
    
--THIS IS ALL THE FLAGS
    -- overflow
    w_SUM <= w_ripple_result(7);
    w_overflow1 <= w_ALU_op(0) XOR w_A(7) XOR w_B(7);
    w_overflow2 <= w_A(7) XOR w_SUM;
    w_OVERFLOW  <= w_overflow1 AND w_overflow2 AND (not w_ALU_op(1));
    
    -- carry
    w_CARRY <= w_Cout2 AND (not w_ALU_op(1));
    
    -- negative
    w_NEGATIVE <= w_RESULT(7);
    
    -- zero
    w_ZERO <= '1' when w_RESULT = x"00" else '0';
    
    --combining all the flags
    o_flags(3) <= w_NEGATIVE;
    o_flags(2) <= w_ZERO;
    o_flags(1) <= w_CARRY;
    o_flags(0) <= w_OVERFLOW;

end Behavioral;
