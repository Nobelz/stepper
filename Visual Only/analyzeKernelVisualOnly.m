function kernels = analyzeKernelVisualOnly(kernelData)
% analyzeKernelVisualOnly.m
% Finds the time to peak, time of decay, and amplitude of visual only
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
kernels = kernelData;
kernel = kernels.avgKernel;
[kernels.stats.ampPeak, timePeak] = max(kernel); % Find max value
kernels.stats.timePeak = kernels.t(timePeak); % Find corresponding time to max

% Find time of decay from peak
decayTimes = kernels.t(kernel <= 0);
timeDecay = decayTimes(decayTimes > kernels.t(timePeak));
kernels.stats.timeDecay = timeDecay(1) - kernels.t(timePeak);
end
