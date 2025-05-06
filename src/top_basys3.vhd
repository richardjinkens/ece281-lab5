--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
    component controller_fsm is 
        Port(
            i_reset : in std_logic;
            i_adv   : in std_logic;
            o_cycle : out std_logic_vector(3 downto 0)
            );
    end component;
    
    component clock_divider is
    generic (constant k_DIV : natural := 2);
        Port(
            i_clk   : in std_logic;
            i_reset : in std_logic;
            o_clk   : out std_logic 
            );
    end component;
    
    component ALU is 
        Port(
            i_A         : in std_logic_vector(7 downto 0);
            i_B         : in std_logic_vector(7 downto 0);
            i_op        : in std_logic_vector(2 downto 0);
            o_result    : out std_logic_vector(7 downto 0);
            o_flags     : out std_logic_vector(3 downto 0)
            );
    end component;
    
    component TDM4 is
    generic (constant k_WIDTH : natural := 4);
        Port(
            i_clk           : in std_logic;
            i_reset         : in std_logic;
            i_D3            : in std_logic_vector(k_WIDTH - 1 downto 0);
            i_D2            : in std_logic_vector(k_WIDTH - 1 downto 0);
            i_D1            : in std_logic_vector(k_WIDTH - 1 downto 0);
            i_D0            : in std_logic_vector(k_WIDTH - 1 downto 0);
            o_data          : out std_logic_vector(k_WIDTH - 1 downto 0);
            o_sel           : out std_logic_vector(3 downto 0)
       );
    end component;
    
    component sevenseg_decoder is 
        Port(
            i_Hex       : in std_logic_vector(3 downto 0);
            o_seg_n     : out std_logic_vector(6 downto 0)
        );
    end component;
    
    component twos_comp is 
        Port(
            i_bin       : in std_logic_vector(7 downto 0);
            o_sign      : out std_logic;
            o_hund      : out std_logic_vector(3 downto 0);
            o_tens      : out std_logic_vector(3 downto 0);
            o_ones      : out std_logic_vector(3 downto 0)
        );
    end component;
    
    signal f_A          : std_logic_vector(7 downto 0);
    signal f_B          : std_logic_vector(7 downto 0);
    signal w_RESULT     : std_logic_vector(7 downto 0);
    signal w_M_numbers  : std_logic_vector(7 downto 0);
    
    signal w_seg        : std_logic_vector(6 downto 0);
    
    signal w_cycle      : std_logic_vector(3 downto 0);
    signal w_FLAGS      : std_logic_vector(3 downto 0);
    signal w_D2         : std_logic_vector(3 downto 0);
    signal w_D1         : std_logic_vector(3 downto 0);
    signal w_D0         : std_logic_vector(3 downto 0);
    signal w_sel        : std_logic_vector(3 downto 0);
    signal w_data       : std_logic_vector(3 downto 0);
    signal w_an         : std_logic_vector(3 downto 0);
    
    signal w_reset      : std_logic;
    signal w_D3         : std_logic;
    signal w_clk        : std_logic;
    
    
        
begin
	-- PORT MAPS ----------------------------------------
    c_lockdivider : clock_divider
        generic map( k_DIV => 200000 )
        Port map(
            i_clk   => clk,
            i_reset => w_reset,
            o_clk   => w_clk
        );
        
    c_ontrollerfsm : controller_fsm
        Port map(
            i_reset => w_reset,
            i_adv   => btnC,
            o_cycle => w_cycle
        );
	
	A_LU : ALU
	   Port map(
	       i_A         => f_A,
	       i_B         => f_B,
	       i_op        => sw(2 downto 0),
	       o_result   => w_RESULT,
	       o_flags     => w_FLAGS
	   );
	   
	T_DM4 : TDM4
	   generic map( k_WIDTH => 4 )
	   Port map(
	       i_clk   => w_clk,
	       i_reset => w_reset,
	       i_D3    => x"0",
	       i_D2    => w_D2,
	       i_D1    => w_D1,
	       i_D0    => w_D0,
	       o_data  => w_data,
	       o_sel   => w_sel
	   );
	   
    s_evensegdecoder : sevenseg_decoder
        Port map(
            i_Hex   => w_data,
            o_seg_n => w_seg
        );
   
    t_woscomp : twos_comp
        Port map(
            i_bin       => w_M_numbers(7 downto 0),
            o_sign      => w_D3,
            o_hund      => w_D2,
            o_tens      => w_D1,
            o_ones      => w_D0
        );
	       
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	-- leds
	led(3 downto 0)   <= w_cycle(3 downto 0);
	led(15 downto 12) <= w_flags(3 downto 0);
	
	-- reset button
	w_reset <= btnU;
	
	--this is the op code from the fsm
	with w_cycle select
	   w_M_numbers <=  f_A         when "0010",
	                   f_B         when "0100",
	                   w_RESULT    when "1000",
	                   "00000000"  when others;
	  
	--this is the annode on or off  
	with w_cycle select
	   an <= "1111"        when "0001",
	         w_sel         when others;
	 
	-- this selects the negative sign         
	seg <= "1111111"   when (w_M_numbers(7) = '0' and w_sel(3) = '0') else
	       "0111111"   when (w_M_numbers(7) = '1' and w_sel(3) = '0') else
	       w_seg;
	  
    --first register
    register1_process : process(w_clk)
        begin
            if rising_edge(w_clk) then
                if w_reset = '1' then
                    f_A <= (others => '0');
                elsif w_cycle = "0010" then 
                    f_A <= sw;
                end if;
            end if;
        end process register1_process;
    
    --second register
    register2_process : process(w_clk)
        begin
            if rising_edge(w_clk) then
                if w_reset = '1' then
                    f_B <= (others => '0');
                    elsif w_cycle = "0010" then
                        f_B <= sw;
                    end if;
                end if;
        end process register2_process;     
	     
	
end top_basys3_arch;
