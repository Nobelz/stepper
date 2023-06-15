function [data, posses] = testPosition(mapping)
% Panel_com('reset', 0);
% pause(2);
data = [];

DURATION = 0.2;

%% Run
s = daq.createSession('ni');
s.Rate = 10000;
addAnalogOutputChannel(s,'dev1','ao0','Voltage');
% Add arena y channel
in = daq.createSession('ni');
in.Rate = 10000;
ch = addAnalogInputChannel(in,'dev1','ai4','Voltage');
ch.TerminalConfig = 'SingleEnded';
in.DurationInSeconds = 100 * DURATION;
lh = addlistener(in,'DataAvailable',@getdata);
posses = [];
idx = [];
data = [];
startBackground(in);
for i = 1 : 96
%     test(i, s, in);
    test(mapping, i);
    pause(DURATION);
%     idx = [idx inputSingleScan(in)];
end
outputSingleScan(s,0);
pause(DURATION);
stop(in);
plot(data);

return;

%% Section 1
Panel_com('set_pattern_id', 2);
pause(2);
Panel_com('set_mode', [3 3]);
pause(2);
Panel_com('send_gain_bias', [10 0 10 0]);
pause(2);
Panel_com('start');
pause(2);

function test(mapping, i)
%     disp(pos);
%     pos = pos - 1;
% %     pos = mod(pos, 96);
%     pos = pos * 10;
%     outputSingleScan(s, pos/1023 * 5);
    outputSingleScan(s, mapping(i));
    posses = [posses mapping(i)];
%     posses = [posses pos/1023 * 5];
%     disp(pos/1023 * 5);
%     disp(inputSingleScan(in)/ 5 * 96);
%     pause;
%     disp(inputSingleScan(in));
end

function getdata(~,e)
    data = vertcat(data,e.Data);
end

end