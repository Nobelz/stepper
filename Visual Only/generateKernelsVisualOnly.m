function kernels = generateKernelsVisualOnly(redoDownSampling, redoUpSampling, useDownSamples, showBeforeKernel, windowLength, duration)
% generateKernelsVisualOnly.m
% Generates kernels for all visual only trials.
%
% Inputs:
%   - redoDownSampling: whether to redownsample data
%   - redoUpSampling: whether to reupsample data
%   - useDownSampling: whether to use downsampling data for kernel
%       calculation
%   - showBeforeKernel: whether to add ~0.5s to front of kernel (only for
%       upsampling)
%   - windowLength: the length of the sliding window
%   - duration: the duration of the sliding window
%
% Author: Nobel Zhou
% Date: 28 June 2022
% Version: 1.2
%
% VERSION CHANGELOG:
% - v1.0 (6/21/2022): Initial commit
% - v1.1 (6/28/2022): Changed data to go off of new proc measurements
% - v1.2 (7/7/2022): Added upsampling functionality

%% Set Constants
PATH = './Data/';
SEQ_LENGTH = 127;
REPEATS = 3;
DEG_PER_STEP = 3.75;

%% Find Files
% Add folder name to path
addpath(PATH);

% Get experiment files, proc, and marker files
expFiles = dir(strcat(PATH, '/*exp_arena_only*.mat'));
downheadFiles = dir(strcat(PATH, '/*_DOWNHEAD.mat'));
upheadBeforeFiles = dir(strcat(PATH, '/*_UPHEAD_BEFORE.mat'));
upseqBeforeFiles = dir(strcat(PATH, '/*_UPSEQ_BEFORE.mat'));
upheadNowFiles = dir(strcat(PATH, '/*_UPHEAD_NOW.mat'));
upseqNowFiles = dir(strcat(PATH, '/*_UPSEQ_NOW.mat'));

% Check if videos have been downsampled
if length(downheadFiles) < length(expFiles) || redoDownSampling
    disp('Downsampling files...');
    downsampleVisualOnly();
    disp('Done downsampling files.');
    downheadFiles = dir(strcat(PATH, '/*_DOWNHEAD.mat')); % Reload downhead files
end

% Check if videos have been upsampled
if length(upheadBeforeFiles) < length(expFiles) || redoUpSampling
    disp('Upsampling files...');
    upsampleVisualOnly();
    disp('Done upsampling files.');
    
    % Reload upsampled files
    upheadBeforeFiles = dir(strcat(PATH, '/*_UPHEAD_BEFORE.mat'));
    upseqBeforeFiles = dir(strcat(PATH, '/*_UPSEQ_BEFORE.mat'));
    upheadNowFiles = dir(strcat(PATH, '/*_UPHEAD_NOW.mat'));
    upseqNowFiles = dir(strcat(PATH, '/*_UPSEQ_NOW.mat'));
end

%% Determine Which Uphead Files to Use
if showBeforeKernel
    upheadFiles = upheadBeforeFiles;
    upseqFiles = upseqBeforeFiles;
else
    upheadFiles = upheadNowFiles;
    upseqFiles = upseqNowFiles;
end

%% Initialize Kernel Data Structure
kernels.data(length(expFiles)) = struct();
kernels.windowLength = windowLength;
kernels.duration = duration;

%% Loop Through Files
disp(append('Found ', num2str(length(expFiles)), ' files.'));
for i = 1 : length(expFiles)
    disp(append('Evaluating File ', num2str(i), ' of ', num2str(length(expFiles)), ': ', expFiles(i).name));
    
    % Load files
    load(expFiles(i).name);
    load(downheadFiles(i).name);
    load(upheadFiles(i).name);
    load(upseqFiles(i).name);
    
%   Old code that aligns arena with head angle; no longer needed since we
%   use Fastec video triggers
%
%     % Find when function starts
%     trace = find(diff(exp.daq.data(:, 1) > 2) == -1) - 5;
%     
%     % Scale voltage trace to real world units 
%     vstim = exp.daq.data(trace, 4);
%     vstim = vstim / 5 * 360;
%     vstim = vstim - vstim(1);
%     
%     % Determine relative head angles from proc file
%     load(procFiles(i).name);
%     headAngle = fly.proc.HeadAng; 
%     bodyAngle = fly.proc.BodyAng; 
%     relativeHeadAngle1 = bodyAngle - headAngle; % Calculate relative head angle
%    
%     % Determine other head angle from downproc file
%     load(downprocFiles(i).name);
%     relativeHeadAngle2 = fly.head.angle - fly.abd.angle + 180;
%     
%     % Resample proc relative head angles
%     relativeHeadAngle1 = resample(relativeHeadAngle1, length(relativeHeadAngle2), length(relativeHeadAngle1));
%     

%   Old code that extracts the m sequence, replaced with below
%
%     % Extract m sequence
%     vfunc = exp.vis_funcy * DEG_PER_STEP;

%   Old code that aligns arena with head angle; no longer needed since we
%   use Fastec video triggers
%
%     % Align vstim and vfunc to make sure we start when the function starts
%     if length(alignsignals(vstim(1:100), vfunc(1:100))) > 100
%         % If the arena didn't miss the first index (a prepended zero to the
%         % sequence since this can happen) start at the second index, which 
%         % is the real first start of the sequence
%         vfunc = vfunc(2:end);
%         vfunc = vfunc - vfunc(1);
%         relativeHeadAngle1 = relativeHeadAngle1(2:end);
%         relativeHeadAngle2 = relativeHeadAngle2(2:end);
%     end
    
    % Downsampling condition
    if useDownSamples
        % Extract m sequence and head angles
        mSeq = [0 diff(exp.vis_funcy)] * DEG_PER_STEP;
        kernelLength = SEQ_LENGTH * 2 * REPEATS;
        intMSeq = mSeq(1 : kernelLength);
        intHead = downhead;
    else
        % Extract m sequence and head angles
        kernelLength = length(upseq);
        intMSeq = upseq;
        intHead = uphead;
    end

%   Old code that determined the m-sequence and head angle of interest; no
%   longer needed as functionality is accomplished in above condition
%
%     % Determine m sequence of interest
%     mSeq = [0 diff(vfunc)];
%     intMSeq = mSeq(1 : SEQ_LENGTH * 2 * REPEATS);
%     
%     % Determine head angle of interest
%     intHead = downhead;
%     intHead1 = relativeHeadAngle1(1 : SEQ_LENGTH * 2 * REPEATS)';
%     intHead2 = relativeHeadAngle2(1 : SEQ_LENGTH * 2 * REPEATS);
% 
%     intHead = intHead2;

%   Old code that downsampled the head angle; this is no longer needed as
%   it is done in downsampleVisualOnly.m
%
%     % Downsample head angles
%     downHead = zeros(1, SEQ_LENGTH * 2 * REPEATS);
%     angleIndex = 1;
%     for j = 1 : STEP : length(intHeadAngle)
%         downHead(angleIndex) = mean(intHeadAngle(j : j + STEP - 1));
%         angleIndex = angleIndex + 1;
%     end
%     
%     downHead = downHead(1 : SEQ_LENGTH * REPEATS * 2)';

    % Calculate Average Kernel
    sumKernel = zeros(1, windowLength);
    kernelCount = 0;
    
    % Sliding window loop
    for j = 1 : kernelLength - windowLength + 1
        newHead = intHead(j : j + windowLength - 1);
        newMSeq = intMSeq(j : j + windowLength - 1);
        
        kernel = fcxcorr(newHead, newMSeq);
        kernel = kernel ./ sqrt((norm(newHead) * norm(newMSeq)));
        kernel = kernel - kernel(1);
        
        % Check if kernel is valid (a kernel will be invalid if all of the
        % m sequence is 0 for that particular interval
        if ~isnan(kernel)
            sumKernel = sumKernel + kernel;
            kernelCount = kernelCount + 1; 
        end
    end
    finalKernel = sumKernel / kernelCount;
    
%   Old sliding window code; above code now does the same thing with
%   downhead files
%
%     % Sum Kernel Generation
%     sumKernel = zeros(1, SEQ_LENGTH);
%     kernelCount = 0;
%     
%     % Loop through interval of interest
%     for j = triggerFrame : step : SEQ_LENGTH * step * (repeats - 1) + 1
%         window = j + 1 : j + step * SEQ_LENGTH;
%         newHead = zeros(1, SEQ_LENGTH);
%         newMSeq = zeros(1, SEQ_LENGTH);
%         headIndex = 1;
%         mSeqIndex = ((j - triggerFrame) / step) * 2 + 1;
%         
%         for k = window(1) : step : window(end)
%             newHead(headIndex) = mean(relativeHeadAngle(k : k + step - 1));
%             headIndex = headIndex + 1;
%         end
%         
%         newMSeq = mSeq(mSeqIndex : mSeqIndex + SEQ_LENGTH - 1);
%         
%         kernel = fcxcorr(newHead, newMSeq) / (norm(newHead) * norm(newMSeq));
%         kernel = kernel - kernel(1);
%         
%         sumKernel = sumKernel + kernel;
%         kernelCount = kernelCount + 1;
%     end
    
    % Add data to kernel data structure
    fileName = expFiles(i).name;
    kernels.data(i).kernel = finalKernel; % Kernel
    flyNum = str2double(regexp(extractBefore(fileName, '_'), '\d*', 'match')); % Fly number
    if length(flyNum) > 1
        kernels.data(i).num = flyNum(1); % New naming convention
    else
        kernels.data(i).num = flyNum; % Old naming convention
    end
    kernels.data(i).genotype = extractBefore(fileName, num2str(kernels.data(i).num)); % Fly genotype (typically PCF)
    
    % Determine fly trial
    checkNewNaming = extractAfter(fileName, strcat(kernels.data(i).genotype, num2str(kernels.data(i).num)));
    if strcmp(checkNewNaming(1:3), 'con') % Check for conserved trial on new naming convention
        kernels.data(i).trial = -1; % -1 means the trial is conserved
    elseif strcmp(checkNewNaming(1), 'T') % Check for numbered trial on new naming convention
        kernels.data(i).trial = str2double(extractBefore(extractAfter(checkNewNaming, 'T'), '_'));
    else % Old naming convention
        trialName = extractAfter(fileName, 'onlyT');
        if isempty(trialName)
            kernels.data(i).trial = 1; % If trial name is not specified, it is trial 1
        else
            kernels.data(i).trial = str2double(extractBefore(trialName, '_')); % Fly trial
        end
    end
    
    % Add raw data to kernel data structure
    kernels.data(i).rawData = struct();
    kernels.data(i).rawData.head = intHead;
    kernels.data(i).rawData.sequence = intMSeq;
end

%% Calculate Average Kernel
kernels.avgKernel = computeAverageKernel(kernels);
kernels.t = linspace(0, kernels.duration, kernels.windowLength);

end