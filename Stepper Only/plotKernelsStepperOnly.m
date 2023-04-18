% plotKernelsStepperOnly.m
% Plots the average kernel for all 4 experiments.
%
% Author: Nobel Zhou
% Date: 27 February 2023
% Version: 1.3
%
% VERSION CHANGELOG:
% - v1.0 (6/9/2022): Initial commit
% - v1.1 (6/30/2022): Moved options from generateKernelsStepperOnly.m to
%       this file
% - v1.2 (7/6/2022): Added fitting curves
% - v1.3 (2/27/2023): Added fitting for individual trials

%% Define Options
REDO_DOWNSAMPLING = 0; % Set to 1 to regenerate downsampling files
REDO_UPSAMPLING = 0; % Set to 1 to regenerate upsampling files
USE_DOWNSAMPLES = 0; % Set to 0 to use downsamples, and set to 1 to use upsamples
SHOW_BEFORE_KERNEL = 0; % Set to 0 to have kernel start at time 0, and set to 1 to have kernel be generated before time 0 (Note: only works for upsampled data)

REGENERATE_KERNELS = 0; % Set to 1 to regenerate kernels
REANALYZE_KERNELS = 1; % Set to 1 to reanalyze/refit kernels
REEVALUATE_KERNELS = 0; % Set to 1 to reevaluate kernels to determine their "goodness"; all kernels without "goodness" determined will automatically be evaluated
SHOW_PLOTS = 0; % Set to 1 to show plots
SHOW_FITS = 0; % Set to 0 to show fits

%% Determine Sliding Window Length
if USE_DOWNSAMPLES
    windowLength = 100;
    duration = 100 / 102;
else
    if SHOW_BEFORE_KERNEL
        windowLength = 900;
        duration = 1.5;
    else
        windowLength = 600;
        duration = 1;
    end
end

%% Generate Kernels
if REGENERATE_KERNELS
    allOnKernels = generateKernelsStepperOnly('AllOn_data', REDO_DOWNSAMPLING, REDO_UPSAMPLING, USE_DOWNSAMPLES, SHOW_BEFORE_KERNEL, windowLength, duration);
    allOnHLKernels = generateKernelsStepperOnly('AllOnHL_data', REDO_DOWNSAMPLING, REDO_UPSAMPLING, USE_DOWNSAMPLES, SHOW_BEFORE_KERNEL, windowLength, duration);
    stripesKernels = generateKernelsStepperOnly('Stripes_data', REDO_DOWNSAMPLING, REDO_UPSAMPLING, USE_DOWNSAMPLES, SHOW_BEFORE_KERNEL, windowLength, duration);
    stripesHLKernels = generateKernelsStepperOnly('StripesHL_data', REDO_DOWNSAMPLING, REDO_UPSAMPLING, USE_DOWNSAMPLES, SHOW_BEFORE_KERNEL, windowLength, duration);
else
    load('./Kernels/allOnKernels.mat');
    load('./Kernels/allOnHLKernels.mat');
    load('./Kernels/stripesKernels.mat');
    load('./Kernels/stripesHLKernels.mat');
end

%% Analyze and Fit Kernels
if REANALYZE_KERNELS
    allOnKernels = analyzeKernelStepperOnly(allOnKernels);
    allOnHLKernels = analyzeKernelStepperOnly(allOnHLKernels);
    stripesKernels = analyzeKernelStepperOnly(stripesKernels);
    stripesHLKernels = analyzeKernelStepperOnly(stripesHLKernels);

    allOnKernels = fitKernelStepperOnly(allOnKernels);
    allOnHLKernels = fitKernelStepperOnly(allOnHLKernels);
    stripesKernels = fitKernelStepperOnly(stripesKernels);
    stripesHLKernels = fitKernelStepperOnly(stripesHLKernels);
end

%% Evaluate Kernels
allOnKernels = evaluateKernelStepperOnly(allOnKernels, REEVALUATE_KERNELS);
allOnHLKernels = evaluateKernelStepperOnly(allOnHLKernels, REEVALUATE_KERNELS);
stripesKernels = evaluateKernelStepperOnly(stripesKernels, REEVALUATE_KERNELS);
stripesHLKernels = evaluateKernelStepperOnly(stripesHLKernels, REEVALUATE_KERNELS);

%% Save Kernels
mkdir 'Kernels'
addpath('./Kernels');
save(char('./Kernels/allOnKernels'), 'allOnKernels');
save(char('./Kernels/allOnHLKernels'), 'allOnHLKernels');
save(char('./Kernels/stripesKernels'), 'stripesKernels');
save(char('./Kernels/stripesHLKernels'), 'stripesHLKernels');

%% Plot Kernels
if SHOW_PLOTS
    figure;
    
    subplot(2, 2, 1);
    plotKernel(allOnKernels, 'All On Intact', SHOW_BEFORE_KERNEL, 'y');
    
    subplot(2, 2, 2);
    plotKernel(allOnHLKernels, 'All On Haltereless', SHOW_BEFORE_KERNEL, 'n');

    subplot(2, 2, 3);
    plotKernel(stripesKernels, 'Stripes Intact', SHOW_BEFORE_KERNEL, 'y');

    subplot(2, 2, 4);
    plotKernel(stripesHLKernels, 'Stripes Haltereless', SHOW_BEFORE_KERNEL, 'n');
end

%% Plot Fits
if SHOW_FITS
    plotFit(allOnKernels, 'All On Intact');
    plotFit(allOnHLKernels, 'All On Haltereless');
    plotFit(stripesKernels, 'Stripes Intact');
    plotFit(stripesHLKernels, 'Stripes Haltereless')
end

%% Plot Kernel Function
function plotKernel(kernelData, titleName, showBeforeKernel, intact)
% Plots the kernel.
hold on
for i = 1 : length(kernelData.data)
    if intact == 'y'
        plot(kernelData.t, kernelData.data(i).kernel, 'color', [1 0 0 .01], 'handlevisibility', 'off');
    else
        plot(kernelData.t, kernelData.data(i).kernel, 'color', [0 0 0 .01], 'handlevisibility', 'off');
    end
end
if intact == 'y'
    plot(kernelData.t, kernelData.avgKernel, 'r', 'LineWidth', 2);
else
    plot(kernelData.t, kernelData.avgKernel, 'k', 'LineWidth', 2);
end

if showBeforeKernel
    plot([0.5 0.5], [-3 3], '--');
end

xlim([0 kernelData.duration]);
ylim([-3 3]);
% title(titleName);
ylabel('Gain')
xlabel('Time (s)')
box off

end

%% Plot Curve Fit Function
function plotFit(kernelData, titleName)
% Plots the fitted curve.

% No longer needed: just plot the fit
% tauRise = kernelData.fits.params.tauRise;
% tauDecay = kernelData.fits.params.tauDecay;
% AAC = kernelData.fits.params.AAC;
% tOnset = kernelData.fits.params.tOnset;
% tauStep = kernelData.fits.params.tauStep;
% 
% time = kernelData.t;
% 
% onset = tOnset - t;
% stepTerm = 1 + exp(onset ./ tauStep);
% riseTerm = exp(onset ./ tauRise);
% decayTerm = exp(onset ./ tauDecay);
% 
% fitEquation = AAC .* (riseTerm - decayTerm) ./ stepTerm;
% riseEquation = AAC .* riseTerm ./ stepTerm;
% decayEquation = AAC .* -decayTerm ./ stepTerm;


% plot(kernelData.t, riseEquation, 'g');
% plot(kernelData.t, decayEquation, 'k');


for i = 1 : length(kernelData.data)
    figure;
    
    % Check if fit exists
    if (~isempty(kernelData.data(i).fits))
        kernel = kernelData.data(i).kernel; % Get kernel data
        scatter(kernelData.t, kernel); % Get time data
        hold on
        p = plot(kernelData.data(i).fits.fit, 'k'); % Plot fit
        p.LineWidth = 1.5;
        xlabel('Time (s)');
        ylabel('Gain');
        title(append(titleName, ': Trial ', num2str(i), ' of ', num2str(length(kernelData.data))));
        legend off
    end
end
end
