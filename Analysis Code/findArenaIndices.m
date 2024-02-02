function [indices, rate] = findArenaIndices(data)
% findArenaIndices.m
% Returns the indices signifying each step of the arena.
%
% Inputs:
%   - data: the arena channel data
%
% Author: Nobel Zhou
% Date: 14 December 2023
% Version: 
%
% VERSION CHANGELOG:
% - v0.1 (12/14/2023): Initial commit

    %% Constants
    STARTING_RATE = 51; % Base estimates off of estimate of 51Hz
    FPS = 600;
    DAQ_RATE = 10000;
    SEQ_LENGTH = 255; % Whatever the length of the m-sequence is (255 * 3 for me)

    %% Find Arena Indices
    arenaData = data.data.arena;
    
    % Create set of rates to experimentally determine the arena rate,
    % centered around the starting rate
    arenaRate = DAQ_RATE / STARTING_RATE - 5 : 0.1 : DAQ_RATE / STARTING_RATE + 5;
    
    timescales = struct(); % Create struct to store timescales for each rate
    for i = 1 : length(arenaRate)
        temp = struct();
        temp.arenaRate = arenaRate(i); % Store arena rate, in samples, where each sample is 1/10000th of a second
        testIndices = zeros(1, round((SEQ_LENGTH * 3 + 1) * arenaRate(i) - 1));
        for j = 1 : SEQ_LENGTH * 3
            index = round(arenaRate(i) * j); % Determine step index and round to nearest whole number
            testIndices(index : end) = data.funcV(j) + testIndices(index : end); % Effectively perform step-wise cumsum 
        end

        temp.t = testIndices; % Add to temp struct
        timescales.timescales(i) = temp; % Add to struct array
    end
    timescales = timescales.timescales; % Reformat struct array
    
    rate = STARTING_RATE;

    % Make arrays to store the fidelity and properties of
    % cross-correlations
    shifts = zeros(1, length(timescales));
    strengths = zeros(1, length(timescales));
    
    % Create low-pass filter to attempt to reduce noise in the kernel
    lowPassFilter = fir1(60, rate / (DAQ_RATE / 2), 'low'); % Nyquist frequency is half of sampling rate
    filtered = filter(lowPassFilter, 1, arenaData); % Apply filter
    
    filtered = filtered(101 : end); % Get rid of weird spike in the beginning

    % Normalize arena data so it is more likely to be tolerated by
    % cross-correlation
    normalizedArenaData = filtered - filtered(1); % Normalize to 0
    normalizedArenaData = normalizedArenaData / max(normalizedArenaData) * max(timescales(1).t); % Make magnitudes match up
    
    % Perform for each experimental rate
    for i = 1 : length(timescales)
        [cc, lags] = xcorr(timescales(i).t, normalizedArenaData - normalizedArenaData(1)); % Find the lags and cross-correlation
        [strength, lagIndex] = max(cc); % Take the max-cross correlation
        
        % Find number to shift the m-sequence by
        shifts(i) = -lags(lagIndex) + 100; % Add 100 to account for us removing 100 to get rid of that spike earlier
        strengths(i) = strength; % Determine strength of cross-correlation
    end

    [~, bestIndex] = max(strengths); % Determine index of best cross-correlation
    timescale = timescales(bestIndex).t;

    indices = find(abs(diff(timescale))) + shifts(bestIndex) - 1;
    indices(end + 1) = indices(end) + (indices(end) - indices(end - 1)); % Add final index for wrapping around
    rate = DAQ_RATE / arenaRate(bestIndex); % Experimentally determined arena rate
end