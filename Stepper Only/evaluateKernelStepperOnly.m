function kernels = evaluateKernelStepperOnly(kernelData, checkAll)
% evaluateKernelStepperOnly.m
% Determines if individual kernels are "good".
%
% Inputs:
%   - kernelData: the kernel data to check
%   - checkAll: (1) whether to check all of the kernels, or (0) to only
%               check the new kernels
%
% Author: Nobel Zhou
% Date: 6 March 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (3/6/2023): Initial commit

close all
kernels = kernelData;
recheck = 0; % Stores whether incorrect data was entered and a recheck is necessary

% Loop through each kernel data
for i = 1 : length(kernelData.data)
    kernel = kernelData.data(i).kernel;
    figure;
    plot(kernels.t, kernel); % Plot kernel

    % Check if goodness needs to be evaluated
    if checkAll || ~isfield(kernelData.data(i), 'goodness')
        % Ask experimenter for "goodness" determination
        goodness = input('Good Data? 1 for yes, 0 for no: ');
        if goodness == 1
            kernels.data(i).goodness = 1;
        elseif goodness == 0
            kernels.data(i).goodness = 0;
        else
            recheck = 1;
        end
    end
    close all
end

% Check if recheck is necessary
if recheck
    kernels = evaluateKernelStepperOnly(kernels, 0);
end

end