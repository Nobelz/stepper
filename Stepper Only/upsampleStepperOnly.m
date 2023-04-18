function upsampleStepperOnly(folderName)
% upsampleStepperOnly.m
% Upsamples m sequence to match camera fps length for stepper only (600
% fps)
%
% Inputs:
%   - folderName: the name of the folder to be analyzed
%
% Author: Nobel Zhou
% Date: 30 June 2022
% Version: 1.1
%
% VERSION CHANGELOG:
% - v1.0 (6/28/2022): Initial commit
% - v1.1 (6/30/2022): Fixed issue where the first element of m-sequence was skipped

%% Define Constants
PATH = './Data/';
SEQ_LENGTH = 127;
REPEATS = 3;
DEG_PER_STEP = 3.75;
FPS = 600;

%% Find Files
procFiles = dir(strcat(PATH, folderName, '/*_PROC.mat'));
expFiles = dir(strcat(PATH, folderName, '/*Hz*.mat'));
markerFiles = dir(strcat(PATH, folderName, '/*.xml'));

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
    mSeq = exp.step_seq;
    
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

%   No longer needed: above loops replaces functionality
%     for j = 1 : length(uphead) - triggers(1) % Start at first trigger frame
%         if (triggers(triggers(1) + j - 1)) % Check if frame is a trigger
%             upseq(j) = mSeq(seqIndex);
%             seqIndex = seqIndex + 1; % Increment sequence to next element
%         end
%     end
    
    % Transpose uphead matrices
    upheadBefore = upheadBefore';
    upheadNow = upheadNow';
    
    % Save to files
    uphead = upheadBefore;
    upseq = upseqBefore;
    save(strcat(PATH, folderName, '/', markerFiles(i).name(1 : end - 4), '_UPHEAD_BEFORE'), 'uphead');
    save(strcat(PATH, folderName, '/', markerFiles(i).name(1 : end - 4), '_UPSEQ_BEFORE'), 'upseq');
    
    uphead = upheadNow;
    upseq = upseqNow;
    save(strcat(PATH, folderName, '/', markerFiles(i).name(1 : end - 4), '_UPHEAD_NOW'), 'uphead');
    save(strcat(PATH, folderName, '/', markerFiles(i).name(1 : end - 4), '_UPSEQ_NOW'), 'upseq');
end
end