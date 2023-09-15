% stepperAnalysis.m
% Generates a kernels from ALL data collected during Stepper 2.0.
%
% Author: Nobel Zhou
% Date: 15 September 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (9/15/2023): Initial commit

%% Define Constants
RESET_FILE_LIST = 0; % 1 to pull videos from the directory again (do this if videos have been added)
DATA_DIR = '../../Stepper Data/Analyzed Data';

%% Find Files
fileList = dir('./fileList.mat');

if isempty(fileList) || RESET_FILE_LIST
    fileList = assembleFileList(DATA_DIR, 1); % Pull videos if not found
end