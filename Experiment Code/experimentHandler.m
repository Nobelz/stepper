function repeat = experimentHandler(flyNum, flyTrial, treatment, haltere, condition, doubled, delayed, arenaRate, stepperRate)
% experimentHandler.m
% Handles and provides arguments for all arena/stepper experiments.
% This can be called by hand, or through StepperApp.
%
% Inputs:
%   - flyNum: the number of the fly to be analyzed
%   - flyTrial: the trial of the fly, 'con' if conserved
%   - treatment: the treatment of the fly. Usually, it is PCF
%   - haltere: the haltere status of the fly. 1 if intact, 0 if haltereless
%   - condition: the condition of the fly (e.g. 'ArenaOnly')
%   - doubled: whether the m-sequence should be doubled
%   - delayed: whether the m-sequence should be delayed by 200 iterations
%   - arenaRate: the rate at which the arena should be oscillated. 
%                   Currently, the options are 25Hz or 50Hz, with 25Hz 
%                   being default; in stepper-only trials, set the rate to
%                   0.
%   - stepperRate: the rate at which the stepper should be oscillated. In
%                   arena-only trials, set the rate to 0. In bimodal
%                   trials, this does nothing and the stepper rate is the
%                   arena rate.
%
% Author: Nobel Zhou
% Date: 30 June 2023
% Version: 0.2
%
% VERSION CHANGELOG:
% - v0.1 (6/19/2023): Initial commit
% - v0.2 (6/30/2023): Changed striped pattern from 2 to 1 to account for
%                       different card being used
    
    %% Define Constants
    DEFAULT_RATE = 50;
    DURATION = 20;
    STRIPED_PATTERN = 1;
    PATH_TO_FOLDER = '../New Data/';

    %% Parse Arguments
    if nargin < 9
        stepperRate = DEFAULT_RATE; % Default to default rate if no rate provided
    end

    if nargin < 8
        arenaRate = DEFAULT_RATE; % Default to default rate if no rate provided
    end
    
    if strncmpi(condition, 'Stepper', 7)
        arenaRate = 0;
    elseif strncmpi(condition, 'Arena', 5)
        stepperRate = 0; 

        if arenaRate ~= 25 && arenaRate ~= 50
            error('Arena rate must be 25Hz or 50Hz for arena trials.');
        end
    elseif strncmpi(condition, 'Bimodal', 7)
        if arenaRate ~= 25 && arenaRate ~= 50
            error('Arena rate must be 25Hz or 50Hz for bimodal trials.');
        end    

        if arenaRate ~= stepperRate
            warning('Stepper rate not same to arena rate. Setting stepper rate to be arena rate...');
            stepperRate = arenaRate;
        end

        delayed = 0;
        doubled = 0;
    else
        error('Incorrect condition provided.');
    end

    if nargin < 7
        delayed = 0; % Do not delay if not provided
    end
    
    if nargin < 6
        doubled = 0; % Do not double if not provided
    end

    % Other 5 arguments are essential
    if nargin < 5
        error('Fly number, trial, treatment, haltere status, and condition are required as inputs.');
    end
    
    % Load conserved sequence if conserved trial
    if strcmp(num2str(flyTrial), 'con1') || strcmp(num2str(flyTrial), 'con2') || strcmp(num2str(flyTrial), 'con')
        load('./conservedSeq.mat', 'conservedSeq25Hz1');
        load('./conservedSeq.mat', 'conservedSeq25Hz2');
        load('./conservedSeq.mat', 'conservedSeq50Hz1');
        load('./conservedSeq.mat', 'conservedSeq50Hz2');
        
        if arenaRate == 25
            if strcmp(num2str(flyTrial), 'con2')
                seq1 = conservedSeq25Hz2;
                seq2 = conservedSeq25Hz1;
            else
                seq1 = conservedSeq25Hz1;
                seq2 = conservedSeq25Hz2;
            end
        else
            if strcmp(num2str(flyTrial), 'con2')
                seq1 = conservedSeq50Hz2;
                seq2 = conservedSeq50Hz1;
            else
                seq1 = conservedSeq50Hz1;
                seq2 = conservedSeq50Hz2;
            end
        end
        conserved = 1;
    else
        conserved = 0; % Sequences will be generated later
    end
    
    % Check each condition
    switch (condition)
        case 'ArenaOnly'
            if conserved
                funcV = seq1;
            else
                if arenaRate == 25
                    funcV = generateMSeq(1);
                else
                    funcV = generateMSeq(0);
                end
            end

            % Double sequence if necessary
            if doubled == 1  
                funcV = funcV * 2;
            end
            
            % Delay sequence if necessary
            if delayed == 1
                funcV = [zeros(1, 200) funcV(1 : end - 200)];
            end

            % Coder's note: It's ok to chip off the last 200 iterations of 
            % the m-sequence, as the m-sequence should only go to 1 to 
            % 3x127x2 (762), so with 200 delay, it should be 962 max.
            % - nxz157, 6/19/2023
            % Coder's note: In the event of 8th order sequences, we do not
            % interleave, so max would be 3x255 (765) + 200 = 965. Thus, we 
            % can still do the above. - nxz157, 7/3/2023
            % Coder's note: We are now delaying the m-sequence by 30
            % because the DAQ starts too early. Note that this is still
            % less than 1000, so no data will be lost. - nxz157, 7/6/2023

            funcS = zeros(1, 1000); % Set the stepper m-sequence to all zeros so it doesn't move
            pattern = STRIPED_PATTERN; % Load stripes pattern
        case 'StepperOnlyStripes'
            if conserved
                funcS = seq1;
            else
                funcS = generateMSeq(0);
            end

            if doubled == 1
                funcS = funcS * 2;
            end

            if delayed == 1
                funcS = [zeros(1, 200) funcS(1 : end - 200)];
            end
            
            % Set arena m-sequences to all zeros so no movement in arena
            funcV = zeros(1, 1000);
            
            pattern = STRIPED_PATTERN; % Load stripes pattern
        case 'StepperOnlyAllOn'
           if conserved
                funcS = seq1;
            else
                funcS = generateMSeq(0);
            end

            if doubled == 1
                funcS = funcS * 2;
            end

            if delayed == 1
                funcS = [zeros(1, 200) funcS(1 : end - 200)];
            end

            % Set arena m-sequences to all zeros so no movement in arena
            funcV = zeros(1, 1000);
            
            pattern = 'AllOn'; % Load all on pattern
        case 'BimodalRandom'
            if conserved
                funcV = seq1;
                funcS = seq2;
            else
                if arenaRate == 25
                    funcV = generateMSeq(1);
                    funcS = generateMSeq(1);
                else
                    funcV = generateMSeq(0);
                    funcS = generateMSeq(0);
                end
            end

            pattern = STRIPED_PATTERN; % Load stripes pattern
        case 'BimodalCoherent'
            % Use same m-sequence for everything
            if conserved
                funcV = seq1;
                funcS = seq1;
            else
                if arenaRate == 25
                    funcV = generateMSeq(1);
                    funcS = generateMSeq(1);
                else
                    funcV = generateMSeq(0);
                    funcS = generateMSeq(1);
                end
            end

            pattern = STRIPED_PATTERN; % Load stripes pattern
        case 'BimodalOpposing'
            % Use same m-sequence for everything
            if conserved
                funcV = seq1;
            else
                funcV = generateMSeq(1);
            end

            % Use opposite m-sequence for stepper
            funcS = -funcV;

            pattern = STRIPED_PATTERN; % Load stripes pattern
        otherwise
            error('Incorrect condition provided.');
    end


    %% Collect Data
    % Pass arguments to stepper rig control
    [data, time, status] = stepperRigControl(funcV, funcS, pattern, DURATION, stepperRate);

    if status == 1
        fprintf('Saving trial...\n');

        haltereString = ['HL'; 'IN'];
        folderName = strcat(PATH_TO_FOLDER, string(time, 'yyyyMMdd_HHmmss'));
        mkdir(folderName);
        
        % Setup exp struct
        exp = struct();
        exp.data = data;
        exp.time = time;
        exp.flyNum = flyNum;
        exp.flyTrial = flyTrial;
        exp.treatment = treatment;
        exp.haltere = haltereString(haltere + 1, :);
        exp.condition = condition;
        exp.funcV = funcV;
        exp.funcS = funcS;
        exp.rateV = arenaRate;
        exp.rateS = stepperRate;
        exp.pattern = pattern;

        fileName = [treatment '_F' num2str(flyNum) '_T' num2str(flyTrial)...
            '_' haltereString(haltere + 1, :) '_' condition '_' ...
            string(time, 'yyyyMMdd_HHmmss')]; 
            
        fileName = strjoin(fileName, '');
        fileName = fullfile(folderName, fileName);
        fprintf('Saving file to folder...\n');
        save(fileName, 'exp');

        repeat = 0;
    else
        btn = questdlg('Data collection failed; do you want to try again? The default value is Yes.', 'Repeat?', 'Yes', 'No', 'Yes');
       
        if strcmp(btn, 'Yes')
            repeat = 1;
        else
            repeat = 0;
        end
    end
end

