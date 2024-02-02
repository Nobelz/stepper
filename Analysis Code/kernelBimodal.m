function [visualKernel, stepperKernel] = kernelBimodal(data)
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
    DAQ_RATE = 10000;
    SEQ_LENGTH = 255; % Whatever the length of the m-sequence is (255 * 3 for me)
    
    %% Find Camera Firing
    % Find camera firing
    cameraData = data.data.camera;
    cameraIndices = findCameraIndices(cameraData); 

    %% Find first actual step
    [arenaIndices, rateV] = findArenaIndices(data);
    rateS = rateV;

    % Find first stepper index
    stepperStartData = data.data.stepperStart;
    firstArenaStep = find(diff(stepperStartData) > 3) + 1;

    % Align arena indices so they begin at firstArenaStep
    arenaIndices = arenaIndices - (arenaIndices(1) - firstArenaStep);
    
    %% Step/Frame Association
    % Determine actual length of m-sequence
    mSeq = data.funcS;
    seqLength = sum(mSeq ~= 0); % Get number of non-zero elements

    % Make array of upsampled m-sequence
    cameraMSeq = zeros(1, length(data.bodyAngles));

    % Loop for each step of m-sequence
    for i = 1 : seqLength + 1 % We get one more than the sequence length so we know when the m-sequence actually ends
        [~, frameIndex] = min(abs(cameraIndices - arenaIndices(i))); % Find the camera index closest to the stepper step
        if i == seqLength + 1
            cameraMSeq(frameIndex) = 100; % Store temp value to indicate end of m-sequence
        else
            cameraMSeq(frameIndex) = mSeq(i); % Store value of m-sequence at that closest camera index
        end
    end

    %% Find Camera M-Sequence
    firstIndex = find(cameraMSeq ~= 0, 1, 'first'); % Find first index of change
    lastIndex = find(cameraMSeq ~= 0, 1, 'last'); % Find last index of change
    cameraMSeq = cameraMSeq(firstIndex : lastIndex); % Find interval of interest
    cameraMSeq = cameraMSeq(1 : end - 1); % Get rid of final trigger

    %% Frame/Camera Association
    % Upsample m-sequence to match camera sampling rate
    corrBodyAngles = -data.bodyAngles;
    corrMSeq = cumsum(cameraMSeq);
    
    % Cross correlate m-sequence and angles to find sequence begin time
    [cc, lags] = xcorr(corrMSeq, corrBodyAngles); % Find the lags and cross-correlation
    [~, lagIndex] = max(cc); % Take the max-cross correlation
    
    % Find number to shift the camera by
    shift = -lags(lagIndex);

    %% Formulate Final Camera M-Sequence and Head Angles
    % Determine relative head angles
    relHeadAngles = data.headAngles - data.bodyAngles;
    angles = relHeadAngles(shift : shift + length(cameraMSeq) - 1);
    
    lastIndex = find(cameraMSeq ~= 0, 1, 'last'); % Find last index again
    
    % Transpose m-sequence vector
    cameraMSeq = cameraMSeq';
   
    % Add first elements to end to complete circle
    angles = [angles; angles(1 : round(SEQ_LENGTH * FPS / rateS) - (length(cameraMSeq) - lastIndex + 1))];
    cameraMSeq = [cameraMSeq; cameraMSeq(1 : round(SEQ_LENGTH * FPS / rateS) - (length(cameraMSeq) - lastIndex + 1))];

    %% Generate Kernel
    kernelLength = round(SEQ_LENGTH * FPS / rateS); % Kernel length is whatever the sequence length is times the number of frames for each step
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
    
    if strcmp(data.condition, 'BimodalCoherent')
        visualKernel = finalKernel;
    else
        visualKernel = -finalKernel;
    end
    stepperKernel = finalKernel;

    plot(finalKernel);
    drawnow;
end