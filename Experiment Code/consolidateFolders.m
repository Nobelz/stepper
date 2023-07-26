function consolidateFolders()
% consolidateFolders.m
% Consolidates all subfolders into one folder.
%
% Author: Nobel Zhou (nxz157)
% Date: 18 July 2023
% Version: 1.0
%
% VERSION CHANGELOG:
% - v0.1 (7/18/2023): Initial commit
    
    clc;
    %% Define Constants
    NEW_DATA_DIR = '../../Stepper Data/New Data';

    d = dir([NEW_DATA_DIR filesep '*.*']);

    for i = 3 : length(d)
        if d(i).isdir
            files = dir([d(i).folder filesep d(i).name filesep '*.*']);
            for j = 3 : length(files)
                file = [files(j).folder filesep files(j).name];
                fprintf(['Moving ' files(j).name '...\n']);
                pause(0.1);
                movefile(file, d(i).folder);
            end
        end
    end
end
    