%reads marker channel data from fastec xml and pm files

%output is six-row logical matrix of same length as the video
%{ 
    Row     Channel
    ===     ========
    1       ARM OUT
    2       ARM IN
    3       SYNC OUT
    4       SYNC IN
    5       TRIGGER OUT
    6       TRIGGER IN
%}
function markout = fastecMarkerReader(fname,ix)

%get particuar channel or channels, specified as a vector containing valid
%channel indices (1 through six);
if nargin<2
    ix = 1:6;
else
    if any(ix<1 | ix>6)
        error('Invalid Marker Indices requested');
    end
end

%handle file input
if nargin<1
    [fname, path] = uigetfile({'*.xml;*.pm';'*.xml';'*.pm'});
    if fname == 0
        return
    end
    fname = fullfile(path,fname);
end

[~,~,ext] = fileparts(fname);
fid = fopen(fname);
marker = [];
       
while(~feof(fid))
    switch ext
        %xml files are human-readable and the user has the option of
        %exporting them from the camera at save time. also have meta-data
        case '.xml' 
            tline = fgets(fid);
            ixs = strfind(tline,'<markers>0x'); %get marker starts
            ixe = strfind(tline,'</markers>'); %get marker ends
            %sometimes the XML file has everything in one line. sometimes
            %not. this code works for both.
            if ~isempty(ixs) && length(ixs) == length(ixe) %make sure line has markers and they are formatted right
                for j = 1:length(ixs)
                    marker = [marker hex2dec(tline(ixs(j)+11:ixe(j)-1))];%get the marker bytes
                end
            end
        %pm files are generated when a file has been copied off the ssd
        %on the camera. I've found that every 12th byte in a 32 byte read 
        %frame has the marker data 
        case '.pm'
            %read every 32 bytes (metadata for one frame)
            a = fread(fid,32);
            if ~isempty(a)
                %take the 12th byte which has the marker data
                marker = [marker a(12)];                
            end            
        otherwise
            error('Filetype Not Recognized');
    end
end

%turn the marker bytes into matrix of 1s and 0s for each channel
markout =[];
for i = 1:6
    bitgot = bitget(marker,i);
    markout = [markout; bitgot];
end
markout = logical(markout);
markout = markout(ix,:);
fclose(fid);
end
