function [data, time] = stepperRigControl(funcV, funcS, pattern, duration, rate)
% stepperRigControl.m
% Rewrite for controlling the stepper and arena rig.
%
% Inputs:
%   - funcV: the visual function for the background in the arena, limit 
%       1000; in the event that no visual function is needed, provide an 
%       empty array of 0's. Interleaved zeros necessary to match rate with
%       stepper; otherwise, they are not necessary.
%   - funcS: the stepper pattern, limit 1000; in the event that no visual 
%       function is needed, provide an empty array of 0's. Interleaved 
%       zeros necessary if used with the arena; otherwise, they are not 
%       necessary.
%   - pattern: the arena pattern, usually 'all_on' or 1
%   - duration: the length of the experiment
%   - rate: the rate of the stepper, if using stepper only. The default is
%       50Hz
%
% Author: Nobel Zhou (nxz157)
% Date: 30 June 2023
% Version: 1.1
%
% VERSION CHANGELOG:
% - v0.1 (6/15/2023): Initial commit
% - v0.2 (6/16/2023): Added stepper functionality
% - v1.0 (6/19/2023): Production ready, added trigger functionality
% - v1.1 (6/30/2023): Changed from DAQ trigger to arena trigger due to
%                       voltage problems, with stepper triggered from X
% - v1.2 (7/3/2023): Added low trigger and stepper only functionality

    clc
    close all
    %% Check and Fill Arguments
    if nargin < 4
        error('Not enough input arguments.');
    end
    
    if nargin < 5
        rate = 50;
    end
    
    rigUse = [1 1]; % Stores whether the arena and/or stepper are used
    if all(~funcV)
        rigUse(1) = 0;
    end
    
    if all(~funcS)
        rigUse(2) = 0;
    end
    
    if ~rigUse
        error('No pattern given for either arena or stepper.');
    end
    
    %% Define Constants
    DAQ_RATE = 10000;
    STEPPER_PORT = 'COM3';
    
    %% Setup DAQ
    fprintf('Setting up DAQ...');
    daqreset; % Reset DAQ
    
    % Initialize DAQ
    d = daq('ni');
    fprintf('.');
    d.Rate = DAQ_RATE;
    fprintf('.');
 
    % Setup input channels
    % Add arena control trigger channel
    ch = addinput(d, 'dev1', 'ai1', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');
    
    % Add fastec camera frame sync channel
    ch = addinput(d, 'dev1', 'ai2', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');
    
    % Add stepper trigger channel
    ch = addinput(d, 'dev1', 'ai3', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');
    
    % Add arena (y) channel
    ch = addinput(d, 'dev1', 'ai4', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');
    
    % Add stepper channel
    ch = addinput(d, 'dev1', 'ai6', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');

    % Add trigger connection from arena controller
    trigger = addtrigger(d, 'Digital', 'StartTrigger', 'External', 'dev1/PFI1');
    trigger.Condition = 'RisingEdge';
    fprintf('.done\n');
    
    %% Setup LED Arena
    fprintf('Setting up LED Arena');
    Panel_com('clear'); % Clear LED Arena
    fprintf('.');
    Panel_com('stop'); % Stop LED Arena
    fprintf('.');
    Panel_com('stop_w_trig'); % Stop trigger
    fprintf('.done\n');
    
    fprintf('\tLoading pattern...\n');
    Panel_com('set_pattern_id', pattern); % Load pattern onto arena
    Panel_com('ident_compress_off'); 

    % Coder's note: I do not know what the above command does, but it was
    % carried over from the previous stepper rig control. If it aint broke,
    % don't fix it - nxz157, 6/19/2023
    
    fprintf('\tSetting trigger rate...\n');
    Panel_com('set_trigger_rate', 1);

    % Ensure trigger starts on low first
    fprintf('\tChecking trigger status...\n');
    if read(d).('Dev1_ai1') > 2
        loopTime = tic;
        checks = 1;
        while (read(d).('Dev1_ai1') > 2)
            fprintf('\t\tTrigger status check failed. Attempting to lower trigger voltage...\n');
            Panel_com('start_w_trig'); % Start trigger to advance so it's low again

            while (read(d).('Dev1_ai1') > 2) % Wait until the trigger is no longer high
                if toc(loopTime) > 10 % If 10 seconds elapsed, there is something wrong and we should stop trying
                    error('\tCould not reset arena trigger before trial within 10 seconds. Exiting...\n');
                end
                pause(0.01);
            end
            Panel_com('stop_w_trig'); % Stop trigger and check if low
            fprintf(['\t\tChecking trigger status again (Iteration ' num2str(checks) ')...\n'])
            checks = checks + 1;
        end
    end
    fprintf('\t\tTrigger status check complete.\n');

    % Coder's note: the above loop ensures that the trigger does not skip a
    % frame. In certain cases, the trigger can be stopped while it is high,
    % and since we look at the rising edge, we need to ensure that it
    % starts low in order for the first frame to be triggered. The above
    % code ensures that the trigger starts low, and if it doesn't work
    % after 10 seconds, it throws an error. - nxz157, 7/3/2023
    
    if ~rigUse(1)
        fprintf('No function provided for LED Arena.\n')
    else
        fprintf('\tSetting mode to function mode.');
        Panel_com('set_mode', [4 4]);
        fprintf('.');
        Panel_com('send_gain_bias', [0 0 0 0]);
        fprintf('.done\n');

        fprintf('\tSending arena function.')
        for i = 0 : 19
            j = 1 + i * 50;
            k = j + 49;
    
            Panel_com('send_function', [1 i funcV(j : k)]); % 1 for Y
            fprintf('.');
            pause(0.1);
        end
        fprintf('.done\n');
        
        fprintf('\tSetting initial position...\n');
        Panel_com('set_position', [48 1]); % Write first position

        fprintf('Done setting up LED Arena.\n');
    end
    
    %% Setup Stepper
    fprintf('Setting up Stepper...\n');
    
    if ~rigUse(2)
        fprintf('No function provided for Stepper.\n')
    else
        fprintf('\tEstablishing serial connection to stepper');

        % Make serial port
        stepper = serialport(STEPPER_PORT, 9600);
        fprintf('.');
        stepper.OutputBufferSize = 1024;
        fprintf('.');
        Stepper_com(stepper, 'reset');
        fprintf('.done\n');
        
        fprintf('\tSetting stepper gain...\n');
        gain = max(abs(funcS)); % The max should be 1, 2, etc., which specifies the gain
        Stepper_com(stepper, 'set_sequence_gain', gain);

        if rigUse(1) % Only 50Hz available with arena
            fprintf('\tSetting mode to voltage mode...\n');
            Stepper_com(stepper, 'voltage');
            pause(1);
            
            fprintf('\tParsing stepper trigger m-sequence...\n');
            stepperMSeq = ((-1) .^ (1 : 1000) + 1) * 95 + 1; % Create alternating vector of 1 and 96

            % stepperMSeq = funcS / gain * 45;
            % 
            % % Coder's note: we set the magnitude to 45 so we get values of 
            % % 3, 48, and 93. Using these values, we can ensure that the 
            % % stepper can detect the voltage resolution and step left and 
            % % right, accordingly. - nxz157, 6/30/2023

            % Coder's note: the above is now obsolete, due to the fact that
            % we are storing the stepper sequence on the stepper itself,
            % and the arena X function is simply just triggering the
            % stepper for each step. - nxz157, 7/3/2023
    
            fprintf('\tSending stepper function.')
            for i = 0 : 19
                j = 1 + i * 50;
                k = j + 49;
        
                Panel_com('send_function', [2 i stepperMSeq(j : k)]); % 2 for X
                fprintf('.');
                pause(0.1);
            end
            fprintf('.done\n');
        else
            fprintf('\tSending stepper function...\n');
            Stepper_com(stepper, 'send_sequence', funcS);

            fprintf('\tSetting trigger mode...\n')
            Stepper_com(stepper, 'set_trig_mode', 'start_on_trig');

            fprintf('\tSetting sequence rate...\n')
            Stepper_com('set_sequence_rate', rate);
            Panel_com('set_trigger_rate', 1);
        end

        fprintf('Done setting up Stepper.\n');
    end
    
    %% Final Preparations
    fprintf('Performing final preparations...\n')
    fprintf('\tWaiting for user start signal...\n');
    uiwait(msgbox({'Please arm camera and click ok to continue', ...
        ['(Required buffer length ' num2str(duration) ' seconds)']}));
    
    fprintf('Starting execution...\n');
    fprintf('\tStarting DAQ operation...\n');
    start(d, 'Duration', seconds(duration)); % Start DAQ collection/writing and wait for trigger
    fprintf('\tWaiting for trigger...\n');
    Panel_com('start_w_trig'); % Send trigger to camera and DAQ

    time = datetime('now'); % Record time

    fprintf(['\tTrigger received. Waiting ' num2str(duration) ' seconds...\n']);
    pause(duration); % Wait for DAQ to finish

    % Coder's note: previously, we have used an IsDone to check to see if
    % the DAQ is done. This was removed in the new DAQ interface, and any
    % other calls like drawnow or what-not cause an async error. Thus, we
    % cannot use a listener to call a function. The quick solution to this
    % is simply to wait until we are sure the DAQ is finished, and then
    % collect all the data at once. - nxz157, 6/19/2023

    fprintf('\tData collection received.\nReading data..');
    data = read(d, 'all'); % Reads all input data
    fprintf('.done\n');

    %% Reset and Cleanup Operations
    fprintf('Performing cleanup...\n');
    fprintf('\tStopping Arena...\n');
    Panel_com('stop_w_trig'); % Stop triggering and stop arena

    % Coder's note: you may notice that the arena and stepper will start up
    % again and go through their m-sequence. This is normal and irrelevant,
    % as data has already been done collecting when this happens. - nxz157,
    % 6/30/2023

    if rigUse(2)
        fprintf('\tResetting Stepper...\n');
        Stepper_com(stepper, 'reset'); % Reset stepper to exit voltage loop
    end
    fprintf('\tClearing DAQ...\n');
    clear d % Delete DAQ
    fprintf('Done collecting data!\n');
end
