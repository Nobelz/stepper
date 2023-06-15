function voltages = getArenaVoltages
% getArenaVoltages.m
% Gets the specific arena voltages for each index.
% Returns a 96-length row vector representing the voltage at each index
%   
% Author: Nobel Zhou
% Date: 14 June 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (6/14/2023): Initial commit

%% Setup Panel Controller and DAQ
% Setup Panel Controller
Panel_com('stop');
Panel_com('set_position', [1 1]);

% Setup DAQ
in = daq('ni');
in.Rate = 10000;
ch = addinput(in,'dev1','ai4','Voltage'); % AI4 is Arena Y input
ch.TerminalConfig = 'SingleEnded';

% Setup Output
voltages = zeros(1, 96);

%% Loop Through Indices
for i = 1 : 96
    Panel_com('set_position', [i i]); % Set position to index
    pause(0.2);

    TT = read(in, seconds(0.5)); % Block MATLAB and collect voltage data for 0.5 seconds
    data = TT.('Dev1_ai4');
    voltages(i) = mean(data);
end
end