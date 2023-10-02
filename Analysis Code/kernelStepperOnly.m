%function kernel = kernelStepperOnly(data)

% kernelStepperOnly.m
% Returns the kernel for the stepper only trials.
% Warning: this is only implemented for 50Hz, as I was too lazy to make it
% compatible for 25Hz. 
%
% Inputs:
%   - data: the formatted trial data
%
% Author: Nobel Zhou
% Date: 2 October 2023
% Version: 
%
% VERSION CHANGELOG:
% - v0.1 (10/2/2023): Initial commit
   
    %% Constants
    FPS = 600; 
    rateS = 50;
    DAQ_RATE = 10000;
    PREPEND_STEPS = 30;
    
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
    
    % Make low-pass filter to get rid of noisy data
    lowPassFilter = fir1(100, rateS / (DAQ_RATE / 2), 'low'); % Nyquist frequency is half of sampling rate
    filtered = filter(lowPassFilter, 1, arenaData); % Apply filter
    normalizedFiltered = abs(diff(filtered)); % Take difference and find the peaks
    [~, arenaIndices] = findpeaks(normalizedFiltered, 'MinPeakHeight', 0.0003, 'MinPeakWidth', 10);
    arenaIndices = arenaIndices - 47; % Experimentally determined peak offset
    
%     if length(indices) < 2
%         disp([num2str(data.flyNum) ', ' data.condition ', ' num2str(data.flyTrial)]);
%         return;
%     end

    % Coder's note: the above was used to detect trials that do not have
    % any arena channel. These trials are unanalyzable since otherwise I
    % cannot figure out when they start. Those have since been removed and
    % that code is no longer necessary. - nxz157, 10/2/2023
    
    firstArenaStep = arenaIndices(2); % Avoid first peak that is generated from the low pass filter
    [~, firstStep] = min(abs(stepperIndices - firstArenaStep)); % Find the corresponding stepper step
    
    %% Step/Frame Association
    % Determine actual length of m-sequence
    mSeq = data.funcS;
    seqLength = sum(mSeq ~= 0); % Get number of non-zero elements

    stepperTriggers = stepperIndices(firstStep : end); % Get rid of pre-start stepper fires
    
    % Make array of upsampled m-sequence
    cameraMSeq = zeros(1, length(data.bodyAngles));

    % Loop for each step of m-sequence
    for i = 1 : seqLength
        [~, frameIndex] = min(abs(cameraIndices - stepperTriggers(i))); % Find the camera index closest to the stepper step
        cameraMSeq(frameIndex) = mSeq(i); % Store value of m-sequence at that closest camera index
    end

    %% Formulate Final Camera M-Sequence
    cameraMSeq = [zeros((FPS / rateS) * PREPEND_STEPS + 600, 1); cameraMSeq'];
    cameraMSeq = cameraMSeq';
    cameraMSeq = cameraMSeq(1 : length(data.bodyAngles));

    % Coder's note: the above does something complicated but remember that
    % we prepended 30 zeros since the DAQ was firing too slow. With each
    % step being approximately 12 camera frames (FPS = 600 / stepper rate =
    % 50) = 12, we need to offset it by 360 camera frames. Finally, 600
    % frames were taken before the trigger. Then we need to trim to the
    % correct length for m-sequence analysis. - nxz157, 10/2/2023
    
    %% Determine Head Angles
    
%end