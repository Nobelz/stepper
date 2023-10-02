function flies = assembleFlyDirectory(fileList, saveResults)
% assembleFlyDirectory.m
% Assembles an struct array containing all fly information.
%
% Inputs:
%   - fileList: list of relevant experiment and proc files
%   - saveResults: 1 to save results to a mat file, 0 to not save
%
% Author: Nobel Zhou
% Date: 29 September 2023
% Version: 
%
% VERSION CHANGELOG:
% - v0.1 (9/29/2023): Initial commit

    flies = struct(); % Create struct storing flies
    fprintf('Loading files...\n');

    for i = 1 : length(fileList)
        fprintf(['\tLoading file ' num2str(i) ' of ' num2str(length(fileList)) '...']);
        % Load files
        load([fileList(i).expFile.folder filesep fileList(i).expFile.name]);
        load([fileList(i).procFile.folder filesep fileList(i).procFile.name]);
    
        temp = struct(); % Make temporary struct to store fly information
        temp.flyNum = exp.flyNum;
        temp.condition = exp.condition;
    
        % Change fly trials so they are just numbers (-1 is
        % conserved/conserved 1, -2 is conserved 2)
        if isnumeric(exp.flyTrial)
            temp.flyTrial = exp.flyTrial;
        else
            if strcmp(exp.flyTrial, 'con') || strcmp(exp.flyTrial, 'con1')
                temp.flyTrial = -1;
            else
                temp.flyTrial = -2;
            end
        end
    
        temp.treatment = exp.treatment;
        if ~strcmp(exp.condition, 'TestLinearity')
            temp.funcV = exp.funcV;
            temp.funcS = exp.funcS;
            temp.rateV = exp.rateV;
            temp.rateS = exp.rateS;
        end

        % Add data
        temp.data = struct();
        temp.data.t = exp.data.('Time');
        temp.data.arenaTrigger = exp.data.('Dev1_ai1');
        temp.data.camera = exp.data.('Dev1_ai2');
        temp.data.stepper = exp.data.('Dev1_ai6');

        % Linearity trials have different inputs
        if strcmp(exp.condition, 'TestLinearity')
            temp.data.stepperTrigger = exp.data.('Dev1_ai10');
            temp.data.arena = [];
            temp.data.stepperStart = [];
            temp.funcV = [];
            temp.funcS = [];
            temp.rateV = NaN;
            temp.rateS = NaN;
        else
            temp.data.stepperTrigger = exp.data.('Dev1_ai3');
            temp.data.arena = exp.data.('Dev1_ai4');
            temp.data.stepperStart = exp.data.('Dev1_ai14');
        end
    
        % Add camera data
        temp.headAngles = fly.proc.HeadAng;
        temp.bodyAngles = fly.proc.BodyAng;
        
        flies.flies(i) = temp;
        fprintf('done\n');
    end

    fprintf('Done loading files.\n');
    flies = flies.flies;

    if saveResults
        fprintf('Saving fly information (this may take a long time)...');
        save('flies', 'flies', '-v7.3'); % Save file list results
        fprintf('done\n');
        % Coder's note: apparently the file generated is way too large and
        % more than 2GB. Consistent to MATLAB directions, MAT 7.3 is
        % required. - nxz157, 10/2/2023
    end
end
