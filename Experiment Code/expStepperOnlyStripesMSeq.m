function expStepperOnlyStripesMSeq(flyNum, flyTrial, sequence, double, delayed)
% expStepperOnlyStripesMSeq.m
% Rewrite for experiment for stepper only trials with m-sequence, with
% visual background.
%
% Inputs:
%   - flyNum: the number of the fly to be analyzed
%   - flyTrial: the trial of the fly
%   - sequence: the m-sequence. If not given, a random m-sequence will be
%       generated
%   - double: whether the m-sequence should be doubled (default is no (0))
%   - delayed: whether the m-sequence should be delayed by 200 iterations
%       (default is no (0))
%
% Author: Nobel Zhou
% Date: 1 June 2023
% Version: 0.2
%
% VERSION CHANGELOG:
% - v0.1 (4/17/2023): Initial commit
% - v0.2 (6/1/2023): Added doubling and delayed functionality

if nargin < 2 % Check if fly number and trial are provided
    error('Fly number and trial required as inputs.');
elseif nargin < 3 || length(sequence) ~= 1000 % Check if sequence length is appropriate
    warning('M-sequence length incorrect or not provided. Generating m-sequence...');
    sequence = generateMSeq();
elseif nargin < 5 % Check and assign optional arguments
    delayed = 0;
    if nargin < 4
        double = 0;
    end
end

% Check if m-sequence should be doubled
if double == 1
    GAIN = 2;
else
    GAIN = 1;
end

% Check if m-sequence should be delayed
if delayed == 1
    sequence = [zeros(1, 200) sequence];

    % It's ok to chip off the last 200 iterations of the m-sequence 
    % as the m-sequence should only go to 1 to 3x127x2 (762), so with 200
    % delay, it should be 962 max - nxz157
    sequence = sequence(1 : 1000); 
end

% Slow down to 1Hz for testing purposes
sequence = repelem(sequence, 50); 
sequence = sequence(1 : 1000);

% Define Constants
STEP_RATE = 51;
DURATION = 20;
PATTERN = 2;
              
%% Set Arena Configuration
opts = struct; 
opts.treatment = 'PCF';
opts.step_seq = sequence;
opts.step_rate = STEP_RATE;
opts.vis_pat = PATTERN;
opts.gain = GAIN;
opts.vis_funcx = [];
opts.vis_funcy = [];
opts.exp_dur = DURATION;

% Run Experiment
exp=stepper_rig_control(opts);

% Save Data
btn = questdlg('Save This Trial?','Save Trial', 'Yes', 'No', 'No');

if strcmp(btn, 'Yes')
    foldname = [datestr(exp.exptime,'yyyymmdd_HHMMSS_') exp.treatment '_' mfilename];
    mkdir(foldname);
    if flyTrial > 0
        filename = [exp.treatment num2str(flyNum) 'T' num2str(flyTrial) '_' mfilename datestr(exp.exptime,'_yyyymmdd_HHMMSS')];
    else
        filename = [exp.treatment num2str(flyNum) 'con_' mfilename datestr(exp.exptime,'_yyyymmdd_HHMMSS')];
    end
    filename = fullfile(foldname, filename);
    disp(['Saving to ' filename]);
    save(filename,'exp');
end
end