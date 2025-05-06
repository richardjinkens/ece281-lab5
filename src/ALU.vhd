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
    
    signal w_ripple_carry : std_logic_vector(1 downto 0);

    signal w_B_inv  : std_logic_vector(7 downto 0);
    
    signal w_ripple_result : std_logic_vector(7 downto 0);
    
    signal w_RESULT : std_logic_vector(7 downto 0);
    
    
    --signals to help flags
    signal w_overflow1  : std_logic;
    signal w_overflow2  : std_logic;
    signal w_OVERFLOW   : std_logic;
    
    signal w_CARRY      : std_logic;
    signal w_NEGATIVE   : std_logic;
    signal w_ZERO       : std_logic;
    
    
    
    
begin
    adder_low: ripple_adder
        port map(
            A      => i_A(3 downto 0),
            B      => w_B_inv(3 downto 0),
            Cin    => i_op(0),
            S      => w_ripple_result(3 downto 0),
            Cout   => w_ripple_carry(0)
            
        );
    adder_high: ripple_adder
        port map(
            A      => i_A(7 downto 4),
            B      => w_B_inv(7 downto 4),
            Cin    => w_ripple_carry(0),
            S      => w_ripple_result(7 downto 4),
            Cout   => w_ripple_carry(1)
            
        );
        
        
--right side of figure 5.17
    --this inverts B or not
    with i_op(0) select 
        w_B_inv <= i_B      when '0',
                   not i_B  when '1',
                   i_B      when others;
    
    
    --larger mux in the figure
    with i_op select
        w_RESULT <= w_ripple_result when "000",
                    w_ripple_result when "001",
                    i_A AND i_B     when "010",
                    i_A OR i_B      when "011",
                    "00000000"      when others;              
    
    
                    
    
--THIS IS ALL THE FLAGS
    -- overflow
    w_overflow1 <= i_op(0) XOR i_A(7) XOR i_B(7);
    w_overflow2 <= i_A(7) XOR w_ripple_result(7);
    w_OVERFLOW <= w_overflow1 AND w_overflow2 AND (not i_op(1));
    
    -- carry
    w_CARRY <= (not i_op(1)) AND w_ripple_carry(1);
    
    -- negative
    w_NEGATIVE <= w_RESULT(7);
    
    -- zero
    w_ZERO <= not (w_result(7) OR w_result(6) OR w_result(5) OR w_result (4) OR w_result(3) OR w_result(2) OR w_result(1) OR w_result(0));
    
    --combining all the flags
    o_flags(3) <= w_NEGATIVE;
    o_flags(2) <= w_ZERO;
    o_flags(1) <= w_CARRY;
    o_flags(0) <= w_OVERFLOW;

end Behavioral;
