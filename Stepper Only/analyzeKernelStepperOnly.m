function kernels = analyzeKernelStepperOnly(kernelData)
% analyzeKernelStepperOnly.m
% Finds the time to peak, time of decay, and amplitude of stepper only
% kernels.
%
% Inputs:
%   - kernelData: the kernel data to fit
%
% Author: Nobel Zhou
% Date: 7 July 2022
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (7/7/2022): Initial commit

%% Find Stats
% Old data that found stat of average kernel, not all kernels
% kernels = kernelData;
% kernel = kernels.avgKernel;
% [kernels.stats.ampPeak, timePeak] = max(kernel); % Find max value
% kernels.stats.timePeak = kernels.t(timePeak); % Find corresponding time to max
% 
% tHalfs = find(kernel > kernels.stats.ampPeak / 2);
% kernels.stats.widthHalfPeak = kernels.t(max(tHalfs)) - kernels.t(min(tHalfs));
% 
% % Find time of decay from peak
% decayTimes = kernels.t(kernel <= 0.05);
% timeDecay = decayTimes(decayTimes > kernels.t(timePeak));
% kernels.stats.timeDecay = timeDecay(1) - kernels.t(timePeak);

kernels = kernelData;
for i = 1 : length(kernelData.data)
    kernel = kernelData.data(i).kernel;
    [kernels.data(i).stats.ampPeak, timePeak] = max(kernel); % Find peak amplitude
    kernels.data(i).stats.timePeak = kernels.t(timePeak); % Find time at max peak

    tHalfs = find(kernel > kernels.data(i).stats.ampPeak / 2);
    kernels.data(i).stats.widthHalfPeak = kernels.t(max(tHalfs)) - kernels.t(min(tHalfs));

    % Find time of decay from peak
    decayTimes = kernels.t(kernel <= 0.05);
    timeDecay = decayTimes(decayTimes > kernels.t(timePeak));

    if isempty(timeDecay)
        kernels.data(i).stats.timeDecay = NaN;
    else
        kernels.data(i).stats.timeDecay = timeDecay(1) - kernels.t(timePeak);
    end
end
end
