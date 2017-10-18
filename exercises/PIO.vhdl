library ieee;
use ieee.std_logic_1164.all;

entity simplePIO is
  port(
-- Avalon interfaces signals
    Clk_CI       : in    std_logic;
    Reset_RLI    : in    std_logic;
    Address_DI   : in    std_logic_vector(2 downto 0);
    Read_SI      : in    std_logic;
    ReadData_DO  : out   std_logic_vector(7 downto 0);
    Write_SI     : in    std_logic;
    WriteData_DI : in    std_logic_vector(7 downto 0);
-- Parallel Port external interface
    ParPort_DIO  : inout std_logic_vector(7 downto 0));
end entity simplePIO;




architecture NoWait of simplePIO is
  signal RegDir_D  : std_logic_vector (7 downto 0);
  signal RegPort_D : std_logic_vector (7 downto 0);
  signal RegPin_D  : std_logic_vector (7 downto 0);
begin  -- architecture NoWait



  pRegWr : process(Clk_CI, Reset_RLI)
  begin
    if Reset_RLI = '0' then
      -- Input by default
      RegDir_D <= (others => '0');
      RegPort_D <= (others => '0');
    elsif rising_edge(Clk_CI) then
      if Write_SI = '1' then
        -- Write cycle
        case Address_DI(2 downto 0) is
          when "000" =>
            RegDir_D <= WriteData_DI;
          when "010" =>
            RegPort_D <= WriteData_DI;
          when "011" =>
            RegPort_D <= RegPort_D or WriteData_DI;
          when "100" =>
            RegPort_D <= RegPort_D and not WriteData_DI;
          when others => null;
        end case;
      end if;
    end if;
  end process pRegWr;



  -- Selected Signal Assignment Statement
  -- shorthand for a process containing a number of
  -- ordinary signal assignments within a case statement
  
  -- Read from registers with wait 0
  with Address_DI select
    ReadData_DO <=
    RegDir_D        when "000",
    RegPin_D        when "001",
    RegPort_D       when "010",
    (others => '0') when others;



  -- Parallel port output value
  pPort : process(RegDir_D, RegPort_D)
  begin
    for idx in 0 to 7 loop
      if RegDir_D(idx) = '1' then
        ParPort_DIO(idx) <= RegPort_D(idx);
      else
        ParPort_DIO(idx) <= 'Z';
      end if;
    end loop;
  end process pPort;

  -- signal assignment outside a process
  -- Parallel port input value
  RegPin_D <= ParPort_DIO;

end architecture NoWait;
