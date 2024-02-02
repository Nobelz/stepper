function finalKernel = kernelBimodal(data)
% kernelBimodal.m
% Returns the kernel for the bimodal trials, excluding bimodal random trials.
% Warning: this is only implemented for 50Hz, as I was too lazy to make it
% compatible for 25Hz. 
%
% Inputs:
%   - data: the formatted trial data
%
% Author: Nobel Zhou
% Date: 13 December 2023
% Version: 
%
% VERSION CHANGELOG:
% - v0.1 (12/13/2023): Initial commit
   
    %% Constants
    FPS = 600; 
    rateS = 50;
    DAQ_RATE = 10000;
    SEQ_LENGTH = 255; % Whatever the length of the m-sequence is (255 * 3 for me)
    
    %% Find Camera and Stepper Firing
    % Find camera firing
    cameraData = data.data.camera;
    cameraIndices = findCameraIndices(cameraData); 

    % Find stepper firing
    stepperData = data.data.stepper;
    stepperIndices = findStepperIndices(stepperData);

    %% Find first actual step
    % Look at arena channel for trigger
    arenaData = data.data.arena;
    
    % Create set of rates to experimentally determine the arena rate,
    % centered around 51 Hz
    arenaRate = DAQ_RATE / 51 - 5 : 0.1 : DAQ_RATE / 51 + 5;
    
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
    
    rateV = 51;

    % Make arrays to store the fidelity and properties of
    % cross-correlations
    shifts = zeros(1, length(timescales));
    strengths = zeros(1, length(timescales));
    
    % Create low-pass filter to attempt to reduce noise in the kernel
    lowPassFilter = fir1(60, rateV / (DAQ_RATE / 2), 'low'); % Nyquist frequency is half of sampling rate
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
    
    rateV = DAQ_RATE / arenaRate(bestIndex); % Experimentally determined arena rate
    cameraRate = FPS / rateV;
    
    %% Generate Camera M-Sequence
    triggerData = fastecMarkerReader([data.pmFile.folder filesep data.pmFile.name], 6); % Get trigger information of the camera
    firstTrigger = find(diff(triggerData == 1), 1);
    
    cameraMSeq = zeros(1, length(data.bodyAngles));
    cameraMSeq(firstTrigger) = data.funcV(1);

    for i = 1 : SEQ_LENGTH * 3 - 1
        cameraMSeq(round(firstTrigger + cameraRate * i)) = data.funcV(i + 1);
    end

    %% Find Camera M-Sequence
    firstIndex = find(cameraMSeq ~= 0, 1, 'first'); % Find first index of change
    lastIndex = find(cameraMSeq ~= 0, 1, 'last'); % Find last index of change
    cameraMSeq = -cameraMSeq(firstIndex : lastIndex + round(cameraRate) - 1); % Find interval of interest
    
    %% Formulate Final Camera M-Sequence and Head Angles
    % Determine relative head angles
    relHeadAngles = data.headAngles - data.bodyAngles;    
    angles = relHeadAngles(firstIndex : lastIndex + round(cameraRate) - 1);
    
    % Transpose m-sequence vector
    cameraMSeq = cameraMSeq';
   
    % Add first elements to end to complete circle
    angles = [angles; angles(1 : SEQ_LENGTH * round(cameraRate) - (length(cameraMSeq) - lastIndex + 1))];
    cameraMSeq = [cameraMSeq; cameraMSeq(1 : SEQ_LENGTH * round(cameraRate) - (length(cameraMSeq) - lastIndex + 1))];

    %% Generate Kernel
    kernelLength = round(SEQ_LENGTH * FPS / (DAQ_RATE / arenaRate(bestIndex))); % Kernel length is whatever the sequence length is times the number of frames for each step    
    sumKernel = zeros(1, kernelLength);
    kernelCount = 0;
    
    % Transpose matrices
    angles = angles';
    cameraMSeq = cameraMSeq';

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
     
    finalKernel = finalKernel';

    % Todo remove
    plot(finalKernel);
    drawnow;
end