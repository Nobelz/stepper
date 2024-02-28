function voltages = getArenaVoltages
% getArenaVoltages.m
% Gets the specific arena voltages for each index.
% Returns a 20 row matrix representing the voltage at each index for X
% and Y.
%   
% Author: Nobel Zhou
% Date: 27 February 2024
% Version: 0.3
%
% VERSION CHANGELOG:
% - v0.1 (6/14/2023): Initial commit
% - v0.2 (6/16/2023): Added comments
% - v0.3 (2/27/2024): Changed for 10x10 mapping
 
    fprintf('Getting Arena Voltages...\n');
    %% Setup Panel Controller and DAQ
    % Setup Panel Controller
    fprintf('\tSetting up Panel Controller');
    Panel_com('stop');
    Panel_com('set_mode', [3 3]); % Set to position control mode
    pause(0.2);
    fprintf('.');
    Panel_com('set_pattern_id', 1); % Set to striped pattern
    fprintf('.');
    Panel_com('set_position', [1 1]);
    fprintf('.done\n');
    
    % Setup DAQ
    fprintf('\tSetting up DAQ');
    in = daq('ni');
    fprintf('.');
    in.Rate = 10000;
    fprintf('.');
    ch = addinput(in,'dev1','ai10','Voltage'); % AI10 is Arena X input
    fprintf('.');
    ch = addinput(in,'dev1','ai3','Voltage'); % AI3 is Arena X input
    fprintf('.');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.done\n');
    
    % Setup Output
    fprintf('\tCommencing voltage operations...\n');
    voltages = zeros(1, 20);
    
    %% Loop Through Indices
    for i = 1 : 10
        fprintf(['\t\tX: Determining Voltage of Frame ' num2str(i) ' of 10']);
        Panel_com('set_position', [i 1]); % Set position to index
        fprintf('.');
        pause(2);
        fprintf('.');
    
        TT = read(in, seconds(0.5)); % Block MATLAB and collect voltage data for 0.5 seconds
        fprintf('.');
        data = TT.Dev1_ai10; % Read Arena X
        fprintf('.');
        voltages(i) = mean(data);
        fprintf('.done\n');
    end

    for j = 1 : 10
        fprintf(['\t\tY: Determining Voltage of Frame ' num2str(j) ' of 10']);
        Panel_com('set_position', [1 j]); % Set position to index
        fprintf('.');
        pause(2);
        fprintf('.');
    
        TT = read(in, seconds(0.5)); % Block MATLAB and collect voltage data for 0.5 seconds
        fprintf('.');
        data = TT.Dev1_ai3; % Read Arena Y
        fprintf('.');
        voltages(j + 10) = mean(data);
        fprintf('.done\n');
    end
end