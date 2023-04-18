function kernels = generateKernelsStepperOnly(folderName, redoDownSampling, redoUpSampling, useDownSamples, showBeforeKernel, windowLength, duration)
% generateKernelsStepperOnly.m
% Generates a "kernel" for stepper only trials.
%
% Inputs:
%   - folderName: the name of the folder to be analyzed
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
% Version: 1.1.1
%
% VERSION CHANGELOG:
% - v0.1 (6/5/2022): Initial commit
% - v0.2: (6/21/2022): Added repeats and step, removed dependency on DOWNHEAD files
% - v1.0: (6/28/2022) Fixed downsampling, adjusted window length, it finally works!
% - v1.1 (6/30/2022): Added options as parameters for the function
% - v1.1.1 (7/6/2022): Added duration as a parameter; changed kernel data
%       structure layout

close all

%% Define Constants
PATH = './Data/';
SEQ_LENGTH = 127;
REPEATS = 3;
DEG_PER_STEP = 3.75;

%% Find Files
% Add folder name to path
addpath(strcat(PATH, folderName));

% Get experiment files, proc, and marker files
expFiles = dir(strcat(PATH, folderName, '/*Hz*.mat'));
downheadFiles = dir(strcat(PATH, folderName, '/*_DOWNHEAD.mat'));
upheadBeforeFiles = dir(strcat(PATH, folderName, '/*_UPHEAD_BEFORE.mat'));
upseqBeforeFiles = dir(strcat(PATH, folderName, '/*_UPSEQ_BEFORE.mat'));
upheadNowFiles = dir(strcat(PATH, folderName, '/*_UPHEAD_NOW.mat'));
upseqNowFiles = dir(strcat(PATH, folderName, '/*_UPSEQ_NOW.mat'));

% Check if videos have been downsampled
if length(downheadFiles) < length(expFiles) || redoDownSampling
    disp(append('Downsampling files for ', folderName, '...'));
    downsampleStepperOnly(folderName);
    disp('Done downsampling files.');
    downheadFiles = dir(strcat(PATH, folderName, '/*_DOWNHEAD.mat')); % Reload downhead files
end

% Check if videos have been upsampled
if length(upheadBeforeFiles) < length(expFiles) || redoUpSampling
    disp(append('Upsampling files for ', folderName, '...'));
    upsampleStepperOnly(folderName);
    disp('Done upsampling files.');
    
    % Reload upsampled files
    upheadBeforeFiles = dir(strcat(PATH, folderName, '/*_UPHEAD_BEFORE.mat'));
    upseqBeforeFiles = dir(strcat(PATH, folderName, '/*_UPSEQ_BEFORE.mat'));
    upheadNowFiles = dir(strcat(PATH, folderName, '/*_UPHEAD_NOW.mat'));
    upseqNowFiles = dir(strcat(PATH, folderName, '/*_UPSEQ_NOW.mat'));
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
disp(append('Found ', num2str(length(expFiles)), ' files in ', folderName));
for i = 1 : length(expFiles)
    disp(append('Evaluating File ', num2str(i), ' of ', num2str(length(expFiles)), ': ', expFiles(i).name));
    
    % Load files
    load(expFiles(i).name);
    load(downheadFiles(i).name);
    load(upheadFiles(i).name);
    load(upseqFiles(i).name);
    
    % Downsampling condition
    if useDownSamples
        % Extract m sequence and head angles
        mSeq = exp.step_seq * DEG_PER_STEP;
        kernelLength = SEQ_LENGTH * 2 * REPEATS;
        intMSeq = mSeq(1 : kernelLength);
        intHead = downhead;
    else
        % Extract m sequence and head angles
        kernelLength = length(upseq);
        intMSeq = upseq;
        intHead = uphead;
    end
    
    % Calculate Average Kernel
    sumKernel = zeros(1, windowLength);
    kernelCount = 0;
    
    % Sliding window loop
    for j = 1 : kernelLength - windowLength + 1
        newHead = intHead(j : j + windowLength - 1);
        newMSeq = intMSeq(j : j + windowLength - 1);
        
        kernel = fcxcorr(newHead, newMSeq) ./ sqrt(norm(newHead) * norm(newMSeq));
%       No longer needed: above fcxcorr does the same thing as this but
%       faster
%         kernel = cconv(newHead, conj(fliplr(newMSeq)), seqLength * 2);
%         kernel = kernel ./ (norm(newHead) * norm(newMSeq));
        kernel = kernel - kernel(1);
        
        % Check if kernel is valid (a kernel will be invalid if all of the
        % m sequence is 0 for that particular interval
        if ~isnan(kernel)
            sumKernel = sumKernel + kernel;
            kernelCount = kernelCount + 1; 
        end
    end
    finalKernel = sumKernel / kernelCount;

    % Add data to kernel data structure
    fileName = expFiles(i).name;
    kernels.data(i).kernel = finalKernel; % Kernel
    kernels.data(i).num = str2double(regexp(extractBefore(fileName, 'Stepper'), '\d*', 'match')); % Fly number
    kernels.data(i).genotype = extractBefore(fileName, num2str(kernels.data(i).num)); % Fly genotype (typically PCF)
    
    % Determine fly trial
    trialName = extractBefore(extractAfter(fileName, '_'), '_');
    if strcmp(trialName, 'con')
        kernels.data(i).trial = -1; % For conserved trials, the trial number is -1
    else
        kernels.data(i).trial = str2double(extractAfter(trialName, 'T')); % Fly trial
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