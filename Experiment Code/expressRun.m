function expressRun(flyNum)
% expressRun.m
% Runs all relevant trials for the fly.
%
% Inputs:
%   - flyNum: the number of the fly
%
% Author: Nobel Zhou
% Date: 11 July 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (7/11/2023): Initial commit
    
    clc;
    
    %% Define Constants
    TREATMENT = 'PCF';
    DEFAULT_RATE = 50;

    %% Test Linearity
    fprintf('Testing linearity...\n');
    uiwait(msgbox({'Please make sure camera is set to 7.000GB storage,', ...
        'then click ok to continue', ...
        '(Required buffer length 40 seconds)'}));

    while experimentHandler(flyNum, 1, TREATMENT, 1, 'TestLinearity')
    end
    
    uiwait(msgbox({'Please make sure camera is set to 3.750GB storage, then click ok to continue', ...
        '(Required buffer length 20 seconds)'}));
    
    expOrder = randperm(6); % Randomize experiment treatment

    for j = 1 : 6
        clc;

        switch expOrder(j)
            case 1
                %% Visual Only
                fprintf('Running arena-only conserved trial...\n');
                while experimentHandler(flyNum, 'con', TREATMENT, 1, 'ArenaOnly', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                end
                
                for i = 1 : 3
                    clc;
                    fprintf(['Running arena-only trial ' num2str(i) ' of 3...\n']);
                    while experimentHandler(flyNum, i, TREATMENT, 1, 'ArenaOnly', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                    end
                end
            
            case 2
                %% Stepper Only Stripes
                fprintf('Running stepper-only stripes conserved trial...\n');
                while experimentHandler(flyNum, 'con', TREATMENT, 1, 'StepperOnlyStripes', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                end
                
                for i = 1 : 3
                    clc;
                    fprintf(['Running stepper-only stripes trial ' num2str(i) ' of 3...\n']);
                    while experimentHandler(flyNum, i, TREATMENT, 1, 'StepperOnlyStripes', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                    end
                end
            
            case 3
                %% Stepper Only All On
                fprintf('Running stepper-only all on conserved trial...\n');
                while experimentHandler(flyNum, 'con', TREATMENT, 1, 'StepperOnlyAllOn', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                end
                
                for i = 1 : 3
                    clc;
                    fprintf(['Running stepper-only all on trial ' num2str(i) ' of 3...\n']);
                    while experimentHandler(flyNum, i, TREATMENT, 1, 'StepperOnlyAllOn', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                    end
                end

            case 4
                %% Bimodal Coherent
                fprintf('Running bimodal coherent conserved trial...\n');
                while experimentHandler(flyNum, 'con', TREATMENT, 1, 'BimodalCoherent', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                end
                
                for i = 1 : 3
                    clc;
                    fprintf(['Running bimodal coherent trial ' num2str(i) ' of 3...\n']);
                    while experimentHandler(flyNum, i, TREATMENT, 1, 'BimodalCoherent', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                    end
                end
        
            case 5
                %% Bimodal Opposing
                fprintf('Running bimodal coherent conserved trial...\n');
                while experimentHandler(flyNum, 'con', TREATMENT, 1, 'BimodalOpposing', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                end
                
                for i = 1 : 3
                    clc;
                    fprintf(['Running bimodal coherent trial ' num2str(i) ' of 3...\n']);
                    while experimentHandler(flyNum, i, TREATMENT, 1, 'BimodalOpposing', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                    end
                end
        
            case 6
                %% Bimodal Random
                fprintf('Running bimodal random conserved trial 1 of 2...\n');
                while experimentHandler(flyNum, 'con1', TREATMENT, 1, 'BimodalRandom', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                end
            
                clc;
                fprintf('Running bimodal random conserved trial 2 of 2...\n');
                while experimentHandler(flyNum, 'con2', TREATMENT, 1, 'BimodalRandom', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                end
                
                for i = 1 : 3
                    clc;
                    fprintf(['Running bimodal random trial ' num2str(i) ' of 3...\n']);
                    while experimentHandler(flyNum, i, TREATMENT, 1, 'BimodalRandom', 0, 0, DEFAULT_RATE, DEFAULT_RATE)
                    end
                end
        end
    end

    clc;
    fprintf('Done collecting experiments!\n');
end