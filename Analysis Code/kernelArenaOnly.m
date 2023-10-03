function kernel = kernelArenaOnly(data)

% kernelArenaOnly.m
% Returns the kernel for the arena only trials.
% Warning: this is only implemented for 50Hz, as I was too lazy to make it
% compatible for 25Hz. 
%
% Inputs:
%   - data: the formatted trial data
%
% Author: Nobel Zhou
% Date: 3 October 2023
% Version: 
%
% VERSION CHANGELOG:
% - v0.1 (10/3/2023): Initial commit
   
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

    % if length(stepperTriggers) < seqLength + 1;
    %     disp([num2str(data.flyNum) ', ' data.condition ', ' num2str(data.flyTrial)]);
    %     finalKernel = [];
    %     return;
    % end

    % Coder's note: the above was removed because some trials weren't up to
    % par. Again, these did not have an arena channel. - nxz157, 10/3/2023

    % Loop for each step of m-sequence
    for i = 1 : seqLength + 1 % We get one more than the sequence length so we know when the m-sequence actually ends
        [~, frameIndex] = min(abs(cameraIndices - stepperTriggers(i))); % Find the camera index closest to the stepper step
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
    
%     startPoint = (FPS / rateS) * PREPEND_STEPS + 600;
%     
%     % Coder's note: the above does something complicated but remember that
%     % we prepended 30 zeros since the DAQ was firing too slow. With each
%     % step being approximately 12 camera frames (FPS = 600 / stepper rate =
%     % 50) = 12, we need to offset it by 360 camera frames. Finally, 600
%     % frames were taken before the trigger. Then we need to trim to the
%     % correct length for m-sequence analysis. - nxz157, 10/2/2023
    
    % Coder's note: the above does not work because the camera doesn't work
    % like that. The above cross-correlation attempts to align the cumsum
    % m-sequence with the actual body angles, which allows to determine
    % which frame in the camera actually begins the m-sequence. - nxz157,
    % 10/3/2023
    
    angles = relHeadAngles(shift : shift + length(cameraMSeq) - 1);
    
    lastIndex = find(cameraMSeq ~= 0, 1, 'last'); % Find last index again
    
    % Transpose m-sequence vector
    cameraMSeq = cameraMSeq';
   
    % Add first elements to end to complete circle
    angles = [angles; angles(1 : SEQ_LENGTH * FPS / rateS - (length(cameraMSeq) - lastIndex + 1))];
    cameraMSeq = [cameraMSeq; cameraMSeq(1 : SEQ_LENGTH * FPS / rateS - (length(cameraMSeq) - lastIndex + 1))];

    % Coder's note: the above does something kinda complex but it's
    % actually pretty simple. For the sliding window, it's a circular
    % correlation so at the end of the m-sequence, I need to wrap around to
    % the front. Now I could do a modulo operator or something funky like
    % that but I chose to just append the beginning of the sequence at the
    % end so I don't have to do that weird math. All of what this does is
    % that it makes sure that there is just enough elements at the end to
    % accomplish this circular cross-correlation. - nxz157, 10/2/2023

    %% Generate Kernel
    kernelLength = SEQ_LENGTH * FPS / rateS; % Kernel length is whatever the sequence length is times the number of frames for each step
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
    
    % plot(finalKernel);
    % pause;
end