function kernels = fitKernelVisualOnly(kernelData, startPoint)
% fitKernelVisualOnly.m
% Fits the visual only kernels to a nonlinear, overdamped harmonic 
% oscillator curve.
%
% Inputs:
%   - kernelData: the kernel data to fit
%   - startPoint: where the fit should start
%
% Author: Nobel Zhou
% Date: 7 July 2022
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (7/7/2022): Initial commit

%% Set Default Values
if nargin < 2
    startPoint = 0;
end

%% Find Data
kernels = kernelData;
kernel = kernels.avgKernel;
t = kernels.t;

%% Curve Fit Function
func = @(x) sseval(x, t(t >= startPoint), kernel(t >= startPoint));

% Give good estimates for parameters
startingValues = [0.5 0.01 0.43 0.03];

% No longer needed: random values for parameters are not a good estimate
% startingValues = rand(4, 1);

% Use fminsearch to determine best fitting parameters
fits = fminsearch(func, startingValues); 

%% Add Fitted Parameters to Kernel Data Structure
kernels.fits.tauRise = fits(1);
kernels.fits.tauDecay = fits(2);
kernels.fits.AAC = fits(3);
kernels.fits.tOnset = fits(4);
kernels.fits.tauStep = 0.01;

%% Define Function for Nonlinear Curve
function sse = sseval(params, t, y)
% Function for the nonlinear curve fit

tauStep = 0.01;

tauRise = params(1);
tauDecay = params(2);
AAC = params(3);
tOnset = params(4);

onset = tOnset - t;
stepTerm = 1 + exp(onset ./ tauStep);
riseTerm = exp(onset ./ tauRise);
decayTerm = exp(onset ./ tauDecay);

fitEquation = AAC .* (riseTerm - decayTerm) ./ stepTerm;

sse = sum((y - fitEquation).^2); % Sum of squares
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
end
