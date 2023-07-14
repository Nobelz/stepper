 function next_sequence()
[curdir,~,~]=fileparts(mfilename('fullpath'));
fname = fullfile(curdir,'CurrentMSequence.mat');
if isfile(fname);load(fname);else;seq=[];end

outseq =[];
% wmseq=-mseq(2,8,round(rand*255),round(rand*16));
wmseq=-repmat(mseq(2,7,round(rand*127),round(rand*18)),[3 1]);
nbin=2;
for(i=1:length(wmseq))
    for(j=1:nbin)
        outseq((i-1)*nbin+j)=(j==1)*wmseq(i);
    end
end

outseq = [0 outseq];
outseq(end:1000)=0;
if ~isempty(seq) & seq==outseq
    next_sequence()
else
    seq = outseq;
    save(fname,'seq') 
end
end