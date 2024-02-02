function [visualKernel, stepperKernel] = kernelRandom(data)
% kernelRandom.m
% Returns the kernel for the bimodal random trials only.
% Warning: this is only implemented for 50Hz, as I was too lazy to make it
% compatible for 25Hz. 
%
% Inputs:
%   - data: the formatted trial data
%
% Author: Nobel Zhou
% Date: 14 December 2023
% Version: 
%
% VERSION CHANGELOG:
% - v0.1 (12/14/2023): Initial commit
   
    %% Constants
    FPS = 600;
    DAQ_RATE = 10000;
    SEQ_LENGTH = 255; % Whatever the length of the m-sequence is (255 * 3 for me)
    
    %% Find Camera and Stepper Firing
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
    stepperMSeq = data.funcS;
    arenaMSeq = data.funcV;
    seqLength = sum(stepperMSeq ~= 0); % Get number of non-zero elements
    
    % Make array of upsampled m-sequence
    cameraStepperMSeq = zeros(1, length(data.bodyAngles));
    cameraArenaMSeq = zeros(1, length(data.bodyAngles));

    % Loop for each step of m-sequence
    for i = 1 : seqLength + 1 % We get one more than the sequence length so we know when the m-sequence actually ends
        [~, frameIndex] = min(abs(cameraIndices - arenaIndices(i))); % Find the camera index closest to the stepper step
        if i == seqLength + 1
            cameraStepperMSeq(frameIndex) = 100; % Store temp value to indicate end of m-sequence
            cameraArenaMSeq(frameIndex) = 100;
        else
            cameraStepperMSeq(frameIndex) = stepperMSeq(i); % Store value of m-sequence at that closest camera index
            cameraArenaMSeq(frameIndex) = arenaMSeq(i);
        end
    end

    %% Find Camera M-Sequence
    firstIndex = find(cameraStepperMSeq ~= 0, 1, 'first'); % Find first index of change
    lastIndex = find(cameraStepperMSeq ~= 0, 1, 'last'); % Find last index of change
    cameraStepperMSeq = cameraStepperMSeq(firstIndex : lastIndex); % Find interval of interest
    cameraArenaMSeq = cameraArenaMSeq(firstIndex : lastIndex); % Find interval of interest
    cameraStepperMSeq = cameraStepperMSeq(1 : end - 1); % Get rid of final trigger
    cameraArenaMSeq = cameraArenaMSeq(1 : end - 1);

    %% Frame/Camera Association
    % Upsample m-sequence to match camera sampling rate
    corrBodyAngles = -data.bodyAngles;
    corrMSeq = cumsum(cameraStepperMSeq);
    
    % Cross correlate m-sequence and angles to find sequence begin time
    [cc, lags] = xcorr(corrMSeq, corrBodyAngles); % Find the lags and cross-correlation
    [~, lagIndex] = max(cc); % Take the max-cross correlation
    
    % Find number to shift the camera by
    shift = -lags(lagIndex);

    %% Formulate Final Camera M-Sequence and Head Angles
    % Determine relative head angles
    relHeadAngles = data.headAngles - data.bodyAngles;
    angles = relHeadAngles(shift : shift + length(cameraStepperMSeq) - 1);
    
    lastIndex = find(cameraStepperMSeq ~= 0, 1, 'last'); % Find last index again
    
    % Transpose m-sequence vector
    cameraStepperMSeq = cameraStepperMSeq';
    cameraArenaMSeq = cameraArenaMSeq';
   
    % Add first elements to end to complete circle
    angles = [angles; angles(1 : round(SEQ_LENGTH * FPS / rateS) - (length(cameraStepperMSeq) - lastIndex + 1))];
    cameraStepperMSeq = [cameraStepperMSeq; cameraStepperMSeq(1 : round(SEQ_LENGTH * FPS / rateS) - (length(cameraStepperMSeq) - lastIndex + 1))];
    cameraArenaMSeq = [cameraArenaMSeq; cameraArenaMSeq(1 : round(SEQ_LENGTH * FPS / rateS) - (length(cameraArenaMSeq) - lastIndex + 1))];

    %% Generate Kernel
    kernelLength = round(SEQ_LENGTH * FPS / rateS); % Kernel length is whatever the sequence length is times the number of frames for each step
    sumArenaKernel = zeros(1, length(kernelLength));
    sumStepperKernel = zeros(1, length(kernelLength));
    kernelCount = 0;

    % Sliding window loop
    for j = 1 : length(angles) - kernelLength + 1
        newHead = angles(j : j + kernelLength - 1);
        newStepperSeq = cameraStepperMSeq(j : j + kernelLength - 1);
        newArenaSeq = cameraArenaMSeq(j : j + kernelLength - 1);
        
        stepperKernel = fcxcorr(newHead, newStepperSeq) ./ sqrt(norm(newHead) * norm(newStepperSeq)); % Conserved kernel calculation from previous research
        stepperKernel = stepperKernel - stepperKernel(1);

        arenaKernel = fcxcorr(newHead, newArenaSeq) ./ sqrt(norm(newHead) * norm(newArenaSeq)); % Conserved kernel calculation from previous research
        arenaKernel = arenaKernel - arenaKernel(1);
        
        % Check if kernel is valid (a kernel will be invalid if all of the
        % m sequence is 0 for that particular interval
        if ~anynan(stepperKernel) && ~anynan(arenaKernel)
            sumStepperKernel = sumStepperKernel + stepperKernel;
            sumArenaKernel = sumArenaKernel + arenaKernel;
            kernelCount = kernelCount + 1; 
        end
    end

    stepperKernel = sumStepperKernel / kernelCount;
    visualKernel = sumArenaKernel / kernelCount;

    subplot(2, 1, 1);
    plot(stepperKernel);
    subplot(2, 1, 2);
    plot(visualKernel);
    drawnow;
end