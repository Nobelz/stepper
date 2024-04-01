function finalData = kernelLinearity(data)
% kernelLinearity.m
% Returns the final data for the test linearity trials.
%
% Inputs:
%   - data: the formatted trial data
%
% Author: Nobel Zhou
% Date: 29 March 2024
% Version: 
%
% VERSION CHANGELOG:
% - v0.1 (3/29/2024): Initial commit
   
    %% Constants
    FPS = 600; 
    DAQ_RATE = 10000;

    %% Line up DAQ and Camera
    % Get camera trigger information
    cameraTrigger = fastecMarkerReader([data.pmFile.folder filesep data.pmFile.name], 6);
    
    % Get arena trigger information
    arenaTrigger = data.data.arenaTrigger;
    
    % Find trigger index in DAQ
    daqTrigger = find(arenaTrigger > 3);
    daqTrigger = daqTrigger(1);

    % Downsample DAQ to FPS
    stepper = zeros(1, length(data.headAngles));
    stepper(1) = data.data.stepper(daqTrigger); % Set first stepper index to first index of daqTrigger
    
    stepperIdx = 0;

    for i = 2 : length(data.headAngles)
        % Check if index is in range of DAQ 
        if (round(daqTrigger + i * DAQ_RATE / FPS) - 1 > length(data.data.stepper))
            break;
        end
        
        % Determine data range of downsampling
        dataRange = round(daqTrigger + (i - 1) * DAQ_RATE / FPS) : round(daqTrigger + i * DAQ_RATE / FPS) - 1;

        if any(data.data.stepper(dataRange) > 3) % Check if a step has been performed in that region
            stepperIdx = stepperIdx + 1;

            if mod(stepperIdx, 5) == 0 % Every 5th step is a double step
                stepper(i) = 2;
            else
                stepper(i) = 1;
            end
        end
    end
    
    % Find first camera trigger
    triggers = find(cameraTrigger > 0);
    stepper = [zeros(1, triggers(1)) stepper];
    
    %% Divide data into chunks and make finalData
    relAngles = data.headAngles - data.bodyAngles;
    
    finalData = struct();

    finalData.allOn = struct();
    finalData.stripes = struct();

    finalData.allOn.left = struct();
    finalData.allOn.right = struct();
    
    stepperIdx = find(stepper > 0);
    
    finalData.allOn.left.trial1 = relAngles(stepperIdx(1) : stepperIdx(1) + FPS - 1) - relAngles(stepperIdx(1));
    finalData.allOn.left.trial2 = relAngles(stepperIdx(2) - FPS * 0.1 : stepperIdx(2) + FPS * 0.9 - 1) - relAngles(stepperIdx(2) - FPS * 0.1);
    finalData.allOn.left.trial3 = relAngles(stepperIdx(3) : stepperIdx(3) + FPS - 1) - relAngles(stepperIdx(3));
    finalData.allOn.left.trial4 = relAngles(stepperIdx(5) : stepperIdx(5) + FPS - 1) - relAngles(stepperIdx(5));

    finalData.allOn.right.trial1 = relAngles(stepperIdx(6) : stepperIdx(6) + FPS - 1) - relAngles(stepperIdx(6));
    finalData.allOn.right.trial2 = relAngles(stepperIdx(7) - FPS * 0.1 : stepperIdx(7) + FPS * 0.9 - 1) - relAngles(stepperIdx(7) - FPS * 0.1);
    finalData.allOn.right.trial3 = relAngles(stepperIdx(8) : stepperIdx(8) + FPS - 1) - relAngles(stepperIdx(8));
    finalData.allOn.right.trial4 = relAngles(stepperIdx(10) : stepperIdx(10) + FPS - 1) - relAngles(stepperIdx(10));

    finalData.stripes.left.trial1 = relAngles(stepperIdx(11) : stepperIdx(11) + FPS - 1) - relAngles(stepperIdx(11));
    finalData.stripes.left.trial2 = relAngles(stepperIdx(12) - FPS * 0.1 : stepperIdx(12) + FPS * 0.9 - 1) - relAngles(stepperIdx(12) - FPS * 0.1);
    finalData.stripes.left.trial3 = relAngles(stepperIdx(13) : stepperIdx(13) + FPS - 1) - relAngles(stepperIdx(13));
    finalData.stripes.left.trial4 = relAngles(stepperIdx(15) : stepperIdx(15) + FPS - 1) - relAngles(stepperIdx(15));

    finalData.stripes.right.trial1 = relAngles(stepperIdx(16) : stepperIdx(16) + FPS - 1) - relAngles(stepperIdx(16));
    finalData.stripes.right.trial2 = relAngles(stepperIdx(17) - FPS * 0.1 : stepperIdx(17) + FPS * 0.9 - 1) - relAngles(stepperIdx(17) - FPS * 0.1);
    finalData.stripes.right.trial3 = relAngles(stepperIdx(18) : stepperIdx(18) + FPS - 1) - relAngles(stepperIdx(18));
    finalData.stripes.right.trial4 = relAngles(stepperIdx(20) : stepperIdx(20) + FPS - 1) - relAngles(stepperIdx(20));
end