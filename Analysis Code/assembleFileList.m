function fileList = assembleFileList(dataDir)
% assembleFileList.m
% Assembles an struct array containing all pertinent files.
%
% Inputs:
%   - dataDir: folder path where the videos and data are located, as a
%       string
%
% Author: Nobel Zhou
% Date: 15 September 2023
% Version: 
%
% VERSION CHANGELOG:
% - v0.1 (9/15/2023): Initial commit

    expFiles = dir([dataDir filesep '*.mat']);
    procFiles = dir([dataDir filesep '*_PROC.mat']);
    
    fileList = struct();
    
    % Find proc files in exp files list and remove them
    for i = 1 : length(procFiles)
        for j = 1 : length(expFiles)
            if strcmp(expFiles(j).name, procFiles(i).name)
                temp = struct();
                temp.procFile = procFiles(i);
                temp.expFile = expFiles(j - 1);
    
                fileList.files(j / 2) = temp;
            end
        end
    end
    
    fileList = fileList.files;
end
