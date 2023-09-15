function fileList = assembleFileList(dataDir, saveResults)
% assembleFileList.m
% Assembles an struct array containing all videos and information.
%
% Inputs:
%   - dataDir: folder path where the videos and data are located, as a
%       string
%   - saveResults: 1 to save results to a mat file, 0 to not save
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
            temp.expFile = expFiles(j);

            fileList.files(j / 2) = temp;
        end
    end
end

end
