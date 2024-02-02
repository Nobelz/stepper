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

%% Condition-Dependent Analysis
kernels = struct(); % Create struct storing all kernels
j = 0; % Stores the index of kernel array (may not be the same as i due to linearity trials)

for i = 1 : length(flies)
    j = j + 1; % Increment kernel array index
    temp = struct(); % Create temporary struct to store kernel data for one trial

    temp.flyNum = flies(i).flyNum;
    temp.condition = flies(i).condition;
    temp.flyTrial = flies(i).flyTrial;
    
    disp(i);
    disp(flies(i).condition);
    switch (flies(i).condition)
        case {'StepperOnlyAllOn', 'StepperOnlyStripes'} % Stepper-only trials
            temp.stepperKernel = kernelStepperOnly(flies(i));
            temp.arenaKernel = [];
            kernels.kernels(j) = temp;
        case 'ArenaOnly' % Arena-only trials
            temp.arenaKernel = kernelArenaOnly(flies(i));
            temp.stepperKernel = [];
            kernels.kernels(j) = temp;
        case {'BimodalCoherent', 'BimodalOpposing'} % Bimodal trials
            [temp.arenaKernel, temp.stepperKernel] = kernelBimodal(flies(i));
            kernels.kernels(j) = temp;
        case 'BimodalRandom' % Bimodal random trials
            [temp.arenaKernel, temp.stepperKernel] = kernelRandom(flies(i));
            kernels.kernels(j) = temp;
        otherwise
            j = j - 1;
    end
end

kernels = kernels.kernels;
save('kernels', 'kernels');

%% Final Analysis
allOnKernel = zeros(1, 3060);
stripesKernel = zeros(1, 3060);

minArenaLength = 3060;
minCoherentLength = 3060;
minOpposingLength = 3060;
minRandomStepperLength = 3060;
minRandomVisualLength = 3060;

for i = 1 : length(kernels)
    if strcmp(kernels(i).condition, 'ArenaOnly')
        minArenaLength = min(minArenaLength, length(kernels(i).arenaKernel));
    elseif strcmp(kernels(i).condition, 'BimodalCoherent')
        minCoherentLength = min(minCoherentLength, length(kernels(i).stepperKernel));
    elseif strcmp(kernels(i).condition, 'BimodalOpposing')
        minOpposingLength = min(minOpposingLength, length(kernels(i).stepperKernel));  
    elseif strcmp(kernels(i).condition, 'BimodalRandom')
        minRandomStepperLength = min(minRandomStepperLength, length(kernels(i).stepperKernel));
        minRandomVisualLength = min(minRandomVisualLength, length(kernels(i).arenaKernel));
    end
end

arenaKernel = zeros(minArenaLength, 1);
coherentKernel = zeros(minCoherentLength, 1);
opposingKernel = zeros(minOpposingLength, 1);
randomStepperKernel = zeros(minRandomStepperLength, 1);
randomVisualKernel = zeros(minRandomVisualLength, 1);

countAllOn = 0;
countStripes = 0;
countArena = 0;
countCoherent = 0;
countOpposing = 0;
countRandom = 0;

for i = 1 : length(kernels)
    if kernels(i).flyTrial > 0
        if strcmp(kernels(i).condition, 'StepperOnlyAllOn')
            allOnKernel = allOnKernel + kernels(i).stepperKernel;
            countAllOn = countAllOn + 1;
        elseif strcmp(kernels(i).condition, 'StepperOnlyStripes')
            stripesKernel = stripesKernel + kernels(i).stepperKernel;
            countStripes = countStripes + 1;
        elseif strcmp(kernels(i).condition, 'ArenaOnly')
            arenaKernel = arenaKernel + kernels(i).arenaKernel(1 : minArenaLength);
            countArena = countArena + 1;
        elseif strcmp(kernels(i).condition, 'BimodalCoherent')
            coherentKernel = coherentKernel + kernels(i).stepperKernel(1 : minCoherentLength);
            countCoherent = countCoherent + 1;
        elseif strcmp(kernels(i).condition, 'BimodalOpposing')
            opposingKernel = opposingKernel + kernels(i).stepperKernel(1 : minOpposingLength);
            countOpposing = countOpposing + 1;
        elseif strcmp(kernels(i).condition, 'BimodalRandom')
            randomStepperKernel = randomStepperKernel + kernels(i).stepperKernel(1 : minRandomStepperLength);
            randomVisualKernel = randomVisualKernel + kernels(i).arenaKernel(1 : minRandomVisualLength);
            countRandom = countRandom + 1;
        end
    end
end

allOnKernel = allOnKernel / countAllOn;
stripesKernel = stripesKernel / countStripes;
arenaKernel = arenaKernel / countArena;
coherentKernel = coherentKernel / countCoherent;
opposingKernel = opposingKernel / countOpposing;
randomVisualKernel = randomVisualKernel / countRandom;
randomStepperKernel = randomStepperKernel / countRandom;

%% Plot Final Kernels
figure;
subplot(4, 1, 1);
plot(linspace(0, 1, 601), allOnKernel(1 : 601));
title('Stepper All On Kernel');
xlabel('Time (s)');
ylabel('Gain (Degrees)');
xlim([0 1]);
ylim([0 3]);

subplot(4, 1, 2);
plot(linspace(0, 1, 601), stripesKernel(1 : 601));
title('Stepper Stripes Kernel');
xlabel('Time (s)');
ylabel('Gain (Degrees)');
xlim([0 1]);
ylim([0 3]);

subplot(4, 1, 3);
plot(linspace(0, 1, 601), coherentKernel(1 : 601));
title('Coherent Kernel');
xlabel('Time (s)');
ylabel('Gain (Degrees)');
xlim([0 1]);
ylim([0 3]);

subplot(4, 1, 4);
plot(linspace(0, 1, 601), opposingKernel(1 : 601));
title('Opposing Kernel');
xlabel('Time (s)');
ylabel('Gain (Degrees)');
xlim([0 1]);
ylim([0 3]);

figure;
subplot(3, 1, 1);
plot(linspace(0, 1, 601), randomStepperKernel(1 : 601));
title('Random Stepper Kernel');
xlabel('Time (s)');
ylabel('Gain (Degrees)');
xlim([0 1]);
ylim([0 3]);

subplot(3, 1, 2);
plot(linspace(0, 1, 601), randomVisualKernel(1 : 601));
title('Random Visual Kernel');
xlabel('Time (s)');
ylabel('Gain (Degrees)');
xlim([0 1]);
ylim([-3 0]);

subplot(3, 1, 3);
plot(linspace(0, 1, 601), arenaKernel(1 : 601));
title('Arena Kernel');
xlabel('Time (s)');
ylabel('Gain (Degrees)');
xlim([0 1]);
ylim([0 3]);
