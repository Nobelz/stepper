function voltages = getArenaVoltages
% getArenaVoltages.m
% Gets the specific arena voltages for each index.
% Returns a 96-length row vector representing the voltage at each index
%   
% Author: Nobel Zhou
% Date: 16 June 2023
% Version: 0.2
%
% VERSION CHANGELOG:
% - v0.1 (6/14/2023): Initial commit
% - v0.2 (6/16/2023): Added comments

    fprintf('Getting Arena Voltages...\n');
    %% Setup Panel Controller and DAQ
    % Setup Panel Controller
    fprintf('\tSetting up Panel Controller');
    Panel_com('stop');
    Panel_com('set_mode', [3 3]); % Set to position control mode
    pause(0.2);
    fprintf('.');
    Panel_com('set_pattern_id', 2); % Set to striped pattern
    fprintf('.');
    Panel_com('set_position', [1 1]);
    fprintf('.done\n');
    
    % Setup DAQ
    fprintf('\tSetting up DAQ');
    in = daq('ni');
    fprintf('.');
    in.Rate = 10000;
    fprintf('.');
    ch = addinput(in,'dev1','ai4','Voltage'); % AI4 is Arena Y input
    fprintf('.');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.done\n');
    
    % Setup Output
    fprintf('\tCommencing voltage operations...\n');
    voltages = zeros(1, 96);
    
    %% Loop Through Indices
    for i = 1 : 96
        fprintf(['\t\tDetermining Voltage of Frame ' num2str(i) ' of 96']);
        Panel_com('set_position', [1 i]); % Set position to index
        fprintf('.');
        pause(2);
        fprintf('.');
    
        TT = read(in, seconds(0.5)); % Block MATLAB and collect voltage data for 0.5 seconds
        fprintf('.');
        data = TT.('Dev1_ai4');
        fprintf('.');
        voltages(i) = mean(data);
        fprintf('.done\n');
    end
end