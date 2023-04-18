function expStepperOnlyStripesMSeq(flyNum, flyTrial, double, sequence)
% expStepperOnlyStripesMSeq.m
% Rewrite for experiment for stepper only trials with m-sequence, with
% visual background.
%
% Inputs:
%   - flyNum: the number of the fly to be analyzed
%   - flyTrial: the trial of the fly
%   - double: whether the m-sequence should be doubled (default is no)
%   - sequence: the m-sequence. If not given, a random m-sequence will be
%       generated
%
% Author: Nobel Zhou
% Date: 18 April 2023
% Version: 0.1

if nargin < 2
    error('Fly number and trial required as inputs.');
elseif nargin > 3 && length(sequence) ~= 1000 % Check if sequence length is appropriate
    error('M-sequence length incorrect.');
elseif nargin < 4 % Check if sequence was provided
    warning('M-sequence not provided. Generating m-sequence...');
    sequence = generateMSeq(); % Generate new m-sequence
end

% Check if m-sequence should be doubled
if nargin > 2 && double == 1
    sequence = 2 * sequence; % Double m-sequence
end

% Define Constants
STEP_RATE = 50;
DURATION = 16;
PATTERN = 2;
              
%% Set Arena Configuration
opts = struct;
opts.treatment = 'PCF';
opts.step_seq = sequence;
opts.step_rate = STEP_RATE;
opts.vis_pat = PATTERN;
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