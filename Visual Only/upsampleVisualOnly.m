function upsampleVisualOnly()
% upsampleVisualOnly.m
% Upsamples m sequence to match camera fps length for visual only (600 fps)
%
% Author: Nobel Zhou
% Date: 7 July 2022
% Version: 1.0
%
% VERSION CHANGELOG:
% - v1.0 (7/7/2022): Initial commit

%% Define Constants
PATH = './Data/';
SEQ_LENGTH = 127;
REPEATS = 3;
DEG_PER_STEP = 3.75;
FPS = 600;

%% Find Files
expFiles = dir(strcat(PATH, '/*exp_arena_only*.mat'));
procFiles = dir(strcat(PATH, '*0_PROC.mat'));
markerFiles = dir(strcat(PATH, '*.xml'));

%% Loop through Files
for i = 1 : length(procFiles)
    disp(append('Upsampling File ', num2str(i), ' of ', num2str(length(procFiles)), ': ', procFiles(i).name));

    % Add folder to path
    addpath(expFiles(i).folder);
    addpath(markerFiles(i).folder);
    addpath(procFiles(i).folder);
    
    % Load files
    load(expFiles(i).name);
    load(procFiles(i).name);
    
    % Find m-sequence
    mSeq = [0 diff(exp.vis_funcy)];
    
    % Find triggers of m-sequence
    trigChannel = fastecMarkerReader(markerFiles(i).name, 6);
    triggers = find(diff(trigChannel) == 1) + 1; % Account for diff reducing the index by 1
    
    % Determine relative head angles from proc file
    headAngle = fly.proc.HeadAng; 
    bodyAngle = fly.proc.BodyAng; 
    relativeHeadAngle = bodyAngle - headAngle; % Calculate relative head angle
    
    % Trim head angles to 0.5 seconds before 1st trigger and 1 second after last trigger (if possible)
    upheadBefore = relativeHeadAngle(triggers(1) - 0.5 * FPS : min(triggers(SEQ_LENGTH * 2 * REPEATS) + FPS, length(relativeHeadAngle)));
    
    % Trim head angles to triggers without 0.5 seconds at beginning
    upheadNow = relativeHeadAngle(triggers(1) : min(triggers(SEQ_LENGTH * 2 * REPEATS) + FPS, length(relativeHeadAngle)));
    
    % Initiate upseq matrices
    upseqBefore = zeros(1, length(upheadBefore));
    upseqNow = zeros(1, length(upheadNow));
    
    % Up sample sequence to match upseq
    for j = 1 : SEQ_LENGTH * 2 * REPEATS
        % First m-sequence element (the prepended zero) is skipped
        upseqBefore(triggers(j) - triggers(1) + 1) = mSeq(j + 1) * DEG_PER_STEP;  
        upseqNow(triggers(j) - triggers(1) + 1) = mSeq(j + 1) * DEG_PER_STEP;
    end
    
    % Transpose uphead matrices
    upheadBefore = upheadBefore';
    upheadNow = upheadNow';
    
    % Save to files
    uphead = upheadBefore;
    upseq = upseqBefore;
    save(strcat(PATH, '/', markerFiles(i).name(1 : end - 4), '_UPHEAD_BEFORE'), 'uphead');
    save(strcat(PATH, '/', markerFiles(i).name(1 : end - 4), '_UPSEQ_BEFORE'), 'upseq');
    
    uphead = upheadNow;
    upseq = upseqNow;
    save(strcat(PATH, '/', markerFiles(i).name(1 : end - 4), '_UPHEAD_NOW'), 'uphead');
    save(strcat(PATH, '/', markerFiles(i).name(1 : end - 4), '_UPSEQ_NOW'), 'upseq');
end
end