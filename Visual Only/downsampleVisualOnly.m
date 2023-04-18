function downsampleVisualOnly()
% downsampleVisualOnly.m
% Downsamples head angles to match m-sequence length for visual only
% trials.
%
% Author: Nobel Zhou
% Date: 7 July 2022
% Version: 1.0.1
%
% VERSION CHANGELOG:
% - v1.0 (6/28/2022): Initial commit
% - v1.0.1 (7/7/2022): Turned into function

%% Define Constants
PATH = './Data/';
SEQ_LENGTH = 127;
REPEATS = 3;

%% Find Files
procFiles = dir(strcat(PATH, '*0_PROC.mat'));
markerFiles = dir(strcat(PATH, '*.xml'));

%% Loop through Files
for i = 1 : length(procFiles)
    disp(append('Downsampling File ', num2str(i), ' of ', num2str(length(procFiles)), ': ', procFiles(i).name));

    % Add folder to path
    addpath(markerFiles(i).folder);
    addpath(procFiles(i).folder);
    
    % Find triggers of m-sequence
    trigChannel = fastecMarkerReader(markerFiles(i).name, 6);
    triggers = find(diff(trigChannel) == 1);
    
    % Determine relative head angles from proc file
    load(procFiles(i).name);
    headAngle = fly.proc.HeadAng; 
    bodyAngle = fly.proc.BodyAng; 
    relativeHeadAngle = bodyAngle - headAngle; % Calculate relative head angle
    
    % Initiate downhead matrix
    downhead = zeros(1, length(triggers) - 1);
    for j = 1 : length(triggers) - 1
        % Calculate average over interval of interest to downsample
        interval = triggers(j) : triggers(j + 1) - 1;
        downhead(j) = mean(relativeHeadAngle(interval));
    end
    
    % Truncate downhead matrix to match m-sequence length
    downhead = downhead(1 : SEQ_LENGTH * 2 * REPEATS);
    
    % Save to file
    save(strcat(PATH, markerFiles(i).name(1 : end - 4), '_DOWNHEAD'), 'downhead')
end
end