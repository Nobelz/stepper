% stepperAnalysis.m
% Generates a kernels from ALL data collected during Stepper 2.0.
%
% Author: Nobel Zhou
% Date: 15 September 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (9/15/2023): Initial commit

clc;
close all;

%% Define Constants
RESET_FLIES = 0; % 1 to pull videos from the directory again (do this if videos have been added)
DATA_DIR = '../../Stepper Data/Analyzed Data';

%% Find Files
checkFlies = dir('./flies.mat');

if isempty(checkFlies) || RESET_FLIES
    fileList = assembleFileList(DATA_DIR); % Pull videos if not found
    flies = assembleFlyDirectory(fileList, 1); % Create fly structs
else
    load('./flies.mat');
end

%% Condition-Dependent Analysis
kernels = struct(); % Create struct storing all kernels
j = 0; % Stores the index of kernel array (may not be the same as i due to linearity trials)

for i = 1 : length(flies)
    j = j + 1; % Increment kernel array index
    temp = struct(); % Create temporary struct to store kernel data for one trial

    temp.flyNum = flies(i).flyNum;
    temp.condition = flies(i).condition;
    temp.flyTrial = flies(i).flyTrial;
    
    switch (flies(i).condition)
        case {'StepperOnlyAllOn', 'StepperOnlyStripes'} % Stepper-only trials
            temp.kernel = kernelStepperOnly(flies(i));
            kernels.kernels(j) = temp;
        case 'ArenaOnly' % Arena-only trials
            temp.kernel = kernelArenaOnly(flies(i));
            kernels.kernels(j) = temp;
        otherwise
            j = j - 1;
    end
end

kernels = kernels.kernels;

%% Final Analysis
allOnKernel = zeros(1, 3060);
stripesKernel = zeros(1, 3060);

minLength = 3060;
for i = 1 : length(kernels)
    if strcmp(kernels(i).condition, 'ArenaOnly')
        minLength = min(minLength, length(kernels(i).kernel));
    end
end
arenaKernel = zeros(1, minLength);


countAllOn = 0;
countStripes = 0;
countArena = 0;

for i = 1 : length(kernels)
    if strcmp(kernels(i).condition, 'StepperOnlyAllOn')
        allOnKernel = allOnKernel + kernels(i).kernel;
        countAllOn = countAllOn + 1;
    elseif strcmp(kernels(i).condition, 'StepperOnlyStripes')
        stripesKernel = stripesKernel + kernels(i).kernel;
        countStripes = countStripes + 1;
    else
        arenaKernel = arenaKernel + kernels(i).kernel(1 : minLength);
        countArena = countArena + 1;
    end
end

allOnKernel = allOnKernel / countAllOn;
stripesKernel = stripesKernel / countStripes;
arenaKernel = arenaKernel / countArena;

%% Plot Final Kernels
figure;
subplot(3, 1, 1);
plot(linspace(0, 1, 601), allOnKernel(1 : 601));
title('Stepper All On Kernel');
xlabel('Time (s)');
ylabel('Gain (Degrees)');
xlim([0 1]);
ylim([0 3]);

subplot(3, 1, 2);
plot(linspace(0, 1, 601), stripesKernel(1 : 601));
title('Stepper Stripes Kernel');
xlabel('Time (s)');
ylabel('Gain (Degrees)');
xlim([0 1]);
ylim([0 3]);

subplot(3, 1, 3);
plot(linspace(0, 1, 601), arenaKernel(1 : 601));
title('Arena Kernel');
xlabel('Time (s)');
ylabel('Gain (Degrees)');
xlim([0 1]);
ylim([0 3]);
