function mapping = getMapping
% getMapping.m
% Gets the specific arena voltages for each index.
% Returns a 96-length row vector representing the voltage at each index
%   
% Author: Nobel Zhou
% Date: 14 June 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (6/14/2023): Initial commit

    fprintf('Getting Mapping...\n');
    %% Get Arena Voltages
    voltages = getArenaVoltages();
    save('voltages', 'voltages');
    
    %% Setup DAQ and Panel Controller
    % Setup Panel Controller
    fprintf('\tSetting up Panel Controller');
    Panel_com('stop'); % Stop before changing panel controller settings
    pause(1);
    fprintf('.');
    Panel_com('set_mode', [3 3]); % Set to position control mode
    pause(2);
    fprintf('.');
    Panel_com('set_pattern_id', 2); % Set to striped pattern
    pause(2);
    fprintf('.');
    Panel_com('send_gain_bias', [10 0 10 0]);
    pause(1);
    fprintf('.');
    Panel_com('start'); % Start panel controller using voltage setting
    pause(2);
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
    fprintf('.');
    
    out = daq('ni');
    fprintf('.');
    out.Rate = 10000;
    fprintf('.');
    addoutput(out,'dev1','ao0','Voltage');
    fprintf('.');
    fprintf('.done\n');
    
    fprintf('\tCommencing mapping operation...\n');
    % Use previous mapping file if supplied
    if isfile('mapping.mat')
        load('mapping.mat', 'mapping');
    else
        mapping = linspace(0, 950 / 1023 * 5, 96); % Generate good "guesses" for voltages
    end
    for i = 1 : 96
        voltageCompliant = 0;
        fprintf(['\t\tMapping Frame ' num2str(i) ' of 96...\n']);
        while ~voltageCompliant
            v = mapping(i);
            fprintf(['\t\t\tTrying voltage of ' num2str(v) '...\n']);
            write(out, v);
    
            TT = read(in, seconds(5)); % Block MATLAB and collect voltage data for 5 seconds
            data = TT.('Dev1_ai4');
            plot(data);
            drawnow;
            data = data - voltages(i);
            if (~isempty(find(data > 0.035, 1)))
                mapping(i:end) = mapping(i:end) - 0.002;
                fprintf('\t\t\t\tMapping noncompliant. Decrementing voltage...\n');
            elseif (~isempty(find(data < -0.035, 1)))
                mapping(i:end) = mapping(i:end) + 0.002;
                fprintf('\t\t\t\tMapping noncompliant. Incrementing voltage...\n');
            else
                fprintf('\t\t\tMapping compliant. Proceeding to next index...\n');
                voltageCompliant = 1;
            end
        end
    end
    fprintf('\tSaving mapping...\n');
    save('mapping', 'mapping');
    fprintf('Mapping done.\n');

end
