function stepper_com(port, command, argument)
% Stepper_com.m
% Communicates with the stepper via a serial port.
%
% Inputs:
%   - port: the serialport object of the stepper
%   - command: the command
%   - argument: the argument of the command, if there is one
%
% Author: Mike Rauscher and Nobel Zhou
% Date: 16 June 2023
% Version: 1.1
%
% VERSION CHANGELOG:
% - v1.0 (??/??/????): Initial commit
% - v2.2 (6/16/2023): Added comments, added voltage functionality

    % Coder's note: the below code was used before switching to the new
    % serialport. Now, only one serialport object is created at a time, so
    % defining the port here is no longer useful. - nxz157, 6/16/2023

%     % use default com port if none specified [change to match computer]
%     DEFAULT_COM = 'COM3';
%     if nargin<3
%         port = DEFAULT_COM;
%     end
        
    % set command to lowercase to make input case-insensitive
    switch(lower(command))
        case 'set_speed'
            argument = argument*6/36; % convert �/s to RPM
            send_serial(['S' uint8(argument)]);
        case 'step_left'
            send_serial(['l' uint8(argument)]);
        case 'step_right'
            send_serial(['r' uint8(argument)]);
        case 'set_sequence_rate'
            send_serial(['P' uint8(argument)]);
        case 'set_sequence_gain'
            send_serial(['G' uint8(argument)]);
        case 'send_sequence'
%             argument(argument==-1)=2;             
            len = length(argument)/4;
            sequence = uint8(len);
            outbyte = uint8(0);
            ctr = 1;
            for i = 1:length(argument)
                if argument(i) > 0
                    outbyte=bitset(outbyte,ctr,1);
                elseif argument(i) < 0
                    outbyte=bitset(outbyte,ctr+1,1);
                end
                ctr = ctr+2;
                if ctr==9
                    sequence(end+1)=outbyte;
                    outbyte = uint8(0);
                    ctr=1;
                end
            end
            sequence = ['C' sequence]; 
            for i = 1:50:length(sequence)
                iend = i+49;
                iend = min([iend length(sequence)]);
                send_serial(sequence(i:iend));
                pause(.05);
            end
        case 'set_trig_mode'
            switch argument
                case 'off'
                    send_serial(['T' uint8(0)]);
                case 'step_on_trig'
                    send_serial(['T' uint8(1)]);
                case 'start_on_trig'
                    send_serial(['T' uint8(2)]);
                otherwise
                    error('Invalid trigger mode. Valid options: off step_on_trig start_on_trig')
            end
        case 'voltage'
            send_serial('V');
        case 'reset'
            % Assert DTR to reset arduino
%             s = serialport(port, 9600);
            setDTR(port,false);
            setDTR(port,true);
            
%             fopen(s);
%             fclose(s);
%             delete(s);
%             delete(s);
            pause(2);%block for the arduino to reboot
        otherwise
            error(['Not a recognized command: "' command '"']);
    end
    
    function send_serial(cmd)
%         ss = serialport(port, 9600);
%         setDTR(ss,false);
%         ss.OutputBufferSize = 1024;
% %         ss.configureTerminator(0);
%         write(ss, cmd, 'uint8');
%         delete(ss);
        
        write(port, cmd, 'uint8');
%         warning off 'instrument:serial:ClassToBeRemoved'
%         ss = serial(port,'DataTerminalReady','off','OutputBufferSize',1024,'Terminator','');%DTR is hard-wired to arduino reset so keep it off
%         fopen(ss);
%         fwrite(ss,cmd, 'uint8');
%         fclose(ss);
%         delete(ss);
    end
end