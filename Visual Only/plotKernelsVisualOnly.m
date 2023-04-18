% plotKernelsVisualOnly.m
% Plots the kernel and the average kernel for the visual only trials.
%
% Author: Nobel Zhou
% Date: 7 July 2022
% Version: 1.1
%
% VERSION CHANGELOG:
% - v1.0 (6/21/2022): Initial commit
% - v1.1 (7/7/2022): Added plotting options, added upsampling

%% Define Options
REDO_DOWNSAMPLING = 0; % Set to 1 to regenerate downsampling files
REDO_UPSAMPLING = 0; % Set to 1 to regenerate upsampling files
USE_DOWNSAMPLES = 0; % Set to 0 to use downsamples, and set to 1 to use upsamples
SHOW_BEFORE_KERNEL = 0; % Set to 0 to have kernel start at time 0, and set to 1 to have kernel be generated before time 0 (Note: only works for upsampled data)

REGENERATE_KERNELS = 1; % Set to 1 to regenerate kernels
REANALYZE_KERNELS = 1; % Set to 1 to reanalyze kernels
REFIT_KERNELS = 0; % Set to 1 to refit kernels
SHOW_PLOTS = 1; % Set to 1 to show plots
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
    kernels = generateKernelsVisualOnly(REDO_DOWNSAMPLING, REDO_UPSAMPLING, USE_DOWNSAMPLES, SHOW_BEFORE_KERNEL, windowLength, duration);
else
    load('./visualKernels.mat');
end

%% Analyze Kernels
if REANALYZE_KERNELS || ~isfield(kernels, 'stats')
    kernels = analyzeKernelVisualOnly(kernels);
end

%% Determine Nonlinear Curve Fit
if REFIT_KERNELS || ~isfield(kernels, 'fits')
    kernels = fitKernelVisualOnly(kernels, 0.02);
end

%% Plot Kernels
if SHOW_PLOTS
    figure;
    plotKernel(kernels, 'Visual Intact');
    if SHOW_FITS
        plotFit(kernels);
    end
end

%% Save Kernels
save(char('./visualKernels'), 'kernels');

%% Plot Kernel Function
function plotKernel(kernelData, titleName)
hold on
for i = 1 : length(kernelData.data)
    plot(kernelData.t, kernelData.data(i).kernel, 'color', [1 0 0 .05], 'handlevisibility', 'off');
end
plot(kernelData.t, kernelData.avgKernel, 'r', 'LineWidth', 2);
xlim([0 kernelData.duration]);
ylim([-3 3]);
title(titleName);
ylabel('Gain')
xlabel('Time (s)')
box off

end

%% Plot Curve Fit Function
function plotFit(kernelData)
% Plots the fitted curve.

tauRise = kernelData.fits.tauRise;
tauDecay = kernelData.fits.tauDecay;
AAC = kernelData.fits.AAC;
tOnset = kernelData.fits.tOnset;
tauStep = kernelData.fits.tauStep;
t = kernelData.t;

onset = tOnset - t;
stepTerm = 1 + exp(onset ./ tauStep);
riseTerm = exp(onset ./ tauRise);
decayTerm = exp(onset ./ tauDecay);

fitEquation = AAC .* (riseTerm - decayTerm) ./ stepTerm;
riseEquation = AAC .* riseTerm ./ stepTerm;
decayEquation = AAC .* -decayTerm ./ stepTerm;


plot(kernelData.t, riseEquation, 'g');
plot(kernelData.t, decayEquation, 'b');
plot(kernelData.t, fitEquation, 'k');


end


