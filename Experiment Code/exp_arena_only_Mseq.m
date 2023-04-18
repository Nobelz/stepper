 function exp_arena_only_Mseq(seq, flyNum, flyTrial)

if nargin<1 || length(seq)~=1000
    if nargin>0
        warning('Sequence Length Incorrect Loading M-Sequence File');
    end
    %Load Sequence
    [codedir,~,~]=fileparts(mfilename('fullpath'));     
     load(fullfile(codedir,'CurrentMSequence.mat'));
     dur = (round(find(seq~=0,1,'last')/50))+1;
     seq = cumsum(seq);
%      upseq = resample(seq,2550,50);
%      seq = resample(upseq,51,2550);
%      seq = seq(1:1000);
     seq = seq-seq(1);
else
    dur = 16;
end

%Set Arena Configuration
opts = struct;
opts.treatment = 'PCF';
opts.step_seq = [];
opts.step_rate = [100]; 
opts.vis_pat = 2;
opts.vis_funcx = seq;
opts.vis_funcy = seq;
opts.exp_dur = dur;

%Run Experiment
exp=stepper_rig_control(opts); 

%Save
btn = 'Cancel';
while strcmp(btn,'Cancel')
    btn=questdlg('Save This Trial?','Save Trial',...
        'Yes','No','Cancel','Cancel');
end
if strcmp(btn,'Yes')
    foldname = [datestr(exp.exptime,'yyyymmdd_HHMMSS_') exp.treatment '_' mfilename];
    mkdir(foldname);
    if flyTrial > 0
        filename = [exp.treatment num2str(flyNum) 'T' num2str(flyTrial) '_' mfilename datestr(exp.exptime,'_yyyymmdd_HHMMSS')];
    else
        filename = [exp.treatment num2str(flyNum) 'con_' mfilename datestr(exp.exptime,'_yyyymmdd_HHMMSS')];
    end
    filename = fullfile(foldname,filename);
    disp(['Saving to ' filename]);
    save(filename,'exp');
end

end