function finalKernel = kernelArenaOnly(data)

% kernelArenaOnly.m
% Returns the kernel for the arena only trials.
% Warning: this is only implemented for 50Hz, as I was too lazy to make it
% compatible for 25Hz. 
%
% Inputs:
%   - data: the formatted trial data
%
% Author: Nobel Zhou
% Date: 4 October 2023
% Version: 
%
% VERSION CHANGELOG:
% - v0.1 (10/3/2023): Initial commit
   
    %% Constants
    FPS = 600; 
    rateV = 50;
    DAQ_RATE = 10000;
    SHIFT = 850; % This is a guesstimate of the frame shift from the camera, taken as the average of stepper only trials
    SEQ_LENGTH = 255; % Whatever the length of the m-sequence is (255 * 3 for me)
    SHIFT = 950; % Camera shift, experimentally determined to be 950
    
    %% Find Camera Firing
    cameraData = data.data.camera;
    cameraIndices = findCameraIndices(cameraData); 

    %% Find Arena Steps
    % Look at arena channel for trigger
    arenaData = data.data.arena;
    
    % Create set of rates to experimentally determine the arena rate,
    % centered around 51 Hz
    arenaRate = DAQ_RATE / 51 - 5 : 0.1 : DAQ_RATE / 51 + 5;
    
    timescales = struct(); % Create struct to store timescales for each rate
    for i = 1 : length(arenaRate)
        temp = struct();
        temp.arenaRate = arenaRate(i); % Store arena rate, in samples, where each sample is 1/10000th of a second
        testIndices = zeros(1, round((SEQ_LENGTH * 3 + 1) * arenaRate(i)));
        for j = 1 : SEQ_LENGTH * 3
            index = round(arenaRate(i) * j); % Determine step index and round to nearest whole number
            testIndices(index : end) = data.funcV(j) + testIndices(index : end); % Effectively perform step-wise cumsum 
        end

        temp.t = testIndices; % Add to temp struct
        timescales.timescales(i) = temp; % Add to struct array
    end
    timescales = timescales.timescales; % Reformat struct array
    
    % Make arrays to store the fidelity and properties of
    % cross-correlations
    shifts = zeros(1, length(timescales));
    strengths = zeros(1, length(timescales));
    
    % Create low-pass filter to attempt to reduce noise in the kernel
    lowPassFilter = fir1(60, data.rateV / (DAQ_RATE / 2), 'low'); % Nyquist frequency is half of sampling rate
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
    mSeq = diff(timescales(bestIndex).t); % Change to m-sequence impulses
    mSeq = [zeros(1, shifts(bestIndex) + 1) mSeq]; % Add 1 zero to account for diff taking one data point off and add the shift
    
%     figure;
%     plot(normalizedArenaData);
%     hold on;
%     for i = 1 : length(timescales)
%         plot(-shifts(i): -shifts(i) + length(timescales(i).t) - 1, timescales(i).t);
%     end

    %% Step/Frame Association
    % Determine actual length of m-sequence
    seqLength = sum(mSeq ~= 0); % Get number of non-zero elements
    
    % Determine indices of m-sequence
    arenaIndices = find(mSeq ~= 0);

    % Initialize array for m-sequence
    cameraMSeq = zeros(1, length(data.bodyAngles));

    % Loop for each step of m-sequence
    for i = 1 : seqLength % We get one more than the sequence length so we know when the m-sequence actually ends
        [~, frameIndex] = min(abs(cameraIndices - arenaIndices(i))); % Find the camera index closest to the stepper step
        cameraMSeq(frameIndex) = data.funcV(i); % Store value of m-sequence at that closest camera index
    end

    %% Find Camera M-Sequence
    firstIndex = find(cameraMSeq ~= 0, 1, 'first'); % Find first index of change
    lastIndex = find(cameraMSeq ~= 0, 1, 'last'); % Find last index of change
    cameraMSeq = cameraMSeq(firstIndex : lastIndex + (FPS / rateV) - 1); % Find interval of interest

    %% Formulate Final Camera M-Sequence and Head Angles
    % Determine relative head angles
    relHeadAngles = data.headAngles - data.bodyAngles;
    angles = relHeadAngles(SHIFT : SHIFT + length(cameraMSeq) - 1);
    
    lastIndex = find(cameraMSeq ~= 0, 1, 'last'); % Find last index again
    
    % Transpose m-sequence vector
    cameraMSeq = cameraMSeq';
   
    % Add first elements to end to complete circle
    angles = [angles; angles(1 : SEQ_LENGTH * FPS / rateV - (length(cameraMSeq) - lastIndex + 1))];
    cameraMSeq = [cameraMSeq; cameraMSeq(1 : SEQ_LENGTH * FPS / rateV - (length(cameraMSeq) - lastIndex + 1))];

    % Coder's note: the above does something kinda complex but it's
    % actually pretty simple. For the sliding window, it's a circular
    % correlation so at the end of the m-sequence, I need to wrap around to
    % the front. Now I could do a modulo operator or something funky like
    % that but I chose to just append the beginning of the sequence at the
    % end so I don't have to do that weird math. All of what this does is
    % that it makes sure that there is just enough elements at the end to
    % accomplish this circular cross-correlation. - nxz157, 10/2/2023

    %% Generate Kernel
    kernelLength = SEQ_LENGTH * FPS / rateV; % Kernel length is whatever the sequence length is times the number of frames for each step
    sumKernel = zeros(1, length(kernelLength));
    kernelCount = 0;

    % Sliding window loop
    for j = 1 : length(angles) - kernelLength + 1
        newHead = angles(j : j + kernelLength - 1);
        newSeq = cameraMSeq(j : j + kernelLength - 1);
        
        kernel = fcxcorr(newHead, newSeq) ./ sqrt(norm(newHead) * norm(newSeq)); % Conserved kernel calculation from previous research
        kernel = kernel - kernel(1);
        
        % Check if kernel is valid (a kernel will be invalid if all of the
        % m sequence is 0 for that particular interval
        if ~isnan(kernel)
            sumKernel = sumKernel + kernel;
            kernelCount = kernelCount + 1; 
        end
    end
    finalKernel = sumKernel / kernelCount;
    
end