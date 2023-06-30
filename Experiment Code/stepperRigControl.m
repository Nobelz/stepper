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
% Date: 19 June 2023
% Version: 1.0
%
% VERSION CHANGELOG:
% - v0.1 (6/15/2023): Initial commit
% - v0.2 (6/16/2023): Added stepper functionality
% - v1.0 (6/19/2023): Production ready, added trigger functionality
% - v1.1 (6/30/2023): Changed from DAQ trigger to arena trigger due to
%                       voltage problems, with stepper triggered from X

    clc
    close all
    %% Check and Fill Arguments
    if nargin < 4
        error('Not enough input arguments.');
    end
    
    if nargin < 5
        rate = 50;
    end
%     if nargin < 5
%         setup = 0; % If setup input not provided, default to not doing setup
% 
%         % Coder's note: if no input is provided but no setup has been done
%         % before, this code will still perform setup, irregardless of
%         % input. - nxz157, 6/16/2023
%     end
    
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

%     ARENA_DELAY = 0.004; Removed because stepper is no longer being
%     triggered by the DAQ
    
%     %% Rerun Mappings (if necessary)
%     if setup || ~isfile('mapping.mat')
%         mapping = getMapping();
%     else
%         fprintf('Skipping re-mapping.\n');
%         load('mapping.mat', 'mapping');
%     end
% 
%     close all
    
    %% Setup DAQ
    fprintf('Setting up DAQ...');
    daqreset; % Reset DAQ
    
    % Initialize DAQ
    d = daq('ni');
    fprintf('.');
    d.Rate = DAQ_RATE;
    fprintf('.');
    
%     % Create DAQ input for arena
%     daqExpData = zeros(DAQ_RATE * duration, 2);
    
%     % Setup output channels
%     addoutput(d, 'dev1', 'ao0', 'Voltage'); % Output channel for LED Arena (X and Y)
%     fprintf('.');
%      
%     addoutput(d, 'dev1', 'ao1', 'Voltage'); % Output channel for Stepper
%     fprintf('.');
 
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

%         fprintf('\tSampling rate...\n');
%         % Determine indices of change, based on frequency
%         lastIdx = 1000 / rateV * DAQ_RATE; % Find last index
%         indices = round(linspace(0, lastIdx, 1001)) + 1; % Find indices of change, starting with 1
%         indices = indices(1 : 1000); % Disregard last index, as this is when everything finishes and we don't care about the finish point
%     
%         % Coder's note: the above is a little confusing. Let's take a 
%         % somewhat easier example: say we have a 10Hz DAQ, 2Hz pattern 
%         % velocity, and 3 length sequence. Then, we need to get the 
%         % duration of the sequence, which is 3 / 2 = 1.5 seconds. In DAQ 
%         % data points, this is 1.5 * 10 = 15 data points. Note that 15 
%         % would be the last point, and we need to get the 3 starting 
%         % points, which would be time 0, time 5, and time 10 using 
%         % linspace, chopping off the last 15. We increment by 1 to account 
%         % for dumb MATLAB indexing. - nxz157, 6/15/2023
%         
%         funcV = funcX; % Select a function that's not just nothing
%         if rigUse(1) && ~rigUse(2)
%             Panel_com('set_mode', [3 4]);
%             fprintf('\tParsing X function');
%         elseif ~rigUse(1) && rigUse(2)
%             Panel_com('set_mode', [4 3]);
%             fprintf('\tParsing Y function');
%             funcV = funcY;
%         else 
%             Panel_com('set_mode', [3 3]);
%             fprintf('\tParsing X/Y function');
%         end
%         
%         % Change m-sequence into positional data
%         arenaMSeq = cumsum(funcV); 
%         fprintf('.');
% 
%         % Coder's note: currently, because of the lack of outputs, X and Y 
%         % can only be set to the same sequence or none at all. While this 
%         % code's functionality, with some tweaking, will allow independent 
%         % X and Y m-sequences, we are currently limited by DAQ space. 
%         % An alternative is to setup ao1 to be Y and ao0 to be X, but then 
%         % you would lose stepper functionality. If this is co-opted in the 
%         % future, this may be helpful. Best of luck, future researcher! 
%         % - nxz157, 6/15/2023
%     
%         % Resolve rollover indices
%         arenaMSeq(arenaMSeq < 0) = arenaMSeq(arenaMSeq < 0) + 96; 
%         arenaMSeq(arenaMSeq > 96) = arenaMSeq(arenaMSeq > 96) - 96; 
%         fprintf('.');
%         
%         % Coder's note: the above 2 lines do not account for massive gain. 
%         % If you have a gain of >10, then you will most likely need to 
%         % employ a modulo operator to ensure that the cumsum of the 
%         % m-sequence is within 1 to 96. This should never happen, however, 
%         % at least for what I'm doing. Change at your (and your flies') 
%         % own risk. - nxz157, 6/15/2023
%     
%         arenaMSeq = arenaMSeq + 1; % Account for MATLAB indexing
%     
%         % Loop through each element of X sequence
%         lastIdx = 1;
%         for i = 1 : 999
%             daqExpData(lastIdx : indices(i + 1) - 1, 1) = mapping(arenaMSeq(i)); % Get voltage of index and add its time frame to DAQ
%             lastIdx = indices(i + 1);
%         end
%         fprintf('.');
% 
%         daqExpData(indices(1000) : end, 1) = mapping(arenaMSeq(end)); % Append last voltage all the way to the end of the time frame, to prevent a sudden jolt at the end
%         fprintf('.done\n');
        
        fprintf('\tSetting initial position...\n');
        Panel_com('set_position', [48 48]); % Write first voltage

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

        fprintf('\tSetting mode to voltage mode...\n');
        Stepper_com(stepper, 'voltage');
        pause(1);
        
        fprintf('\tSetting stepper gain...\n');
        gain = max(abs(funcS)); % The max should be 1, 2, etc., which specifies the gain
        Stepper_com(stepper, 'set_sequence_gain', gain);
        
        fprintf('\tParsing stepper m-sequence...\n');
        stepperMSeq = funcS / gain * 45;

        % Coder's note: we set the magnitude to 45 so we get values of 3,
        % 48, and 93. Using these values, we can ensure that the stepper
        % can detect the voltage resolution and step left and right,
        % accordingly. - nxz157, 6/30/2023

        fprintf('\tSending stepper function.')
        for i = 0 : 19
            j = 1 + i * 50;
            k = j + 49;
    
            Panel_com('send_function', [2 i stepperMSeq(j : k)]); % 2 for X
            fprintf('.');
            pause(0.1);
        end
        fprintf('.done\n');
        
%         fprintf('\tSampling rate...\n');
%         
%         % Determine indices of change, based on frequency
%         lastIdx = 1000 / rateS * DAQ_RATE; % Find last index
%         indices = round(linspace(0, lastIdx, 2001)) + 1; % Find indices of change, starting with 1
%         
%         % Coder's note: note that this is different than in the arena, as
%         % the arena linspaces 1000 while the stepper linspaces 2000, even
%         % though the sequence length is the same. The reason being is that
%         % because the stepper is not positionally controlled, we are
%         % sending square waves to the stepper, and thus, I need to reset
%         % to baseline before sending another step. For instance, if I had
%         % the sequence of "[1 1]", if I don't reset it between the 2
%         % indices, then the stepper has no way of knowing if I wanted just
%         % 1 step or 2 steps. - nxz157, 6/16/2023
% 
%         indices = indices(1 : 2000); % Disregard last index, as this is when everything finishes and we don't care about the finish point        
%         
%         fprintf('\tSetting gain...\n');
%         gain = max(abs(funcS)); % Get the max step
%         Stepper_com(stepper, 'set_sequence_gain', gain);
%         pause(1);
% 
%         % Coder's note: this is just a hack-y way of getting the gain of
%         % the m-sequence. This should be an integer, with default as 1, but
%         % sometimes it might be 2 or something else. I could send this as
%         % an additional input, but to keep everything the same as the
%         % arena, I opted to encode gain information in the sequence itself.
%         % - nxz157, 6/16/2023
%         fprintf('\tParsing stepper function');
%         stepperMSeq = upsample(funcS, 2); % Add one zero between each sequence (should now be length 2000)
%         fprintf('.');
% 
%         % Get unary m-sequence
%         stepperMSeq = stepperMSeq / gain * 2.5 + 2.5; % Should now be 0, 2.5, or 5
%         fprintf('.');
% 
%         % Coder's note: because the stepper works by "change" but the arena
%         % works on position, I need the actual m-sequence for the stepper
%         % but the cumsum for the arena. - nxz157, 6/16/2023
% 
%         % Coder's note: I need to change the m-sequence to a sequence of 0,
%         % 2.5, and 5, as those are the voltages to indicate left, nothing,
%         % and right, respectively. - nxz157, 6/16/2023
%         
%         daqExpData(1 : ARENA_DELAY * DAQ_RATE) = 2.5;
%         
%         % Coder's note: in practice, the arena is about 0.005s slower than
%         % the arena. To offset this, I am instituting a 0.005s delay on all
%         % input of the stepper to compensate for this delay. 
% 
%         % Loop through each element of X sequence
%         lastIdx = ARENA_DELAY * DAQ_RATE + 1;
%         for i = 1 : 1999
%             daqExpData(lastIdx : indices(i + 1) - 1, 2) = stepperMSeq(i); % Get voltage of index and add its time frame to DAQ
%             lastIdx = indices(i + 1);
%         end
%         fprintf('.');
%     
%         daqExpData(indices(2000) : end, 2) = stepperMSeq(end); % Append last voltage all the way to the end of the time frame, to prevent a sudden jolt at the end
%         fprintf('.done\n');

        fprintf('Done setting up Stepper.\n');
    end
    
    %% Final Preparations
    fprintf('Performing final preparations...\n')
%     fprintf('\tSending DAQ Data..');
%     preload(d, daqExpData); % Send data to DAQ
%     pause(2);
%     fprintf('.done\n');
    
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
    Panel_com('stop'); % Stop
    Panel_com('stop_w_trig'); % Stop triggering and stop arena
    if rigUse(2)
        fprintf('\tResetting Stepper...\n');
        Stepper_com(stepper, 'reset'); % Reset stepper to exit voltage loop
    end
    fprintf('\tClearing DAQ...\n');
    clear d % Delete DAQ
    fprintf('Done collecting data!\n');
end
