function experimentHandler(flyNum, flyTrial, treatment, haltere, condition, doubled, delayed, setup, arenaRate, stepperRate)
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
%   - setup: whether voltages should be setup again
%   - arenaRate: the rate at which the arena should be oscillated
%   - stepperRate: the rate at which the stepper should be oscillated
%
% Author: Nobel Zhou
% Date: 19 June 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (6/19/2023): Initial commit
    
    %% Define Constants
    DEFAULT_RATE = 50;
    DURATION = 20;
    PATH_TO_FOLDER = '../New Data/';

    %% Parse Arguments
    if nargin < 10
        stepperRate = DEFAULT_RATE; % Default to default rate if no rate provided
    end

    if nargin < 9
        arenaRate = DEFAULT_RATE; % Default to default rate if no rate provided
    end
    
    if nargin < 8
        setup = 0; % No setup if input not provided
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
    if strcmp(num2str(flyTrial), 'con')
        load('./conserved_seq.mat', 'conserved_seq');
        sequence = conserved_seq;
    else
        sequence = generateMSeq(); % Generate new m-sequence if not conserved
    end
    
    % Check each condition
    switch (condition)
        case 'ArenaOnly'
            % Double sequence if necessary
            if doubled == 1  
                funcX = sequence * 2;
                funcY = sequence * 2;
            else
                funcX = sequence;
                funcY = sequence;
            end
            
            % Delay sequence if necessary
            if delayed == 1
                funcX = [zeros(1, 200) funcX(1 : end - 200)];
                funcY = [zeros(1, 200) funcY(1 : end - 200)];
            end

            % Coder's note: It's ok to chip off the last 200 iterations of 
            % the m-sequence, as the m-sequence should only go to 1 to 
            % 3x127x2 (762), so with 200 delay, it should be 962 max.
            % - nxz157, 6/19/2023

            funcS = zeros(1, 1000); % Set the stepper m-sequence to all zeros so it doesn't move
            pattern = 2; % Load stripes pattern
        case 'StepperOnlyStripes'
            if doubled == 1
                funcS = sequence * 2;
            else
                funcS = sequence;
            end

            if delayed == 1
                funcS = [zeros(1, 200) funcS(1 : end - 200)];
            end
            
            % Set arena m-sequences to all zeros so no movement in arena
            funcX = zeros(1, 1000);
            funcY = zeros(1, 1000);
            
            pattern = 2; % Load stripes pattern
        case 'StepperOnlyAllOn'
            if doubled == 1
                funcS = sequence * 2;
            else
                funcS = sequence;
            end

            if delayed == 1
                funcS = [zeros(1, 200) funcS(1 : end - 200)];
            end

            % Set arena m-sequences to all zeros so no movement in arena
            funcX = zeros(1, 1000);
            funcY = zeros(1, 1000);
            
            pattern = 'AllOn'; % Load all on pattern
        case 'BimodalRandom'
            % Set arena to random m-sequence
            funcX = sequence;
            funcY = sequence;

            % Generate new m-sequence for stepper
            funcS = generateMSeq();

            pattern = 2; % Load stripes pattern
        case 'BimodalCoherent'
            % Use same m-sequence for everything
            funcX = sequence;
            funcY = sequence;
            funcS = sequence;

            pattern = 2; % Load stripes pattern
        case 'BimodalOpposing'
            funcX = sequence;
            funcY = sequence;

            % Use opposite m-sequence for stepper
            funcS = -sequence;

            pattern = 2; % Load stripes pattern
        otherwise
            error('Incorrect condition provided.');
    end


    %% Collect Data
    % Pass arguments to stepper rig control
    [data, time] = stepperRigControl(funcX, funcY, funcS, arenaRate, stepperRate, pattern, DURATION, setup);

    fprintf('Awaiting user input...\n');
    % Check if we want to save this trial
    btn = questdlg('Save This Trial?','Save Trial', 'Yes', 'No', 'No');

    if strcmp(btn, 'Yes')
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
        exp.funcV = funcX;
        exp.funcS = funcS;
        exp.rateV = arenaRate;
        exp.rateS = stepperRate;

        fileName = [treatment '_F' num2str(flyNum) '_T' num2str(flyTrial)...
            '_' haltereString(haltere + 1, :) '_' condition '_' ...
            string(time, 'yyyyMMdd_HHmmss')]; 
            
        fileName = strjoin(fileName, '');
        fileName = fullfile(folderName, fileName);
        fprintf('Saving file to folder...\n');
        save(fileName, 'exp');
    end
end
