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

    %% Visual Only
    fprintf('Running visual-only conserved trial...\n');
    while experimentHandler(flyNum, 'con', TREATMENT, 1, 'VisualOnly', 0, 0, 50, 50)
    end
    
    for i = 1 : 3
        clc;
        fprintf(['Running visual-only trial ' num2str(i) ' of 3...\n']);
        while experimentHandler(flyNum, i, TREATMENT, 1, 'VisualOnly', 0, 0, 50, 50)
        end
    end

    %% Stepper Only Stripes
    clc;
    fprintf('Running stepper-only stripes conserved trial...\n');
    while experimentHandler(flyNum, 'con', TREATMENT, 1, 'StepperOnlyStripes', 0, 0, 50, 50)
    end
    
    for i = 1 : 3
        clc;
        fprintf(['Running stepper-only stripes trial ' num2str(i) ' of 3...\n']);
        while experimentHandler(flyNum, i, TREATMENT, 1, 'StepperOnlyStripes', 0, 0, 50, 50)
        end
    end
    
    %% Stepper Only All On
    clc;
    fprintf('Running stepper-only all on conserved trial...\n');
    while experimentHandler(flyNum, 'con', TREATMENT, 1, 'StepperOnlyAllOn', 0, 0, 50, 50)
    end
    
    for i = 1 : 3
        clc;
        fprintf(['Running stepper-only all on trial ' num2str(i) ' of 3...\n']);
        while experimentHandler(flyNum, i, TREATMENT, 1, 'StepperOnlyAllOn', 0, 0, 50, 50)
        end
    end

    %% Bimodal Coherent
    clc;
    fprintf('Running bimodal coherent conserved trial...\n');
    while experimentHandler(flyNum, 'con', TREATMENT, 1, 'BimodalCoherent', 0, 0, 50, 50)
    end
    
    for i = 1 : 3
        clc;
        fprintf(['Running bimodal coherent trial ' num2str(i) ' of 3...\n']);
        while experimentHandler(flyNum, i, TREATMENT, 1, 'BimodalCoherent', 0, 0, 50, 50)
        end
    end

    %% Bimodal Opposing
    clc;
    fprintf('Running bimodal coherent conserved trial...\n');
    while experimentHandler(flyNum, 'con', TREATMENT, 1, 'BimodalOpposing', 0, 0, 50, 50)
    end
    
    for i = 1 : 3
        clc;
        fprintf(['Running bimodal coherent trial ' num2str(i) ' of 3...\n']);
        while experimentHandler(flyNum, i, TREATMENT, 1, 'BimodalOpposing', 0, 0, 50, 50)
        end
    end

    %% Bimodal Random
    clc;
    fprintf('Running bimodal random conserved trial 1 of 2...\n');
    while experimentHandler(flyNum, 'con1', TREATMENT, 1, 'BimodalRandom', 0, 0, 50, 50)
    end

    clc;
    fprintf('Running bimodal random conserved trial 2 of 2...\n');
    while experimentHandler(flyNum, 'con2', TREATMENT, 1, 'BimodalRandom', 0, 0, 50, 50)
    end
    
    for i = 1 : 3
        clc;
        fprintf(['Running bimodal random trial ' num2str(i) ' of 3...\n']);
        while experimentHandler(flyNum, i, TREATMENT, 1, 'BimodalRandom', 0, 0, 50, 50)
        end
    end
end