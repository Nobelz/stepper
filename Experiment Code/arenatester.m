function data = arenatester
daqreset
s = daq.createSession('ni');
s.DurationInSeconds = 25;
s.Rate = 10000;
lh = addlistener(s,'DataAvailable',@getdata);
addAnalogInputChannel(s,'dev1',6:7,'Voltage');

% seq = [];
% load('CurrentMSequence.mat')
% seq = cumsum(seq);
seq = mseq(2,10,round(rand*1024),round(rand*18));
seq = cumsum(seq)';
% seq = sin(linspace(0,20*pi,1000));
% seq = seq>0;
% seq = bwlabel(seq);

Panel_com('set_pattern_id',1);
Panel_com('ident_compress_off');
fprintf(' sending x function\n   ');
for j = 0:19
    start_addr = 1 + j*50;
    end_addr = start_addr + 49;
    Panel_com('send_function', [2 j seq(start_addr:end_addr)]);
    fprintf('|');
    pause(0.01);
end
fprintf('\n    ...done\n');

sync = 20*ones(size(seq));
fprintf(' sending y function\n   ');
for j = 0:19
    start_addr = 1 + j*50;
    end_addr = start_addr + 49;
    Panel_com('send_function', [1 j sync(start_addr:end_addr)]);
    fprintf('|');
    pause(0.01);
end
fprintf('\n    ...done\n');

Panel_com('set_mode',[4 4]);
Panel_com('send_gain_bias',[0 0 0 0])
Panel_com('set_position',[1 44])

data = [];
startBackground(s);
Panel_com('start');
while ~s.IsDone
    drawnow limitrate;
end
% stop
Panel_com('stop');
fprintf('  ...done\n');

seq = seq*3.75;
seq(1:3) = [];
seq = seq-seq(1);
seq = seq';

startix = find(data(:,1)>.5,1);
data = data(startix+3:end,2);

% len = min([length(data); length(seq)]);
% data = data(1:len);
% seq = seq(1:len);

data = data / 5 * 360;
data = data-data(1);

sts = linspace(1/51.3,length(seq)/51.3,length(seq));
plot(sts,seq,'k');hold on
dts = linspace(1/10000,length(data)/10000,length(data));
plot(dts,data,'r');

data = {seq,data};

function getdata(~,e)
    data = vertcat(data,e.Data);
end
end