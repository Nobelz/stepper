function exp_stepper_only_stripes()
%experiment code to run on stepper with striped background. Run code and wait 
%for arena configuration. When prompted arm the camera in fastec and click ok to
%begin trial.M- sequence  will repeat 3 times during the duration of the trial.
%Save trial when promped and save video from fastec

%initialize whether using conserved sequence or not. Conserved sequence is stored 
%in conserved_seq.mat otherwise when set to false need to change the
%sequence using next_sequence.m between trials 
conserve_sequence = true; 

%Load Sequence
[codedir,~,~]=fileparts(mfilename('fullpath'));
load(fullfile(codedir,'CurrentMSequence.mat'));
load('conserved_seq.mat');

              
%Set Arena Configuration
opts = struct;
opts.treatment = 'PCF';
if conserve_sequence == true
    opts.step_seq = conserved_seq;
else
    opts.step_seq = seq;
end
opts.step_rate = 50;
opts.vis_pat = 2;
opts.vis_funcx = [];
opts.vis_funcy = [];
opts.exp_dur = (round(find(seq~=0,1,'last')/opts.step_rate))+1;

%Run Experiment
exp=stepper_rig_control(opts);

%Save
btn = 'Cancel';
while strcmp(btn,'Cancel')
    btn=questdlg('Save This Trial?','Save Trial',...
        'Yes','No','Cancel','Cancel');
end
if strcmp(btn,'Yes')
    foldname = [datestr(exp.exptime,'yyyymmdd_HHMMSS_') exp.treatment '_' mfilename num2str(exp.step_rate) 'Hz'];
    mkdir(foldname);
    filename = [exp.treatment '_' mfilename num2str(exp.step_rate) 'Hz_' datestr(exp.exptime,'_yyyymmdd_HHMMSS')];
    filename = fullfile(foldname,filename);
    disp(['Saving to ' filename]);
    save(filename,'exp');
end
     
end