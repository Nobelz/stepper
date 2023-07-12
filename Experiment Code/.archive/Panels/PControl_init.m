function PC = PControl_init()
%PControl_init
%PControl initializer script

PC.x_gain_max = 10;
PC.x_gain_min = -10;
PC.x_gain_val = 0;

PC.y_gain_max = 10;
PC.y_gain_min = -10;
PC.y_gain_val = 0;

PC.x_offset_max = 5;
PC.x_offset_min = -5;
PC.x_offset_val = 0;

PC.y_offset_max = 5;
PC.y_offset_min = -5;
PC.y_offset_val = 0;

PC.x_pos = 1;
PC.y_pos = 1;


PC.x_mode = 0;  % default is open loop
PC.y_mode = 0;

PC.current_pattern = 0; % use this as the init value to check if real pattern is set

% load the CF file - 
panel_control_paths;
load([controller_path '\CF'])
PC.num_patterns = CF.num_patterns;
for j = 1:CF.num_patterns
     PC.pattern_x_size(j) = CF.x_num(j); 
     PC.pattern_y_size(j) = CF.y_num(j); 
end

% put this in here to set up serial communication for send_serial command
!mode com8:19200,n,8,1
%Changed "com1" to "com3" for USB-to-serial connector. JLF 4/16/13.
