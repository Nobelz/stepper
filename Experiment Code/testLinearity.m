function [data, time, status] = testLinearity()
% testLinearity.m
% Tests the linearity of the kernel using the individual stimulus responses
% as shown in Theobald et al., 2010, Figure 1C.
%
% Outputs:
%   - data: the actual data of the DAQ during the trial
%   - time: the time of experiment data collection
%   - status: whether data was successfully collected (1) or not (0)
%
% Author: Nobel Zhou (nxz157)
% Date: 12 July 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (7/12/2023): Initial commit

    %% Define Constants
    DAQ_RATE = 10000;
    STEPPER_PORT = 'COM3';
    STRIPED_PATTERN = 1;

    %% Setup DAQ
    fprintf('Setting up DAQ...');
    daqreset; % Reset DAQ
    
    % Initialize DAQ
    d = daq('ni');
    fprintf('.');
    d.Rate = DAQ_RATE;
    fprintf('.');
 
    % Setup input channels
    % Add arena control trigger channel
    ch = addinput(d, 'dev1', 'ai1', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');
    
    % Add fastec camera frame sync channel
    ch = addinput(d, 'dev1', 'ai2', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');
    
    % Add stepper channel
    ch = addinput(d, 'dev1', 'ai6', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');

    % Add stepper trigger channel
    ch = addinput(d, 'dev1', 'ai10', 'Voltage');
    ch.TerminalConfig = 'SingleEnded';
    fprintf('.');

    % Setup output channel
    addoutput(d, 'dev1', 'ao1', 'Voltage');
    fprintf('.');

    % Add trigger connection from arena controller
    trigger = addtrigger(d, 'Digital', 'StartTrigger', 'External', 'dev1/PFI1');
    trigger.Condition = 'RisingEdge';
    fprintf('.done\n');

    %% Setup LED Arena
    fprintf('Setting up LED Arena');
    Panel_com('clear'); % Clear LED Arena
    fprintf('.');
    Panel_com('stop'); % Stop LED Arena
    fprintf('.');
    Panel_com('stop_w_trig'); % Stop trigger
    fprintf('.done\n');

    fprintf('\tSetting trigger rate...\n');
    Panel_com('set_trigger_rate', 1);

    % Ensure trigger starts on low first
    fprintf('\tChecking trigger status...\n');
    if read(d).('Dev1_ai1') > 2
        loopTime = tic;
        checks = 1;
        while (read(d).('Dev1_ai1') > 2)
            fprintf('\t\tTrigger status check failed. Attempting to lower trigger voltage...\n');
            Panel_com('start_w_trig'); % Start trigger to advance so it's low again

            while (read(d).('Dev1_ai1') > 2) % Wait until the trigger is no longer high
                if toc(loopTime) > 10 % If 10 seconds elapsed, there is something wrong and we should stop trying
                    error('\tCould not reset arena trigger before trial within 10 seconds. Exiting...\n');
                end
                pause(0.01);
            end
            Panel_com('stop_w_trig'); % Stop trigger and check if low
            fprintf(['\t\tChecking trigger status again (Iteration ' num2str(checks) ')...\n'])
            checks = checks + 1;
        end
    end
    fprintf('\t\tTrigger status check complete.\n');

    fprintf('\tLoading pattern...\n');
    Panel_com('set_pattern_id', STRIPED_PATTERN); % Load pattern onto arena
    Panel_com('ident_compress_off'); 
    Panel_com('set_mode', [5 5]);

    fprintf('\tSetting initial position...\n');
    Panel_com('set_position', [48 48]); % Write first position
    
    fprintf('Done setting up LED Arena.\n');
    
    %% Setup Stepper
    fprintf('Setting up Stepper...\n');
   
    fprintf('\tEstablishing serial connection to stepper');

    % Make serial port
    stepper = serialport(STEPPER_PORT, 9600);
    fprintf('.');
    stepper.OutputBufferSize = 1024;
    fprintf('.');
    Stepper_com(stepper, 'reset');
    fprintf('.done\n');

    % Set to voltage mode
    fprintf('\tSetting to voltage mode...\n');
    write(d, 2); % Set to neutral state
    Stepper_com(stepper, 'voltage');

    % Generate stepper data
    fprintf('\tGenerating stepper data...\n');
    stepperInput = [zeros(1, DAQ_RATE * 0.5) ones(1, DAQ_RATE * 0.05) ...
        zeros(1, DAQ_RATE * 2.05) ones(1, DAQ_RATE * 0.05) ...
        zeros(1, DAQ_RATE * 1.85) ones(1, DAQ_RATE * 0.05) ...
        zeros(1, DAQ_RATE * 0.05) ones(1, DAQ_RATE * 0.05) ...
        zeros(1, DAQ_RATE * 1.85) ones(1, DAQ_RATE * 0.05) * 2 ...
        zeros(1, DAQ_RATE * 1.45)];
    stepperInput = [stepperInput zeros(1, DAQ_RATE) -stepperInput];
    stepperInput = [stepperInput zeros(1, DAQ_RATE * 4) stepperInput];
    stepperInput = stepperInput + 2;
    
    % Coder's note: the above generates the stepper output data. First of
    % all, we have 4 distinct 'trials' for each condition. First, we do a
    % simple step, with 0.5s before and 1.5s after. Then, we do a step
    % delayed by 100ms, so this would look like 0.6s before and 1.4s after.
    % Next, we do them both, so this would mean we have 0.5s, one step,
    % 0.1s, another step, and then 1.4s. Finally, we double the step, so we
    % would have 0.5s, 2 steps, and then 1.5s. This constitutes one full
    % "trial" of linearity test, totaling 8s. Next, we repeat it by doing
    % it for the left, as well as the right, with 1s buffer between. This
    % now means we have 2 * 8 + 1 = 17s, and we repeat this for all on and
    % stripes, with 4s buffer in between to allow for time to change the
    % pattern from stripes to all on. This means we totally have 17 * 2 + 4
    % = 38s. We add a 1s buffer on both sides for the camera and we have
    % 40s for the camera. The camera will be armed with 1s in buffer, and
    % triggered at t = 1s for the camera (t = 0s for the DAQ since the DAQ
    % starts at trigger). The DAQ will then proceed for 38 seconds, but at
    % about t = 19s for camera (t = 18s for DAQ), a switch will be made
    % from stripes to all on. Then, the DAQ will continue, with the camera
    % ending 1 second after the DAQ. A shift of +2 is necessary as the
    % voltages need to be mapped to [0 : 4]. - nxz157, 7/12/2023

    fprintf('Done setting up Stepper.\n');
    
    %% Final Preparations
    fprintf('Performing final preparations...\n');
    fprintf('\tPreloading data...\n');
    preload(d, stepperInput');

    fprintf('\tWaiting for user start signal...\n');
    uiwait(msgbox({'Please arm camera and click ok to continue', ...
        '(Required buffer length 40 seconds)'}));
    
    fprintf('Starting execution...\n');
    fprintf('\tStarting DAQ operation...\n');
    start(d); % Start DAQ collection/writing and wait for trigger
    fprintf('\tWaiting for trigger...\n');
    Panel_com('start_w_trig'); % Send trigger to camera and DAQ

    time = datetime('now'); % Record time
    tic;
    fprintf('\tTrigger received. Waiting for completion...\n');
    
    while toc < 19 % Wait until 19 seconds have elapsed
    end
    fprintf('\tSwitching to all on display...\n');
    Panel_com('stop_w_trig');
    Panel_com('all_on'); % Switch to all on

    while d.Running % Wait until DAQ is finished
        drawnow;
    end

    fprintf('\tData collection received.\nReading data..');
    data = read(d, 'all'); % Reads all input data
    fprintf('.done\n');

    %% Reset and Cleanup Operations
    fprintf('Performing cleanup...\n');
    fprintf('\tStopping Arena...\n');
    Panel_com('stop_w_trig'); % Stop triggering and stop arena
    
    fprintf('\tResetting Stepper...\n');
    Stepper_com(stepper, 'reset'); % Reset stepper to exit voltage loop

    fprintf('\tClearing DAQ...\n');
    clear d % Delete DAQ
    
    %% Data Verification
    fprintf('Verifying data...\n');
    fprintf('\tVerifying fly flight...\n');

    btn = questdlg('If the fly did not stop flying, please select Yes. The default value is No.', 'Save This Trial?', 'Yes', 'No', 'No');
    
    if strcmp(btn, 'Yes')
        status = 1;
        fprintf('Successfully collected data!\n');
    else
        status = 0;
        fprintf('Unsuccessful data collection.\n');
    end
end
    