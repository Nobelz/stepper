function indices = findStepperIndices(data)

% findStepperIndices.m
% Returns the indices signifying each step of the stepper.
%
% Inputs:
%   - data: the square wave stepper channel data
%
% Author: Nobel Zhou
% Date: 2 October 2023
% Version: 
%
% VERSION CHANGELOG:
% - v0.1 (10/2/2023): Initial commit

    % Use find peaks to find general square wave location
    [~, indices] = findpeaks(data, 'MinPeakHeight', 4);
    
    % Decrement each element of the array so it's at the start of the
    % square wave
    for i = 1 : length(indices)
        j = indices(i);
        while  j > 0 && data(j) > 4 % Keep going until you don't get to the square wave
            j = j - 1;
        end
        j = j + 1;

        indices(i) = j; % Update index
    end

    indices = unique(indices); % Get rid of duplicate values
end