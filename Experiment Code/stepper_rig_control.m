function exp = stepper_rig_control(opts)

%make sure configuration struct is defined
if nargin<1
    error('Configuration Struct Required');
end

if isempty(opts.treatment)
    opts.treatment = 'PCF';
end 
if isempty(opts.gain)
    opts.gain = 1;
end
if isempty(opts.vis_funcx)
    opts.vis_funcx = ones(1,1000);
end
if isempty(opts.vis_funcy)
    opts.vis_funcy = ones(1,1000);
end
usevfunc = true;
if all(opts.vis_funcx==1) && all(opts.vis_funcy==1);usevfunc=false;end

if isempty(opts.vis_pat)
    opts.vis_pat = 'all_on';
end

%% setup arena
disp('Setting up flight arena')
Panel_com('clear')
if ~isnumeric(opts.vis_pat)
    Panel_com(opts.vis_pat)
    Panel_com('set_mode',[0 0]);
else
    fprintf([' loading pattern ' num2str(opts.vis_pat) '\n']);
    Panel_com('set_pattern_id',opts.vis_pat);
    fprintf('    ...done\n');
    % send functions if defined
    if usevfunc
        Panel_com('ident_compress_off');
        fprintf(' sending x function\n   ');
        for j = 0:19
            start_addr = 1 + j*50;
            end_addr = start_addr + 49;
            Panel_com('send_function', [2 j opts.vis_funcx(start_addr:end_addr)]);
            fprintf('|');
            pause(0.01);
        end
        fprintf('\n    ...done\n');
        
        fprintf(' sending y function\n   ');
        for j = 0:19
            start_addr = 1 + j*50;
            end_addr = start_addr + 49;
            Panel_com('send_function', [1 j opts.vis_funcy(start_addr:end_addr)]);
            fprintf('|');
            pause(0.01);
        end
        fprintf('\n    ...done\n');
        
        Panel_com('set_mode',[4 4]);
        Panel_com('send_gain_bias',[0 0 0 0])
        Panel_com('set_position',[44 44])
    else
        Panel_com('set_mode',[0 0]);
        Panel_com('send_gain_bias',[0 0 0 0])
        Panel_com('set_position',[44 44])
    end    
end

%% setup daq
disp('Setting up DAQ');
daqreset;
s = daq.createSession('ni');
s.DurationInSeconds = opts.exp_dur;
s.Rate = 10000;
lh = addlistener(s,'DataAvailable',@getdata);

%add arena control trigger channel
ch = addAnalogInputChannel(s,'dev1','ai1','Voltage');
ch.TerminalConfig = 'SingleEnded';

% if voltage on this channel is stuck high turn it on and off again to
% reset it to 0v
if inputSingleScan(s)> 2
    Panel_com('set_trigger_rate', 1) % make rate slow enough for us to catch
    Panel_com('start_w_trig');
    loopctrl = true;
    loopt = tic;
    while(loopctrl)
        if inputSingleScan(s) < 2
            loopctrl = false;
        end
        if toc(loopt)>10
            loopctrl = false;
            warning('Could not reset arena sync before trial');
        end
        drawnow;
    end 
    Panel_com('stop_w_trig');
end

%add fastec camera frame sync channel
ch = addAnalogInputChannel(s,'dev1','ai2','Voltage');
ch.TerminalConfig = 'SingleEnded';

%add arena x channel
ch = addAnalogInputChannel(s,'dev1','ai3','Voltage');
ch.TerminalConfig = 'SingleEnded';

%add arena y channel
ch = addAnalogInputChannel(s,'dev1','ai4','Voltage');
ch.TerminalConfig = 'SingleEnded';

%trigger with arena controller
s.addTriggerConnection('external','dev1/PFI1','StartTrigger');

fprintf('    ...done\n');

%% initialize stepper controller
disp('Setting up stepper motor');
stepper_com('reset');

if ~isempty(opts.step_seq) % don't send if there isn't one.
    fprintf(' sending stepper function\n');
    %step on each trigger pulse
    stepper_com('set_trig_mode','start_on_trig');
    %send rate and sequence
    stepper_com('set_sequence_rate',opts.step_rate);
    stepper_com('send_sequence',opts.step_seq);
    % Send gain
    stepper_com('set_sequence_gain', opts.gain);
    
    Panel_com('set_trigger_rate',opts.step_rate);
    
    fprintf('    ...done\n');
else
    fprintf(' no stepper for this experiment\n');
    % Panel_com('set_trigger_rate',51);    
    % Panel_com('set_trigger_rate', opts.step_rate)
end
%% run and get data
disp('Waiting for user start signal...')
uiwait(msgbox({'Please arm camera and click ok to continue',...
['(Required buffer length ' num2str(opts.exp_dur) ' seconds)']}));
fprintf(' beginning trial\n');
opts.exptime = now;
data = [];
startBackground(s);
Panel_com('start_w_trig');
while ~s.IsDone
    drawnow limitrate;
end
% stop
Panel_com('stop_w_trig');
fprintf('  ...done\n');
%% output data to workspace if required
if nargout>0
    exp = opts;
    exp.daq.data = data;
    exp.daq.fs = s.Rate;
    exp.daq.channelnames = {'Arena Sync','Camera Sync','Arena_X','Arena_Y'};
end

    function getdata(~,e)
        data = vertcat(data,e.Data);
    end
end