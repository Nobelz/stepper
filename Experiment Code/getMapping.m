  function mappingX = getMapping
% getMapping.m
% Gets the specific arena voltages for each index.
% Returns a 100-length row vector representing the voltage at each index
%   
% Author: Nobel Zhou
% Date: 14 June 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (6/14/2023): Initial commit

    fprintf('Getting Mapping...\n');
    %% Get Arena Voltages
    load('voltages.mat', 'voltages');
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
    Panel_com('set_pattern_id', 1); % Set to striped pattern
    pause(2);
    fprintf('.');
    Panel_com('send_gain_bias', [100 0 100 0]);
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
    ch = addinput(in,'dev1','ai10','Voltage'); % AI10 is Arena X input
    ch = addinput(in,'dev1','ai3','Voltage'); % AI3 is Arena Y input
    fprintf('.');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');
    
    out = daq('ni');
    fprintf('.');
    out.Rate = 10000;
    fprintf('.');
    addoutput(out,'dev1','ao0','Voltage'); % Arena X output
    addoutput(out,'dev1','ao1','Voltage'); % Arena Y output
    fprintf('.');
    fprintf('.done\n');
    
    fprintf('\tCommencing mapping operation...\n');
    % Use previous mapping file if supplied
    if isfile('mapping.mat')
        load('mapping.mat', 'mappingX', 'mappingY');
    else
        % Generate good "guesses" for voltages
        mappingX = linspace(0, 1000 / 1023 * 5, 10); 
        mappingY = linspace(0, 1000 / 1023 * 5, 10);
    end

    for j = 1 : 10
        voltageCompliant = 0;
        fprintf(['\t\tY: Mapping Frame ' num2str(j) ' of 10...\n']);
        while ~voltageCompliant
            v = mappingY(j);
            fprintf(['\t\t\tTrying voltage of ' num2str(v) '...\n']);
            write(out, [0, v]);
    
            TT = read(in, seconds(5)); % Block MATLAB and collect voltage data for 5 seconds
            data = TT.Dev1_ai3;
            plot(data);
            drawnow;
            data = data - voltages(j + 10);
            if (~isempty(find(data > 0.1, 1)))
                mappingY(j:end) = mappingY(j:end) - 0.1;
                fprintf('\t\t\t\tMapping noncompliant. Decrementing voltage...\n');
            elseif (~isempty(find(data < -0.1, 1)))
                mappingY(j:end) = mappingY(j:end) + 0.1;
                fprintf('\t\t\t\tMapping noncompliant. Incrementing voltage...\n');
            else
                fprintf('\t\t\tMapping compliant. Proceeding to next index...\n');
                voltageCompliant = 1;
            end
        end
    end

    for i = 1 : 10
        voltageCompliant = 0;
        fprintf(['\t\tX: Mapping Frame ' num2str(i) ' of 10...\n']);
        while ~voltageCompliant
            v = mappingX(i);
            fprintf(['\t\t\tTrying voltage of ' num2str(v) '...\n']);
            write(out, [v, 0]);
    
            TT = read(in, seconds(5)); % Block MATLAB and collect voltage data for 5 seconds
            data = TT.Dev1_ai10;
            plot(data);
            drawnow;
            data = data - voltages(i);
            if (~isempty(find(data > 0.1, 1)))
                mappingX(i:end) = mappingX(i:end) - 0.1;
                fprintf('\t\t\t\tMapping noncompliant. Decrementing voltage...\n');
            elseif (~isempty(find(data < -0.1, 1)))
                mappingX(i:end) = mappingX(i:end) + 0.1;
                fprintf('\t\t\t\tMapping noncompliant. Incrementing voltage...\n');
            else
                fprintf('\t\t\tMapping compliant. Proceeding to next index...\n');
                voltageCompliant = 1;
            end
        end
    end

    fprintf('\tSaving mapping...\n');
    save('mapping', 'mappingX', 'mappingY');
    fprintf('Mapping done.\n');
    
end
