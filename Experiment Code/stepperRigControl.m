function data = stepperRigControl(treatment, gain, funcX, funcY, funcS, rateV, rateS, pattern, duration, setup)
% stepperRigControl.m
% Rewrite for controlling the stepper and arena rig.
%
% Inputs:
%   - treatment: the treatment of the fly (usually PCF)
%   - gain: the gain of the experiment (default is 1)
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
% Date: 15 June 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (6/15/2023): Initial commit

clc
%% Check and Fill Arguments
if nargin < 7
    error('Not enough input arguments.');
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

DAQ_RATE = 10000;

%% Rerun Mappings (if necessary)
if setup || ~isfile('mapping.mat')
    mapping = getMapping();
else
    load('mapping.mat', 'mapping');
end

%% Setup DAQ
fprintf('Setting up DAQ...');
daqreset; % Reset DAQ

% Setup output DAQ
out = daq('ni');
fprintf('.');
out.Rate = DAQ_RATE;
fprintf('.');

% Create DAQ input for arena
daqExpData = zeros(DAQ_RATE * duration, 2);

% Setup output channels
addoutput(out, 'dev1', 'ao0', 'Voltage'); % Output channel for LED Arena (X and Y)
fprintf('.');
% 
% addoutput(out, 'dev1', 'ao1', 'Voltage'); % Output channel for Stepper
% fprintf('.');

% % Add trigger connection from arena controller
% addtrigger(out, 'Digital', 'StartTrigger', 'External', 'dev1/PFI1');
% fprintf('.');
% Setup Input DAQ
in = daq('ni');
fprintf('.');
in.Rate = DAQ_RATE;
fprintf('.');

% Setup input channels
% Add arena control trigger channel
ch = addinput(in, 'dev1', 'ai1', 'Voltage');
ch.TerminalConfig = 'SingleEnded';
fprintf('.');

% Add fastec camera frame sync channel
ch = addinput(in, 'dev1', 'ai2', 'Voltage');
ch.TerminalConfig = 'SingleEnded';
fprintf('.');

% Add arena x channel
ch = addinput(in, 'dev1', 'ai3', 'Voltage');
ch.TerminalConfig = 'SingleEnded';
fprintf('.');

% Add arena y channel
ch = addinput(in, 'dev1', 'ai4', 'Voltage');
ch.TerminalConfig = 'SingleEnded';
fprintf('.');

% Add stepper channel
ch = addinput(in, 'dev1', 'ai6', 'Voltage');
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
    % Determine indices of change, based on frequency
    lastIdx = 1000 / rateV * DAQ_RATE; % Find last index
    indices = round(linspace(0, lastIdx, 1001)) + 1; % Find indices of change, starting with 1
    indices = indices(1 : 1000); % Disregard last index, as this is when everything finishes and we don't care about the finish point

    % Coder's note: the above is a little confusing. Let's take a somewhat
    % easier example: say we have a 10Hz DAQ, 2Hz pattern velocity, and 3
    % length sequence. Then, we need to get the duration of the sequence,
    % which is 3 / 2 = 1.5 seconds. In DAQ data points, this is 1.5 * 10 =
    % 15 data points. Note that 15 would be the last point, and we need to
    % get the 3 starting points, which would be time 0, time 5, and time 10
    % using linspace, chopping off the last 15. We increment by 1 to
    % account for dumb MATLAB indexing. - nxz157, 6/15/2023
    
    funcV = funcX; % Select a function that's not just nothing
    if rigUse(1) && ~rigUse(2)
        Panel_com('set_mode', [3 4]);
        fprintf('\tParsing X function...\n');
    elseif ~rigUse(1) && rigUse(2)
        Panel_com('set_mode', [4 3]);
        fprintf('\tParsing Y function...\n');
        funcV = funcY;
    else 
        Panel_com('set_mode', [3 3]);
        fprintf('\tParsing X/Y function...\n');
    end
    
    % Change m-sequence into positional data
    arenaMSeq = cumsum(funcX); 
    
    % Coder's note: currently, because of the lack of outputs, X and Y can
    % only be set to the same sequence or none at all. While this code's
    % functionality, with some tweaking, will allow independent X and Y
    % m-sequences, we are currently limited by DAQ space. An alternative is
    % to setup ao1 to be Y and ao0 to be X, but then you would lose stepper
    % functionality. If this is co-opted in the future, this may be
    % helpful. Best of luck, future researcher! - nxz157, 6/15/2023

    % Resolve rollover indices
    arenaMSeq(arenaMSeq < 0) = arenaMSeq(arenaMSeq < 0) + 96; 
    arenaMSeq(arenaMSeq > 96) = arenaMSeq(arenaMSeq > 96) - 96; 
    
    % Coder's note: the above 2 lines do not account for massive gain. If
    % you have a gain of >10, then you will most likely need to employ a
    % modulo operator to ensure that the cumsum of the m-sequence is within
    % 1 to 96. This should never happen, however, at least for what I'm
    % doing. Change at your (and your flies') own risk. - nxz157, 6/15/2023

    arenaMSeq = arenaMSeq + 1; % Account for MATLAB indexing

    % Loop through each element of X sequence
    lastIdx = 1;
    for i = 1 : 999
        daqExpData(lastIdx : indices(i + 1) - 1, 1) = mapping(arenaMSeq(i)); % Get voltage of index and add its time frame to DAQ
        lastIdx = indices(i);
    end

    daqExpData(indices(1000) : end, 1) = mapping(arenaMSeq(end)); % Append last voltage all the way to the end of the time frame, to prevent a sudden jolt at the end
    
    fprintf('Done setting up LED Arena.\n');
end

Panel_com('start');
pause(2);
preload(out, daqExpData(:, 1));
pause(2);
start(out);
pause;
data = daqExpData;
end
