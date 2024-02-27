function rate = findArenaRate(pattern)
% findArenaRate.m
% Finds the rate of the arena, which is "SUPPOSED" to be 50Hz.
%
% Input:
%   - pattern: the pattern ID
%
% Author: Nobel Zhou
% Date: 21 February 2024
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (2/21/2024): Initial commit
    
    clc;
    
    %% Declare Constants
    DURATION = 10;
    DAQ_RATE = 10000;

    %% Set up DAQ and Arena
    fprintf('Setting up DAQ.');
    daqreset; % Reset DAQ
    
    % Initialize DAQ
    d = daq('ni');
    fprintf('.');
    d.Rate = DAQ_RATE;
    fprintf('.');
    
    % Add arena control trigger channel
    ch = addinput(d, 'dev1', 'ai1', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');

    % Add arena (y) channel
    ch = addinput(d, 'dev1', 'ai4', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.done\n');

    %% Setup LED Arena
    fprintf('Setting up LED Arena.');
    Panel_com('clear'); % Clear LED Arena
    fprintf('.');
    Panel_com('stop'); % Stop LED Arena
    fprintf('.');
    Panel_com('stop_w_trig'); % Stop trigger
    fprintf('.done\n');
    
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

    Panel_com('set_pattern_id', pattern); % Load random pattern onto arena
    Panel_com('ident_compress_on');

    fprintf('\tSetting mode to function mode.');
    Panel_com('set_mode', [4 4]);
    fprintf('.');
    Panel_com('send_gain_bias', [0 0 0 0]);
    fprintf('.done\n');

    sequence = [1 90];
    sequence = repmat(sequence, 1, 500); % Create alternating sequence of 1 and 96
    
    fprintf('\tSending arena function.')
    for i = 0 : 19
        j = 1 + i * 50;
        k = j + 49;

        Panel_com('send_function', [2 i sequence(j : k)]); % 2 for Y
        fprintf('.');
        pause(0.1);
    end
    fprintf('.done\n');

    fprintf('\tSetting initial position...\n');
    Panel_com('set_position', [1 1]); % Write first position

    fprintf('Done setting up LED Arena.\n');

    %% Collect Data
    fprintf('Starting execution...\n');
    fprintf('\tStarting DAQ operation...\n');
    start(d, 'Duration', seconds(DURATION + 2)); % Start DAQ collection/writing and wait for trigger
    pause(2); % Pause for 2 seconds to make sure DAQ starts triggering

    Panel_com('start_w_trig'); % Send trigger to camera and DAQ.
    while d.Running
        drawnow;
    end

    %% Read Data
    fprintf('\tData collection received.\nReading data..');
    data = read(d, 'all'); % Reads all input data
    fprintf('.done\n');

    fprintf('Performing cleanup...\n');
    fprintf('\tStopping Arena...\n');
    Panel_com('stop_w_trig'); % Stop triggering and stop arena

    fprintf('\tClearing DAQ...\n');
    clear d % Delete DAQ

    arena = data.Dev1_ai4;
    idx = find(abs(diff(arena)) > 2); % Find indices of change

    averagePeriod = mean(diff(idx));
    
    rate = 1 / (averagePeriod / DAQ_RATE);
end