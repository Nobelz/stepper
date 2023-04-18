function kernels = fitKernelStepperOnly(kernelData)
% fitKernelStepperOnly.m
% Fits the stepper only kernels to a nonlinear, overdamped harmonic 
% oscillator curve.
%
% Inputs:
%   - kernelData: the kernel data to fit
%
% Author: Nobel Zhou
% Date: 27 February 2023
% Version: 1.1
%
% VERSION CHANGELOG:
% - v0.1 (6/30/2022): Initial commit
% - v0.2 (7/6/2022): Removed DC terms, changed to a function
% - v1.0 (2/21/2023): Changed to Curve Fitter Toolbox, added DC term back
% - v1.1 (2/27/2023): Changed to fit individual trials, removed start point

%% Find Data
kernels = kernelData;
time = kernels.t;

for i = 1 : length(kernelData.data)
    kernel = kernels.data(i).kernel;
    
    disp(append('Fitting Trial ', num2str(i), ' of ', num2str(length(kernelData.data)), '...'))
    %% Curve Fit Function
    try 
        [fit, gof] = createFit(time, kernel);
        
    
        % No longer needed: now we use Curve Fitter Toolbox to provide better fits
        % than fminsearch
        % func = @(x) sseval(x, t(t >= startPoint), kernel(t >= startPoint));
        % 
        % % Give good estimates for parameters
        % startingValues = [0.2 0 2 0];
        
        % No longer needed: random values for parameters are not a good estimate
        % startingValues = rand(4, 1);
        
        % % Use fminsearch to determine best fitting parameters
        % fits = fminsearch(func, startingValues); 
        
        %% Add Fitted Parameters to Kernel Data Structure
        
        % No longer needed: Use Curve Fitter Toolbox
        % kernels.fits.tauRise = fits(1);
        % kernels.fits.tauDecay = fits(2);
        % kernels.fits.AAC = fits(3);
        % kernels.fits.tOnset = fits(4);
        % kernels.fits.tauStep = 0.01;
        
        % No longer used: now fitting for each trial
        % kernels.fits.fit = fit;
        % kernels.fits.params.tauRise = fit.r;
        % kernels.fits.params.tauDecay = fit.d;
        % kernels.fits.params.tauDC = fit.c;
        % kernels.fits.params.AAC = fit.A;
        % kernels.fits.params.ADC = fit.D;
        % kernels.fits.params.tOnset = fit.t;
        % kernels.fits.params.tauStep = fit.s;
        % kernels.fits.params.tDC = fit.T;
        % kernels.fits.gof = gof;
    
        kernels.data(i).fits.fit = fit;
        kernels.data(i).fits.params.tauRise = fit.r;
        kernels.data(i).fits.params.tauDecay = fit.d;
        kernels.data(i).fits.params.tauDC = fit.c;
        kernels.data(i).fits.params.AAC = fit.A;
        kernels.data(i).fits.params.ADC = fit.D;
        kernels.data(i).fits.params.tOnset = fit.t;
        kernels.data(i).fits.params.tauStep = fit.s;
        kernels.data(i).fits.params.tDC = fit.T;
        kernels.data(i).fits.gof = gof;
    catch ME
        disp(append('Trial ', num2str(i), ' failed. Need manual fit'));
    end
end


%% Define Function for Nonlinear Curve
% RETIRED
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
end
