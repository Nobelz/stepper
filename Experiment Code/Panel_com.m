function Panel_com(command, argument)

%   Sends commands out to the panels
%  ARGUMENTS MUST BE ROW VECTORS
% Acceptable panel commands are:

switch lower(command)

 % one byte commands:
  case 'start'
        %	Start display: panel_addr, 0x20	-panel address not used
        send_serial( char([1 32]));  
  case 'stop'
        %	Stop display: panel_addr, 0x30         
        send_serial( char([1 48]));  
  
  case 'start_w_trig'
        %	Start display w trigger: 0x25	
        send_serial( char([1 37]));  
  
  case 'stop_w_trig'
        %	Stop display w trigger: 0x35         
        send_serial( char([1 53]));  
  
  case 'clear'      % clear the flash
        send_serial( char([1 hex2dec('F0')]));
        
  case 'all_off'      % set all panels to 0;
        send_serial( char([1 hex2dec('00')]));        
  
  case 'all_on'      % set all panels to 0;
        send_serial( char([1 hex2dec('FF')]));    
  
  case  'g_level_0' % set all panels to grey level 0;
        send_serial( char([1 hex2dec('40')]));    
      
  case  'g_level_1' % set all panels to grey level 1;
        send_serial( char([1 hex2dec('41')]));    

  case  'g_level_2' % set all panels to grey level 2;
        send_serial( char([1 hex2dec('42')]));    

  case  'g_level_3' % set all panels to grey level 3;
        send_serial( char([1 hex2dec('43')]));    
        
  case  'g_level_4' % set all panels to grey level 4;
        send_serial( char([1 hex2dec('44')]));    

  case  'g_level_5' % set all panels to grey level 5;
        send_serial( char([1 hex2dec('45')]));    

  case  'g_level_6' % set all panels to grey level 6;
        send_serial( char([1 hex2dec('46')]));    

  case  'g_level_7' % set all panels to grey level 7;
        send_serial( char([1 hex2dec('47')]));    
        
  case  'led_tog' % toggles controller LED
        send_serial( char([1 hex2dec('50')]));    
        
  case  'ctr_reset' % resets the controller
        send_serial( char([1 hex2dec('60')]));

  case  'bench_pattern' % run a benchmark on current pattern     
        send_serial( char([1 hex2dec('70')]));
        
  case  'laser_on' % enable laser trigger
        send_serial( char([1 hex2dec('10')]));
  
  case  'laser_off' % enable laser trigger
        send_serial( char([1 hex2dec('11')]));
        
  case  'ident_compress_on' % enable compression for identical panel patches
        send_serial( char([1 hex2dec('12')]));
        		
  case  'ident_compress_off' % disable compression for identical panel patches
        send_serial( char([1 hex2dec('13')]));
        
% two byte commands:
  case 'reset'
        if (~isequal(length(argument),1)||(~isnumeric(argument)))
            error('reset command requires 1 argument that is a number');
        end
        %	Board reset : 0x01, panel_addr
        send_serial( char([2 1 argument(1)]));      
        
  case 'display'
        if (~isequal(length(argument),1)||(~isnumeric(argument)))
            error('display command requires 1 argument that is a number');
        end
        %	Display id:    0x02, panel_addr
        send_serial( char([2 2 argument(1)]));      

  case 'set_pattern_id'
        if ((~isequal(length(argument),1))||(~isnumeric(argument))||(argument(1) >99)||(argument(1) <= 0))
            error('Pattern ID command requires 1 numerical argument that is between 1 and 99');
        end
        % panel ID:  0x03, Panel_ID
        send_serial( char([2 3 argument(1)]));    
        
  case 'adc_test'
        if (~isequal(length(argument),1)||(~isnumeric(argument))||(argument(1) >7)||(argument(1) < 0))
            error('ADC_test requires 1 argument that is a number between 0 and 7');
        end
        %	test ADC on controller board for certain chanel. send 0x04, channel addr (0 - 7)
        send_serial( char([2 4 argument(1)]));      

  case 'dio_test'
        if (~isequal(length(argument),1)||(~isnumeric(argument))||(argument(1) >7)||(argument(1) < 0))
            error('DIO_test requires 1 argument that is a number between 0 and 7');
        end
        %	test DIO on controller board for certain chanel. send 0x05, channel addr (0 - 7)
        send_serial( char([2 5 argument(1)]));
  
  case 'set_trigger_rate'
        if (~isequal(length(argument),1)||(~isnumeric(argument))||(argument(1) > 255)||(argument(1) < 0))
            error('trigger setting requires 1 argument that is a number between 0 and 255');
        end
        %	set the trigger rate on the controller; send 0x06 and value
        %	0-255 (multiplied by 2 on the controller).
        send_serial(char([2 6 argument(1)]));
        
% three byte commands:
  
  case 'set_mode'
        if ((~isequal(length(argument),2))||(~isnumeric(argument))||any(argument > 5)||any(argument(1) < 0))
            error('Loop mode command requires 2 numerical argument, 0,1,2,3, or 4 for both X, and Y');
        end
        send_serial( char([3  hex2dec('10') argument(1) argument(2)]));

  case 'address'
        if (~isequal(length(argument),2)||(~isnumeric(argument)))
            error('update address command requires 2 numerical arguments');
        end
        % update address: 0xFF; current address, new address
        send_serial( char([3 255 argument(1) argument(2)]));      
  
% five byte commands:        
  case 'set_position'
        % 5 bytes to set pattern position: 0x70, then 2 bytes for x index, y index
        if (~isequal(length(argument),2)||(~isnumeric(argument)))
            error('position setting command requires 2 numerical arguments');
        end
        %subtract -1 from each argument  
        % beacause in matlab use 1 as start index, and controller uses 0
        send_serial([5 hex2dec('70') dec2char(argument(1)-1,2) dec2char(argument(2)-1,2)]);          
  case 'send_gain_bias'
        % 5 bytes to set gain and bias values: 0x80, then 1 byte each for gain_x, bias_x, gain_y, bias_y
        if (~isequal(length(argument),4)||(~isnumeric(argument)))
            error('gain & bias setting command requires 4 numerical arguments');
        end
        %Note: these are all signed arguments, so we need to convert to 2's complement if necessary  
        send_serial( [5 hex2dec('71') signed_byte_to_char(argument)]);          
        
% six byte        
  case 'send_filter_coeff'
        % 6 bytes to set gain and bias values: 0x90, then 1 byte (signed)for Cp, the 2 bytes 
        % (unsigned) for Jp*(2/h) then 1 byte each for gain_y, bias_y
        if (~isequal(length(argument),4)||(~isnumeric(argument)))
            error('filter coeff setting command requires 4 numerical arguments');
        end
        %Note: these are all signed arguments, so we need to convert to 2's complement if necessary  
        send_serial( char([5 hex2dec('90') signed_byte_to_char(argument(1)) signed_byte_to_char(argument(2)) ...
                signed_byte_to_char(argument(3)) signed_byte_to_char(argument(4))  ]));                  

% even longer commands:
case 'send_function'
    % 52 bytes - byte 1 is identifier, 1 for X, 2 for Y, 2nd byte is
    % the function segment number (these are 50 byte length segments),
    % starting at zero.
    % then 50 bytes of data
    if (~isequal(length(argument),52)||(~isnumeric(argument)))
            error('flash scrolling requires 52 numerical arguments');
    end
    send_serial( ([52 argument(1) argument(2) signed_byte_to_char(argument(3:end))]));        
    
        
 otherwise
    error('invalid command name, please check help')
end