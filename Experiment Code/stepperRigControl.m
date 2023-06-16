function data = stepperRigControl(treatment, funcX, funcY, funcS, rateV, rateS, pattern, duration, setup)
% stepperRigControl.m
% Rewrite for controlling the stepper and arena rig.
%
% Inputs:
%   - treatment: the treatment of the fly (usually PCF)
%   - funcX: the visual function for the figure in the arena, limit 1000; 
%       in the event that no visual function is needed, provide an empty
%       array of 0's
%   - funcY: the visual pattern for the background in the arena, limit
%       1000; in the event that no visual function is needed, provide an 
%       empty array of 0's
%   - funcS: the stepper pattern, limit 1000; in the event that no visual 
%       function is needed, provide an empty array of 0's
%   - rateV: the rate of the visual pattern
%   - rateS: the rate of the stepper
%   - pattern: the arena pattern, usually 'all_on' or 2
%   - duration: the length of the experiment
%   - setup: whether to rerun mappings
%
% Author: Nobel Zhou, nxz157
% Date: 16 June 2023
% Version: 0.2
%
% VERSION CHANGELOG:
% - v0.1 (6/15/2023): Initial commit
% - v0.2 (6/16/2023): Added stepper functionality

    clc
    close all
    %% Check and Fill Arguments
    if nargin < 8
        error('Not enough input arguments.');
    end

    if nargin < 9
        setup = 0; % If setup input not provided, default to not doing setup

        % Coder's note: if no input is provided but no setup has been done
        % before, this code will still perform setup, irregardless of
        % input. - nxz157, 6/16/2023
    end
    
    rigUse = [1 1 1]; % Stores whether the arena and/or stepper are used
    if all(~funcX)
        rigUse(1) = 0;
    end
    
    if all(~funcY)
        rigUse(2) = 0;
    end
    
    if all(~funcS)
        rigUse(3) = 0;
    end
    
    if ~rigUse
        error('No pattern given for either arena or stepper.');
    end
    
    %% Define Constants
    DAQ_RATE = 10000;
    STEPPER_PORT = 'COM3';
    ARENA_DELAY = 0.004;
    
    %% Rerun Mappings (if necessary)
    if setup || ~isfile('mapping.mat')
        mapping = getMapping();
    else
        fprintf('Skipping re-mapping.\n');
        load('mapping.mat', 'mapping');
    end

    close all
    
    %% Setup DAQ
    fprintf('Setting up DAQ...');
    daqreset; % Reset DAQ
    
    % Initialize DAQ
    d = daq('ni');
    fprintf('.');
    d.Rate = DAQ_RATE;
    fprintf('.');
    
    % Create DAQ input for arena
    daqExpData = zeros(DAQ_RATE * duration, 2);
    
    % Setup output channels
    addoutput(d, 'dev1', 'ao0', 'Voltage'); % Output channel for LED Arena (X and Y)
    fprintf('.');
     
    addoutput(d, 'dev1', 'ao1', 'Voltage'); % Output channel for Stepper
    fprintf('.');
    
%     % Add trigger connection from arena controller
%     addtrigger(out, 'Digital', 'StartTrigger', 'External', 'dev1/PFI1');
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
    
    % Add arena x channel
    ch = addinput(d, 'dev1', 'ai3', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');
    
    % Add arena y channel
    ch = addinput(d, 'dev1', 'ai4', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');
    
    % Add stepper channel
    ch = addinput(d, 'dev1', 'ai6', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');
    
    fprintf('.done\n');
    
    %% Setup LED Arena
    fprintf('Setting up LED Arena...\n');
    Panel_com('clear'); % Clear LED Arena
    
    fprintf('\tLoading pattern...\n');
    Panel_com('set_pattern_id', pattern); % Load pattern onto arena
    Panel_com('ident_compress_off'); % Idk what this does but it was in the previous file - nxz157
    
    fprintf('\tSetting mode to position mode...\n');
    Panel_com('send_gain_bias', [10 0 10 0]);
    
    if ~rigUse(1) && ~rigUse(2)
        fprintf('No function provided for LED Arena.\n')
    else
        fprintf('\tSampling rate...\n');
        % Determine indices of change, based on frequency
        lastIdx = 1000 / rateV * DAQ_RATE; % Find last index
        indices = round(linspace(0, lastIdx, 1001)) + 1; % Find indices of change, starting with 1
        indices = indices(1 : 1000); % Disregard last index, as this is when everything finishes and we don't care about the finish point
    
        % Coder's note: the above is a little confusing. Let's take a 
        % somewhat easier example: say we have a 10Hz DAQ, 2Hz pattern 
        % velocity, and 3 length sequence. Then, we need to get the 
        % duration of the sequence, which is 3 / 2 = 1.5 seconds. In DAQ 
        % data points, this is 1.5 * 10 = 15 data points. Note that 15 
        % would be the last point, and we need to get the 3 starting 
        % points, which would be time 0, time 5, and time 10 using 
        % linspace, chopping off the last 15. We increment by 1 to account 
        % for dumb MATLAB indexing. - nxz157, 6/15/2023
        
        funcV = funcX; % Select a function that's not just nothing
        if rigUse(1) && ~rigUse(2)
            Panel_com('set_mode', [3 4]);
            fprintf('\tParsing X function');
        elseif ~rigUse(1) && rigUse(2)
            Panel_com('set_mode', [4 3]);
            fprintf('\tParsing Y function');
            funcV = funcY;
        else 
            Panel_com('set_mode', [3 3]);
            fprintf('\tParsing X/Y function');
        end
        
        % Change m-sequence into positional data
        arenaMSeq = cumsum(funcX); 
        fprintf('.');

        % Coder's note: currently, because of the lack of outputs, X and Y 
        % can only be set to the same sequence or none at all. While this 
        % code's functionality, with some tweaking, will allow independent 
        % X and Y m-sequences, we are currently limited by DAQ space. 
        % An alternative is to setup ao1 to be Y and ao0 to be X, but then 
        % you would lose stepper functionality. If this is co-opted in the 
        % future, this may be helpful. Best of luck, future researcher! 
        % - nxz157, 6/15/2023
    
        % Resolve rollover indices
        arenaMSeq(arenaMSeq < 0) = arenaMSeq(arenaMSeq < 0) + 96; 
        arenaMSeq(arenaMSeq > 96) = arenaMSeq(arenaMSeq > 96) - 96; 
        fprintf('.');
        
        % Coder's note: the above 2 lines do not account for massive gain. 
        % If you have a gain of >10, then you will most likely need to 
        % employ a modulo operator to ensure that the cumsum of the 
        % m-sequence is within 1 to 96. This should never happen, however, 
        % at least for what I'm doing. Change at your (and your flies') 
        % own risk. - nxz157, 6/15/2023
    
        arenaMSeq = arenaMSeq + 1; % Account for MATLAB indexing
    
        % Loop through each element of X sequence
        lastIdx = 1;
        for i = 1 : 999
            daqExpData(lastIdx : indices(i + 1) - 1, 1) = mapping(arenaMSeq(i)); % Get voltage of index and add its time frame to DAQ
            lastIdx = indices(i + 1);
        end
        fprintf('.');

        daqExpData(indices(1000) : end, 1) = mapping(arenaMSeq(end)); % Append last voltage all the way to the end of the time frame, to prevent a sudden jolt at the end
        fprintf('.done\n');
        
        fprintf('\tSetting initial position...\n');
        % Set initial position so jolt doesn't happen at beginning
        write(d, [daqExpData(1, 1) 2.5]); % Write first voltage

        fprintf('Done setting up LED Arena.\n');
    end
    
    %% Setup Stepper
    fprintf('Setting up Stepper...\n');
    
    if ~rigUse(3)
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
        
        fprintf('\tSampling rate...\n');
        
        % Determine indices of change, based on frequency
        lastIdx = 1000 / rateS * DAQ_RATE; % Find last index
        indices = round(linspace(0, lastIdx, 2001)) + 1; % Find indices of change, starting with 1
        
        % Coder's note: note that this is different than in the arena, as
        % the arena linspaces 1000 while the stepper linspaces 2000, even
        % though the sequence length is the same. The reason being is that
        % because the stepper is not positionally controlled, we are
        % sending square waves to the stepper, and thus, I need to reset
        % to baseline before sending another step. For instance, if I had
        % the sequence of "[1 1]", if I don't reset it between the 2
        % indices, then the stepper has no way of knowing if I wanted just
        % 1 step or 2 steps. - nxz157, 6/16/2023

        indices = indices(1 : 2000); % Disregard last index, as this is when everything finishes and we don't care about the finish point        
        
        fprintf('\tSetting gain...\n');
        gain = max(abs(funcS)); % Get the max step
        Stepper_com(stepper, 'set_sequence_gain', gain);
        pause(1);

        % Coder's note: this is just a hack-y way of getting the gain of
        % the m-sequence. This should be an integer, with default as 1, but
        % sometimes it might be 2 or something else. I could send this as
        % an additional input, but to keep everything the same as the
        % arena, I opted to encode gain information in the sequence itself.
        % - nxz157, 6/16/2023
        fprintf('\tParsing stepper function');
        stepperMSeq = upsample(funcS, 2); % Add one zero between each sequence (should now be length 2000)
        fprintf('.');

        % Get unary m-sequence
        stepperMSeq = stepperMSeq / gain * 2.5 + 2.5; % Should now be 0, 2.5, or 5
        fprintf('.');

        % Coder's note: because the stepper works by "change" but the arena
        % works on position, I need the actual m-sequence for the stepper
        % but the cumsum for the arena. - nxz157, 6/16/2023

        % Coder's note: I need to change the m-sequence to a sequence of 0,
        % 2.5, and 5, as those are the voltages to indicate left, nothing,
        % and right, respectively. - nxz157, 6/16/2023
        
        daqExpData(1 : ARENA_DELAY * DAQ_RATE) = 2.5;
        
        % Coder's note: in practice, the arena is about 0.005s slower than
        % the arena. To offset this, I am instituting a 0.005s delay on all
        % input of the stepper to compensate for this delay. 

        % Loop through each element of X sequence
        lastIdx = ARENA_DELAY * DAQ_RATE + 1;
        for i = 1 : 1999
            daqExpData(lastIdx : indices(i + 1) - 1, 2) = stepperMSeq(i); % Get voltage of index and add its time frame to DAQ
            lastIdx = indices(i + 1);
        end
        fprintf('.');
    
        daqExpData(indices(2000) : end, 2) = stepperMSeq(end); % Append last voltage all the way to the end of the time frame, to prevent a sudden jolt at the end
        fprintf('.done\n');

        fprintf('Done setting up Stepper.\n');
    end
    
    Panel_com('start');
    pause(2);
    preload(d, daqExpData);
    pause(2);
    start(d, "Duration", seconds(duration))
    pause;
    data = read(d, 'all');
    Stepper_com(stepper, 'reset');
    Panel_com('stop');
end
