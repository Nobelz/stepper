% linearityAnalysis.m
% Performs linearity analysis.
%
% Author: Nobel Zhou
% Date: 29 March 2024
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (3/29/2023): Initial commit

clc;
close all;

%% Define Constants
RESET_FLIES = 0; % 1 to pull videos from the directory again (do this if videos have been added or if running from different computer)
DATA_DIR = '../../Stepper Data/Analyzed Data';

%% Find Files
checkFlies = dir('./flies.mat');

if isempty(checkFlies) || RESET_FLIES
    fileList = assembleFileList(DATA_DIR); % Pull videos if not found
    flies = assembleFlyDirectory(fileList, 1); % Create fly structs
else
    load('./flies.mat');
end

%% Run Analysis
linearityData = struct();
j = 1;
for i = 1 : length(flies)
    if strcmp('TestLinearity', flies(i).condition)
        linearityData.trials(j) = kernelLinearity(flies(i));
        j = j + 1;
    end
end

%% Final Analysis
num = 0;
allOnKernel = zeros(1, 600);
allOn2Kernel = zeros(1, 600);
stripesKernel = zeros(1, 600);
stripes2Kernel = zeros(1, 600);
for i = 1 : length(linearityData.trials)
    leftAllOnKernel = linearityData.trials(i).allOn.left.trial1;
    rightAllOnKernel = linearityData.trials(i).allOn.right.trial1;
    
    leftAllOn2Kernel = linearityData.trials(i).allOn.left.trial4;
    rightAllOn2Kernel = linearityData.trials(i).allOn.right.trial4;

    leftStripesKernel = linearityData.trials(i).stripes.left.trial1;
    rightStripesKernel = linearityData.trials(i).stripes.right.trial1;

    leftStripes2Kernel = linearityData.trials(i).stripes.left.trial4;
    rightStripes2Kernel = linearityData.trials(i).stripes.right.trial4;

    allOnKernel = allOnKernel + leftAllOnKernel - rightAllOnKernel;
    allOn2Kernel = allOn2Kernel + leftAllOn2Kernel - rightAllOn2Kernel;

    stripesKernel = stripesKernel + leftStripesKernel - rightStripesKernel;
    stripes2Kernel = stripes2Kernel + leftStripes2Kernel - rightStripes2Kernel;
end

allOn2Kernel = allOn2Kernel / length(linearityData.trials) / 2;
allOnKernel = allOnKernel / length(linearityData.trials) / 2;
stripes2Kernel = stripes2Kernel / length(linearityData.trials) / 2;
stripesKernel = stripesKernel / length(linearityData.trials) / 2;

figure; hold on;
plot(allOnKernel);
plot(allOn2Kernel);

figure; hold on;
plot(stripesKernel);
plot(stripes2Kernel);