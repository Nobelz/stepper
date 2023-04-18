function avgKernel = computeAverageKernel(kernelData)
% computeAverageKernel.m
% Generates average kernel for all data with random M sequences.
% Author: Nobel Zhou
% Date: 6 July 2022
% Version: 1.0
%
% VERSION CHANGELOG:
% - v1.0 (7/6/2022): Initial commit

% Initialize sum kernel to empty matrix
sumKernel = zeros(1, kernelData.windowLength);

for i = 1 : length(kernelData.data)
    sumKernel = sumKernel + kernelData.data(i).kernel; % Add kernel to sum
end    
avgKernel = sumKernel / length(kernelData.data); % Determine average by dividing sum by count

end