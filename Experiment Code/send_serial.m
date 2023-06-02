function send_serial(string_to_send)

% this is a function for sending serial port info from matlab. 
% it is written as an alternative to mex_serial
% written in a hurry by MBR, should be modifed to include error checking,
% etc., but seems to work as is, and has not crashed or hung. 

s = serial('COM5', 'BaudRate',19200);
fopen(s);
% fid = fopen('com4:', 'w');
%updated from com 1 to com3 for USB to serial, JLF 4/16/13
fwrite(s, string_to_send, 'uchar');
fclose(s);
delete(s);
