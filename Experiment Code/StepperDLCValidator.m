function StepperDLCValidator()
% StepperDLCValidator.m
% Validates DLC pose estimations with custom GUI.
%
% Author: Mike Rauscher and Nobel Zhou
% Date: 19 July 2023
% Version: 0.2
%
% VERSION CHANGELOG:
% - v0.1 (???): Initial commit
% - v0.2 (7/19/2023): Make code more readable

    %% Define Constants
    SHOW_WINGS = 0;
    DLC_FOLDER = '../../StepperTether-FoxLab-2023-07-17';
    
    %% Load Settings
    % Locate settings file
    directory = pwd;
    settingsFile = [directory filesep 'stepperdlcvalidator.set'];
    
    % Load settings if found
    if isfile(settingsFile)
        load(settingsFile, '-mat', 'settings'); % Load settings from file
        autosave = settings.autosave;
        directory = settings.dir;

        [fnames, dispnames, csvnames, savenames] = getVideoNames(directory);

        lastVideoIndex = find(strcmp(fnames, settings.lastfile), 1); % Find the last video open

        % If last video cannot be found, just go to the first one
        if isempty(lastVideoIndex)
            lastVideoIndex = 1;
        end
    else
        % Have user get the correct directory
        directory = uigetdir('.', 'Select Video Folder');
        [fnames, dispnames, csvnames, savenames] = getVideoNames(directory);

        autosave = 0;
        lastVideoIndex = 1; % Start at first video
    end

    fly = [];
    markers = [];
    vread = VideoReader(fnames{lastVideoIndex});
    vtimer = timer('Period', .01, 'TimerFcn', @nextframe, 'ExecutionMode', 'fixedRate');
    pcols = hsv(13);
    BCOLOR = [253,141,60]./255;
    HCOLOR = [43,140,190]./255;

ptnames = {...
    'LeftAntMed',...
    'LeftAntDist',...
    'RightAntMed',...
    'RightAntDist',...
    'LeftWingRoot',...
    'RightWingRoot',...
    'LeftShoulder',...
    'RightShoulder',...
    'Neck',...
    'Waist',...
    'Abdomen',...
    'LeftWingTip',...
    'RightWingTip'};
showpts = [];
csv = [];
Xpts = [];
Ypts = [];
Pval = [];
HeadAng = [];HeadPts = [];
BodyAng = [];BodyPts = [];
bodymethod = 1;
headmethod = 1;

loop = false;
f = 1;
cix = lastVideoIndex;
if isfile(savenames{cix})
    fly = [];
    load(savenames{cix});
    csv = fly.csv;
    Xpts = fly.pts.X;
    Ypts = fly.pts.Y;
    Pval = fly.pts.P;
    markers = fly.track.frameidx;
    bodymethod = fly.track.bodymethod;
    headmethod = fly.track.headmethod;
else
    loadcsv;
end
getheadang;
getbodyang;
numframes = vread.NumFrames;
curframe = setframeix(1);
vwidth = vread.Width;
vheight = vread.Height;
hyp = sqrt(vwidth^2 + vheight^2);
vwidth = round(768*(vwidth/vheight));
vheight = 768;
uiheight = vheight;
uiwidth = vwidth+480;

c = figure('Name','Stepper DLC Validator','NumberTitle','off',...
    'MenuBar','none','Position',[100 100 1280 800],...
    'CloseRequestFcn',@onClose,'SizeChangedFcn',@szch);

fileslist = uicontrol(c,'Style','listbox','String',dispnames,...
    'Position',[0 0 480 600],'Callback',@buttons,'Value',lastVideoIndex);

vidax = axes(c,'unit','pixel','Position',[480 0 vwidth vheight],'XTick',[],'YTick',[]);
datax = axes(c,'unit','pixel','Position',[0 0 100 100]);
zoomax = axes(c,'unit','pixel','Position',[0 0 100 100]);
edlines = plot(datax,nan,nan);
xlim(datax,[0 numframes]);
xticks(datax,[1 500:500:numframes]);
datax.XTickLabelRotation = 45;
ylim(datax,[-180 180]);
yticks(datax,-180:45:180);
xlabel(datax,'Frame #');
hold(datax,'on');
bodyline = plot(datax,1:numframes,BodyAng,'--','Color',BCOLOR,'LineWidth',2.5);
headline = plot(datax,1:numframes,HeadAng,'Color',HCOLOR,'LineWidth',1);
fline = xline(datax,1,'LineWidth',1.5);
datax.XGrid = 'on';
datax.YGrid = 'on';
hold(datax,'off');
datax.ButtonDownFcn = @buttons;

hold(zoomax,'on')
bodyzmline = plot(zoomax,1:numframes,BodyAng,'--','Color',BCOLOR,'LineWidth',2.5);
headzmline = plot(zoomax,1:numframes,HeadAng,'Color',HCOLOR,'LineWidth',1);
zmfline = xline(zoomax,1,'LineWidth',1);
zoomax.XGrid = 'on';
zoomax.YGrid = 'on';
zoomax.XTick = 1:numframes;
hold(zoomax,'off');

im = image(vidax,curframe);
hold(vidax,'on');
bodyaxline = plot(vidax,[nan nan],[nan nan],'--','Color',BCOLOR,'LineWidth',2);
headaxline = plot(vidax,[nan nan],[nan nan],'Color',HCOLOR,'LineWidth',2);
if SHOW_WINGS
    wingLline = plot(vidax,[nan nan],[nan nan],'Color','r','LineWidth',2);
    wingRline = plot(vidax,[nan nan],[nan nan],'Color','r','LineWidth',2);
end
drpts = plot(vidax,nan,nan,'*','Color','m','Visible','off');
edpts = {};
if SHOW_WINGS;uptopt = 13;else;uptopt = 11;end
for ptix = 1:uptopt
    edpts{end+1} = images.roi.Point(vidax);
    edpts{end}.Color = pcols(ptix,:);
    edpts{end}.Label = ptnames{ptix};
    edpts{end}.LabelVisible = 'hover';
    edpts{end}.Deletable = false;
    addlistener(edpts{end},'MovingROI',@eventcb);
    addlistener(edpts{end},'ROIMoved',@eventcb);
end
xticks(vidax,[]);
yticks(vidax,[]);
hold(vidax,'off');
%we'll not set the layout here instead do everything with sizechangedfcn
dispdir = uicontrol(c,'Style', 'edit','ToolTip',directory,... 
    'String',directory,'ButtonDownFcn',@buttons,...
    'Position', [0 0 480 40],'Enable','off');

playpause = uicontrol(c,'Style','pushbutton','String','>',...
    'Position',[0 143 48 25],'Callback',@buttons,'FontSize',20);

stopbutton = uicontrol(c,'Style','pushbutton','String',string(char(11036)),...
    'Position',[0 143 48 25],'Callback',@buttons,'FontSize',20);

dispframe = uicontrol(c,'Style', 'edit',... 
    'String',['Frame 1 of ' num2str(numframes)],'ButtonDownFcn',@buttons,...
    'Position', [52 143 428 25],'Enable','off');

progress = uicontrol(c,'Style','slider', 'Min',1,'Max',numframes,'Value',1,...
    'SliderStep',[1/(numframes-1) 1/(numframes-1)],...
    'Position',[0 118 480 25],'Callback',@buttons);

nextfilebtn = uicontrol(c,'Style','pushbutton','String','V',...
    'Position',[0 0 1 1],'Callback',@buttons,'FontSize',28);
prevfilebtn = uicontrol(c,'Style','pushbutton','String',string(char(923)),...
    'Position',[0 0 1 1],'Callback',@buttons,'FontSize',28);

autosavecheck = uicontrol(c,'Style','checkbox','String','Autosave',...
    'Position',[0 0 1 1],'Value',autosave);
savebutton = uicontrol(c,'Style','pushbutton','String','Save',...
    'Position',[0 0 1 1],'Callback',@buttons);
deletebutton = uicontrol(c,'Style','pushbutton','String','Delete',...
    'Position',[0 0 1 1],'Callback',@buttons);
quitbutton = uicontrol(c,'Style','pushbutton','String','Quit',...
    'Position',[0 0 1 1],'Callback',@buttons);

nextframebtn = uicontrol(c,'Style','pushbutton','String','>',...
    'Position',[0 0 1 1],'Callback',@buttons);
prevframebtn = uicontrol(c,'Style','pushbutton','String','<',...
    'Position',[0 0 1 1],'Callback',@buttons);

Body7UDbtn = uicontrol(c,'Style','pushbutton','String','7pt Body',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
Body6UDbtn = uicontrol(c,'Style','pushbutton','String','6pt Body',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
Body4LRbtn = uicontrol(c,'Style','pushbutton','String','4Pt LR Body',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
Body4UDbtn = uicontrol(c,'Style','pushbutton','String','4Pt UD Body',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
Body2Sbtn = uicontrol(c,'Style','pushbutton','String','Shoulders',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
Body2Wbtn = uicontrol(c,'Style','pushbutton','String','Wing Roots',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
bodybtns = [Body7UDbtn,Body6UDbtn,Body4LRbtn,...
    Body4UDbtn,Body2Sbtn,Body2Wbtn];

Head7UDbtn = uicontrol(c,'Style','pushbutton','String','7Pt Head',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
Head6UDbtn = uicontrol(c,'Style','pushbutton','String','6Pt Head',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
Head4LRbtn = uicontrol(c,'Style','pushbutton','String','4Pt LR Head',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
Head4UDbtn = uicontrol(c,'Style','pushbutton','String','4Pt UD Head',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
Head2Tbtn = uicontrol(c,'Style','pushbutton','String','Tips',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
Head2Rbtn = uicontrol(c,'Style','pushbutton','String','Roots',...
    'Position',[0 0 1 1],'Callback',@updatetrackingparams);
headbtns = [Head7UDbtn,Head6UDbtn,Head4LRbtn,Head4UDbtn,Head2Tbtn,Head2Rbtn];

updatetrackingparams(headbtns(headmethod));
        
deletemarkerbtn = uicontrol(c,'Style','pushbutton','String','Revert Frame to CSV',...
    'Position',[0 0 1 1],'Callback',@buttons);
gotomarkerbtn = uicontrol(c,'Style','pushbutton','String','Goto Fixed Frame',...
    'Position',[0 0 1 1],'Callback',@buttons);
markerlist = uicontrol(c,'Style','popupmenu','String',' ',...
    'Position',[0 55 200 23]);

nextmarkerbtn = uicontrol(c,'Style','pushbutton','String','V',...
    'Position',[0 0 1 1],'Callback',@buttons);
prevmarkerbtn = uicontrol(c,'Style','pushbutton','String',string(char(923)),...
    'Position',[0 0 1 1],'Callback',@buttons);
szch(c);
c.WindowState='maximized';

if isfile(savenames{lastVideoIndex})
    updatemarkers;
end
curframe = setframeix(1);
showframe;

    function updatetrackingparams(h,~)
        if SHOW_WINGS
            showpts = [5,6,12,13];
        else
            showpts = [];
        end
        mx = find(h==bodybtns);
        if ~isempty(mx)
            bodymethod = mx;
        end
        for i = 1:6
            if i==bodymethod
                bodybtns(i).Enable = 'off';
            else
                bodybtns(i).Enable = 'on';
            end
        end
        getbodyang();
        bodyline.YData = BodyAng;
        bodyzmline.YData =BodyAng;
        
        mx = find(h==headbtns);
        if ~isempty(mx)
            headmethod = mx;
        end
        for i = 1:4
            if i==headmethod
                headbtns(i).Enable = 'off';
            else
                headbtns(i).Enable = 'on';
            end
        end
        getheadang()
        headline.YData = HeadAng;
        headzmline.YData = HeadAng;
        if strcmp(vtimer.Running,'off')
            for i = 1:uptopt
                if ismember(i,showpts)
                    edpts{i}.Visible = 'on';
                else
                    edpts{i}.Visible = 'off';
                end
            end
            showframe;
        end
    end

    function nextframe(~,~)
        if (f+1)>numframes
            if loop
                curframe = setframeix(1);
            else
                stop(vtimer);
                playpause.String = '>';
            end
        else
            curframe = setframeix(f+1);
        end
        showframe();
    end

    function showframe()
        im.CData = curframe;
        xdat = Xpts(f,:);
        ydat = Ypts(f,:);
        badix = Pval(f,:)<.90;
        
        bpts = BodyPts(f,:);
        bodyaxline.XData = bpts([1 3]);
        bodyaxline.YData = bpts([2 4]);
        
        hpts = HeadPts(f,:);
        headaxline.XData = hpts([1 3]);
        headaxline.YData = hpts([2 4]);
        if strcmp(vtimer.Running,'on')
            drpts.XData = xdat(showpts);
            drpts.YData = ydat(showpts);
        else
            for i = 1:uptopt
                edpts{i}.Position = [xdat(i) ydat(i)];
            end
        end
        xdat(badix) = nan;
        ydat(badix) = nan;
        if SHOW_WINGS
            wingLline.XData = xdat([5 12]);wingLline.YData = ydat([5 12]);
            wingRline.XData = xdat([6 13]);wingRline.YData = ydat([6 13]);
        end
        
        zoomax.XLim = [f-10 f+10];
        drawnow limitrate;
    end

    function getbodyang()
        X = Xpts;
        Y = Ypts;
        switch bodymethod
            case 1 %7Pt LR
                showpts = [showpts 5:11];
                ctr = [mean(X(:,5:8),2) mean(Y(:,5:8),2)];
                upt = [mean(X(:,[7:9]),2) mean(Y(:,[7:9]),2)];
                dnt = [mean(X(:,[5,6,10,11]),2) mean(Y(:,[5,6,10,11]),2)];
                BodyAng = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 2 %6PT UD
                showpts = [showpts 5:10];
                ctr = [mean(X(:,5:8),2) mean(Y(:,5:8),2)];
                upt = [mean(X(:,[7:9]),2) mean(Y(:,[7:9]),2)];
                dnt = [mean(X(:,[5,6,10]),2) mean(Y(:,[5,6,10]),2)];
                BodyAng = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 3 %4Pt LR
                showpts = [showpts 5:8];
                ctr = [mean(X(:,5:8),2) mean(Y(:,5:8),2)];
                Lt = [mean(X(:,[5,7]),2) mean(Y(:,[5,7]),2)];
                Rt = [mean(X(:,[6,8]),2) mean(Y(:,[6,8]),2)];
                BodyAng = (atan2d(Lt(:,2)-Rt(:,2),Lt(:,1)-Rt(:,1)))+90;
            case 4 %4Pt UD
                showpts = [showpts 5:8];
                ctr = [mean(X(:,5:8),2) mean(Y(:,5:8),2)];
                upt = [mean(X(:,[7,8]),2) mean(Y(:,[7,8]),2)];
                dnt = [mean(X(:,[5,6]),2) mean(Y(:,[5,6]),2)];
                BodyAng = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 5 %Shoulders
                showpts = [showpts 7:8];
                ctr = [mean(X(:,[7,8]),2) mean(Y(:,[7,8]),2)];
                BodyAng = atan2d(Y(:,8)-Y(:,7),X(:,8)-X(:,7))+90;
            case 6 %WingRoots
                showpts = [showpts 5:6];
                ctr = [mean(X(:,[5,6]),2) mean(Y(:,[5,6]),2)];
                BodyAng = atan2d(Y(:,6)-Y(:,5),X(:,6)-X(:,5))+90;
        end
        showpts = unique(showpts);
        BodyPts = [ctr(:,1) + 200*cosd(BodyAng) ctr(:,2) + 200*sind(BodyAng) ctr(:,1) - 200*cosd(BodyAng) ctr(:,2) - 200*sind(BodyAng)];
        BodyAng = BodyAng-BodyAng(1);
        BodyAng = wrapTo180(BodyAng);
    end

    function getheadang()
        X = Xpts;
        Y = Ypts;
        switch headmethod
            case 1 %Head 7UD
                showpts = [showpts,1:4,7:9];
                ctr = [mean(X(:,[1:4 7:9]),2) mean(Y(:,[1:4 7:9]),2)];
                upt = [mean(X(:,[1:4]),2) mean(Y(:,[1:4]),2)];
                dnt = [mean(X(:,[7:9]),2) mean(Y(:,[7:9]),2)];
                HeadAng = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 2 %Head 6UD
                showpts = [showpts,1:4,7:8];
                ctr = [mean(X(:,[1:4 7:8]),2) mean(Y(:,[1:4 7:8]),2)];
                upt = [mean(X(:,[1:4]),2) mean(Y(:,[1:4]),2)];
                dnt = [mean(X(:,[7:8]),2) mean(Y(:,[7:8]),2)];
                HeadAng = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 3 %Head 4LR
                showpts = [showpts 1:4];
                ctr = [mean(X(:,[1:4]),2) mean(Y(:,[1:4]),2)];
                Lt = [mean(X(:,[1,2]),2) mean(Y(:,[1,2]),2)];
                Rt = [mean(X(:,[3,4]),2) mean(Y(:,[3,4]),2)];
                HeadAng = (atan2d(Lt(:,2)-Rt(:,2),Lt(:,1)-Rt(:,1)))+90;
            case 4 %Head 4UD
                showpts = [showpts 1:4];
                ctr = [mean(X(:,[1:4]),2) mean(Y(:,[1:4]),2)];
                upt = [mean(X(:,[2,4]),2) mean(Y(:,[2,4]),2)];
                dnt = [mean(X(:,[1,3]),2) mean(Y(:,[1,3]),2)];
                HeadAng = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 5 %Tips only
                showpts = [showpts 2,4];
                ctr = [mean(X(:,[2,4]),2) mean(Y(:,[2,4]),2)];
                HeadAng = atan2d(Y(:,4)-Y(:,2),X(:,4)-X(:,2))+90;
            case 6 %Roots only
                showpts = [showpts 1,3];
                ctr = [mean(X(:,[1,3]),2) mean(Y(:,[1,3]),2)];
                HeadAng = atan2d(Y(:,3)-Y(:,1),X(:,3)-X(:,1))+90;
        end
        showpts = unique(showpts);
        HeadPts = [ctr(:,1) + 30*cosd(HeadAng) ctr(:,2) + 30*sind(HeadAng) ctr(:,1) - 30*cosd(HeadAng) ctr(:,2) - 30*sind(HeadAng)];
        HeadAng = HeadAng-HeadAng(1);
        HeadAng = wrapTo180(HeadAng);
    end

    function eventcb(h,e)
        pix = find(strcmp(ptnames,h.Label));
        Xpts(f,pix) =  h.Position(1);
        Ypts(f,pix) =  h.Position(2);
        Pval(f,pix) = inf;%will still be higher than any cutoff but also unambiguously an edited point
        getbodyang();
        getheadang();
        if strcmp(e.EventName,'ROIMoved')
            bodyline.YData = BodyAng;
            bodyzmline.YData = BodyAng;
            headline.YData = HeadAng;
            headzmline.YData = HeadAng;
            mx = find(markers==f,1);
            if isempty(mx)
                markers = [markers; f];
                updatemarkers;
            end
        end
        showframe();
        
    end

    function buttons(b, e)
        switch b
            case dispdir
                return
%                 d = uigetdir(curdir);
%                 if d==0;return;end                
%                 [fnames,dispnames,cnames] = getvideonames(d);
%                 if isempty(fnames)
%                     msgbox('No videos in this folder');
%                     return
%                 end
%                 curdir = d;
%                 b.String = d;
%                 fileslist.Value = 1;
%                 fileslist.String = dispnames;
%                 loadvid(1);
            case fileslist
                if b.Value~=cix && autosavecheck.Value == 1
                    buttons(savebutton,[]);
                end
                loadvid(b.Value);
            case nextfilebtn
                if fileslist.Value~=length(fnames)
                    if autosavecheck.Value == 1
                        buttons(savebutton,[]);
                    end
                    fileslist.Value = fileslist.Value+1;
                    loadvid(fileslist.Value);
                end
            case prevfilebtn                
                if fileslist.Value~=1
                    if autosavecheck.Value == 1
                        buttons(savebutton,[]);
                    end
                    fileslist.Value = fileslist.Value-1;    
                    loadvid(fileslist.Value);
                end
            case progress
%                 b.Value = min([numframes,round(b.Value)]);
                ix = round(b.Value);
                if ix>numframes;ix = numframes;end
                if ix<1; ix = 1;end
                curframe = setframeix(ix);
            case playpause
                if strcmp(b.String,'>')
                    if f == numframes
                        curframe = setframeix(1);
                    end
                    b.String = string(char(449));
                    drpts.Visible = 'on';
                    for i = 1:uptopt
                        edpts{i}.Visible = 'off';
                    end
                    start(vtimer);
                else
                    stop(vtimer);
                    drpts.Visible = 'off';
                    for i = showpts
                        edpts{i}.Visible = 'on';
                    end
                    b.String = '>';
                end
            case stopbutton
                if strcmp(vtimer.Running,'on')
                    stop(vtimer);
                    drpts.Visible = 'off';
                    for i = showpts
                        edpts{i}.Visible = 'on';
                    end
                    playpause.String = '>';
                end
                curframe = setframeix(1);
            case nextframebtn
                if f<numframes && strcmp(vtimer.Running,'off')
                    curframe = setframeix(f+1);
                end
            case prevframebtn
                if f>1 && strcmp(vtimer.Running,'off')
                    curframe = setframeix(f-1);
                end
            case dispframe
                value = inputdlg('Pick Frame:','',[1,30],{num2str(f)});
                if ~isempty(value) && all(isstrprop(strip(value{1}),'digit'))
                    value = str2num(value{1});
                    if value>0 && value<= numframes
                        curframe=setframeix(value);
                    else
                        return
                    end
                else
                    return
                end            
            case savebutton
%                 assignin('base','controlpoints',outstruct);
                fn = savenames{cix};
                fly = struct;
                fly.csv = csv;
                fly.pts.X = Xpts;
                fly.pts.Y = Ypts;
                fly.pts.P = Pval;
                fly.proc.HeadAng = HeadAng;
                fly.proc.BodyAng = BodyAng;
                fly.track.frameidx = markers;
                fly.track.bodymethod = bodymethod;
                fly.track.headmethod = headmethod;
                save(fn,'fly');
                if ~strcmp(dispnames{cix}(1),'*')
                    dispnames{cix} = ['*' dispnames{cix}];
                    fileslist.String= dispnames;
                end
                return
            case deletebutton
                fn = savenames{fileslist.Value};
                if isfile(fn)                    
                    delete(fn)
                end
                if strcmp(dispnames{fileslist.Value}(1),'*')
                    dispnames{fileslist.Value} = dispnames{fileslist.Value}(2:end);
                    fileslist.String= dispnames;
                end
            case quitbutton
                onClose;
                return
            case deletemarkerbtn
                if isempty(markers);return;end
                ix = markerlist.Value;
                revix = markers(ix);
                Xpts(revix,:) = csv(revix,2:3:end);
                Ypts(revix,:) = csv(revix,3:3:end);
                Pval(revix,:) = csv(revix,4:3:end);
                markers(ix) = [];
                updatemarkers;
                getheadang;
                getbodyang;
                headline.YData = HeadAng;
                bodyline.YData = BodyAng;
                if ix>1
                    markerlist.Value = ix-1;
                end
            case gotomarkerbtn
                if isempty(markers);return;end
                curframe = setframeix(markers(markerlist.Value));
            case nextmarkerbtn
                if isempty(markers);return;end
                if markerlist.Value==length(markers)
                    ix = 1;
                else
                    ix = markerlist.Value+1;
                end
                markerlist.Value = ix;
                curframe = setframeix(markers(ix));
            case prevmarkerbtn
                if isempty(markers);return;end
                if markerlist.Value==1
                    ix = length(markers);
                else
                    ix = markerlist.Value-1;
                end
                markerlist.Value = ix;
                curframe = setframeix(markers(ix));
            case datax
                if e.Button==1
                    ix = round(e.IntersectionPoint(1));
                    if ix>numframes;ix = numframes;end
                    if ix<1; ix = 1;end
                    curframe = setframeix(ix);
                end
            otherwise
                disp('!');
        end
        if strcmp(vtimer.Running,'off')
            showframe;
        end
    end

    function loadvid(ix)
        if strcmp(vtimer.Running,'on')
            stop(vtimer);
            playpause.String = '>';
        end        
        cix = ix;
        vread = VideoReader(fnames{ix});
        hyp = sqrt(vread.Width^2 + vread.Height^2);
        numframes = vread.NumFrames;
        progress.Value = 1;
        progress.SliderStep = [1/(numframes-1) 1/(numframes-1)];
        progress.Max = numframes;
        curframe=setframeix(1);
        im = image(vidax,curframe);
        hold(vidax,'on');
        clear('bodyaxline');
        clear('headaxline');
        clear('drpts');
        clear('edpts');
        bodyaxline = plot(vidax,[nan nan],[nan nan],'--','Color',BCOLOR,'LineWidth',1.5);
        headaxline = plot(vidax,[nan nan],[nan nan],'Color',HCOLOR,'LineWidth',2.5);
        if SHOW_WINGS
            wingLline = plot(vidax,[nan nan],[nan nan],'Color','r','LineWidth',2);
            wingRline = plot(vidax,[nan nan],[nan nan],'Color','r','LineWidth',2);
        end
        drpts = plot(vidax,nan,nan,'*','Color','m','Visible','off');
        edpts = {};
        for i = 1:uptopt
            edpts{end+1} = images.roi.Point(vidax);
            edpts{end}.Color = pcols(i,:);
            edpts{end}.Label = ptnames{i};
            edpts{end}.LabelVisible = 'hover';
            edpts{end}.Deletable = false;
            if ismember(i,showpts)
                edpts{end}.Visible = 'on';
            else
                edpts{end}.Visible = 'off';
            end
            addlistener(edpts{end},'MovingROI',@eventcb);
            addlistener(edpts{end},'ROIMoved',@eventcb);
        end
        if isfile(savenames{ix})
            fly = [];
            load(savenames{ix});
            csv = fly.csv;
            Xpts = fly.pts.X;
            Ypts = fly.pts.Y;
            Pval = fly.pts.P;
            markers = fly.track.frameidx;
            bodymethod = fly.track.bodymethod;
            headmethod = fly.track.headmethod;
        else
            loadcsv;
        end
%         pts = plot(vidax,nan(1,13),nan(1,13),'m*');
        hold(vidax,'off');
        xticks(vidax,[]);
        yticks(vidax,[]);
        xlim(datax,[0 numframes]);
        xticks(datax,[1 500:500:numframes]);
        getheadang;
        getbodyang;
        hold(datax,'on');
        bodyline.XData = 1:numframes;
        bodyline.YData = BodyAng;
        headline.XData = 1:numframes;
        headline.YData = HeadAng;
        bodyzmline.XData = 1:numframes;
        bodyzmline.YData = BodyAng;
        headzmline.XData = 1:numframes;
        headzmline.YData = HeadAng;
        zoomax.XTick = 1:numframes;
%         bodyline = plot(datax,1:numframes,BodyAng,'--','Color',BCOLOR,'LineWidth',1.5);
%         headline = plot(datax,1:numframes,HeadAng,'Color',HCOLOR,'LineWidth',2.5);
        hold(datax,'off');
        updatetrackingparams(bodybtns(bodymethod));
        updatemarkers
        showframe;
    end

    function loadcsv()
        csv = readmatrix(csvnames{cix},'Range',4);
        Xpts = csv(:,2:3:end);
        Ypts = csv(:,3:3:end);
        Pval = csv(:,4:3:end);
    end

    function updatemarkers()
        [markers, six] = sort(markers);
        tstr = cell(0);
        if isempty(markers)
            markerlist.Value = 1;
            markerlist.String = ' ';
        else
            for i = 1:length(markers)
                tstr{end+1} = ['F' num2str(markers(i))];
            end
            markerlist.String = tstr;
            markerlist.Value = six(end);
        end    
        
        wasrunning = strcmp(vtimer.Running,'on');
        if wasrunning;stop(vtimer);end
            hold(datax,'on');
            delete(edlines);
            if ~isempty(markers)
                try
                    edlines = plot(datax,[markers markers]',[-180 180],'--','Color',[26,152,80]./255);
                catch
                    disp('!');
                end
                drawnow
            end
            datax.XGrid = 'on';
            hold(datax,'off');
        if wasrunning;start(vtimer);end
    end

    function frame = setframeix(ix)
        f = ix;
%         [~,f]=min(abs(vread.CurrentTime-timeix));
        frame = read(vread,f);
        progress.Value = f;
        dispframe.String = ['Frame ' num2str(f) ' of ' num2str(numframes)];
        fline.Value = f;
        zmfline.Value = f;
    end

    %% Get Video Names Function
    function [videoFiles, displayNames, dlcFiles, procFiles] = getVideoNames(directory)
        trackingFiles = dir([directory filesep '**\*DLC_resnet*.csv']);
        videoFiles = {};
        dlcFiles = {};
        displayNames = {};
        procFiles = {};

        for i = 1 : length(trackingFiles)
            videoPrefix = strsplit(trackingFiles(i).name, 'DLC_resnet');
            videoFile = fullfile(trackingFiles(i).folder, [videoPrefix{1} '.avi']);
            
            % If file exists, add to the arrays
            if isfile(videoFile)
                videoFiles{end + 1} = videoFile;
                dlcFiles{end + 1} = fullfile(trackingFiles(i).folder, trackingFiles(i).name);
                procFiles{end + 1} = [fullfile(trackingFiles(i).folder, trackingFiles(i).name(1 : end - 4)) '_PROC.mat']; % Remove the '.avi' from the file name
                displayNames{end + 1} = trackingFiles(i).name(1 : end - 4);
                
                if isfile(procFiles{end}) 
                    displayNames{end} = ['*' displayNames{end}]; % Indicates that a proc file already exists for the video
                end
            end
        end
    end

    function szch(h,~)
        vidax.Position(2) = h.Position(4)*.3;
        vidax.Position(4) = h.Position(4)-vidax.Position(2)+1;
        vidax.Position(3) = vidax.Position(4)*4/3;
        vidax.Position(1) = 0;
        fileslist.Position(1) = 0;
        fileslist.Position(3) = vidax.Position(3)-200;
        fileslist.Position(4) = vidax.Position(2)-25;
        prevfilebtn.Position(1) = fileslist.Position(3);
        prevfilebtn.Position(2) = fileslist.Position(4)/2;
        prevfilebtn.Position(3) = 100;
        prevfilebtn.Position(4) = fileslist.Position(4)/2;
        nextfilebtn.Position(1) = fileslist.Position(3);
        nextfilebtn.Position(2) = 0;
        nextfilebtn.Position(3) = 100;
        nextfilebtn.Position(4) = fileslist.Position(4)/2;
        quitbutton.Position(1) = fileslist.Position(3)+100;
        quitbutton.Position(2) = 0;
        quitbutton.Position(3) = 100;
        quitbutton.Position(4) = fileslist.Position(4)/3;
        deletebutton.Position = quitbutton.Position;
        deletebutton.Position(2) = deletebutton.Position(2)+deletebutton.Position(4);
        savebutton.Position = deletebutton.Position;
        savebutton.Position(2) = savebutton.Position(2)+savebutton.Position(4);
        autosavecheck.Position = savebutton.Position;
        autosavecheck.Position(1) = autosavecheck.Position(1)+20;
        autosavecheck.Position(2) = autosavecheck.Position(2)+autosavecheck.Position(4);
        autosavecheck.Position(3) = autosavecheck.Position(3)-20;
        autosavecheck.Position(4) = 25;
        
        dispdir.Position(1) = 0;
        dispdir.Position(2) = fileslist.Position(4);
        dispdir.Position(3) = fileslist.Position(3)+100;
        dispdir.Position(4) = 25;
        datax.Position(1) = vidax.Position(3)+35;
        datax.Position(2) = 75;
        datax.Position(3) = h.Position(3)-vidax.Position(3)-35; 
        datax.Position(4) = h.Position(4)-430;
        zoomax.Position(1) = datax.Position(1);
        zoomax.Position(2) = datax.Position(2)+datax.Position(4)+30;
        zoomax.Position(3) = datax.Position(3);
        zoomax.Position(4) = 200;
        playpause.Position(1) = vidax.Position(3)+5;
        playpause.Position(2) = h.Position(4)-55;
        playpause.Position(3) = 50;
        playpause.Position(4) = 50;
        stopbutton.Position = playpause.Position;
        stopbutton.Position(1) = stopbutton.Position(1)+50;
        dispframe.Position(1) = stopbutton.Position(1)+stopbutton.Position(3)+7;
        dispframe.Position(2) = h.Position(4)-30;
%         dispframe.Position(3) = 300;
        dispframe.Position(3) = h.Position(3)-dispframe.Position(1)-7;
        dispframe.Position(4) = 25;
        progress.Position(1) = stopbutton.Position(1)+stopbutton.Position(3)+7;
        progress.Position(2) = h.Position(4)-55;
%         progress.Position(3) = 300;
        progress.Position(3) = h.Position(3)-progress.Position(1)-7;
        progress.Position(4) = 25;
        
        prevframebtn.Position = playpause.Position;
        prevframebtn.Position(2) = prevframebtn.Position(2)-60;
        nextframebtn.Position = prevframebtn.Position;
        nextframebtn.Position(1) = nextframebtn.Position(1)+50;
        
        Body7UDbtn.Position(1) = nextframebtn.Position(1)+nextframebtn.Position(3)+7;
        Body7UDbtn.Position(2)= nextframebtn.Position(2)+25;
        Body7UDbtn.Position(3) = 70;
        Body7UDbtn.Position(4) = 25;
        
        Body6UDbtn.Position(1) = nextframebtn.Position(1)+nextframebtn.Position(3)+7;
        Body6UDbtn.Position(2)= nextframebtn.Position(2);
        Body6UDbtn.Position(3) = 70;
        Body6UDbtn.Position(4) = 25;
        
        Body4LRbtn.Position(1) = Body7UDbtn.Position(1)+Body7UDbtn.Position(3)+1;
        Body4LRbtn.Position(2)= Body7UDbtn.Position(2);
        Body4LRbtn.Position(3) = 70;
        Body4LRbtn.Position(4) = 25;
        
        Body4UDbtn.Position(1) = Body6UDbtn.Position(1)+Body6UDbtn.Position(3)+1;
        Body4UDbtn.Position(2)= Body6UDbtn.Position(2);
        Body4UDbtn.Position(3) = 70;
        Body4UDbtn.Position(4) = 25;
        
        Body2Sbtn.Position(1) = Body4UDbtn.Position(1)+Body4UDbtn.Position(3)+1;
        Body2Sbtn.Position(2)= Body4UDbtn.Position(2);
        Body2Sbtn.Position(3) = 70;
        Body2Sbtn.Position(4) = 25;
        
        Body2Wbtn.Position(1) = Body4LRbtn.Position(1)+Body4LRbtn.Position(3)+1;
        Body2Wbtn.Position(2)= Body4LRbtn.Position(2);
        Body2Wbtn.Position(3) = 70;
        Body2Wbtn.Position(4) = 25;                
        
        Head7UDbtn.Position(1) = Body2Wbtn.Position(1)+Body2Wbtn.Position(3)+7;
        Head7UDbtn.Position(2)= Body2Wbtn.Position(2);
        Head7UDbtn.Position(3) = 70;
        Head7UDbtn.Position(4) = 25;
        
        Head6UDbtn.Position(1) = Body2Sbtn.Position(1)+Body2Sbtn.Position(3)+7;
        Head6UDbtn.Position(2)= Body2Sbtn.Position(2);
        Head6UDbtn.Position(3) = 70;
        Head6UDbtn.Position(4) = 25;
        
        Head4LRbtn.Position(1) = Head7UDbtn.Position(1)+Head7UDbtn.Position(3)+1;
        Head4LRbtn.Position(2)= Head7UDbtn.Position(2);
        Head4LRbtn.Position(3) = 70;
        Head4LRbtn.Position(4) = 25;
        
        Head4UDbtn.Position(1) = Head6UDbtn.Position(1)+Head6UDbtn.Position(3)+1;
        Head4UDbtn.Position(2)= Head6UDbtn.Position(2);
        Head4UDbtn.Position(3) = 70;
        Head4UDbtn.Position(4) = 25; 
        
        Head2Tbtn.Position(1) = Head4LRbtn.Position(1)+Head4LRbtn.Position(3)+1;
        Head2Tbtn.Position(2)= Head4LRbtn.Position(2);
        Head2Tbtn.Position(3) = 70;
        Head2Tbtn.Position(4) = 25;
        
        Head2Rbtn.Position(1) = Head4UDbtn.Position(1)+Head4UDbtn.Position(3)+1;
        Head2Rbtn.Position(2)= Head4UDbtn.Position(2);
        Head2Rbtn.Position(3) = 70;
        Head2Rbtn.Position(4) = 25;     

        
        nextmarkerbtn.Position(1) = h.Position(3)-340;
        nextmarkerbtn.Position(2) = nextframebtn.Position(2);
        nextmarkerbtn.Position(3) = 30;
        nextmarkerbtn.Position(4) = 25;        
        
        prevmarkerbtn.Position = nextmarkerbtn.Position;
        prevmarkerbtn.Position(2) = nextmarkerbtn.Position(2)+25;
        
        markerlist.Position = prevmarkerbtn.Position;
        markerlist.Position(1) = prevmarkerbtn.Position(1)+33;
        markerlist.Position(3) = 299;

        gotomarkerbtn.Position = nextmarkerbtn.Position;
        gotomarkerbtn.Position(1) = nextmarkerbtn.Position(1)+33;
        gotomarkerbtn.Position(3) = 150;
        deletemarkerbtn.Position = gotomarkerbtn.Position;
        deletemarkerbtn.Position(1) = gotomarkerbtn.Position(1)+150;
    end

    % Coder's note: the below function is run whenever a user attempts to
    % close the figure. A confirmation is given, and then the settings are
    % saved for next time.
    function onClose(~, ~)
        % Display confirmation message
        confirm = questdlg('Quit?', '', 'Yes', 'No', 'No');
        
        if ~strcmp(confirm, 'Yes')
            return;
        end

        if autosavecheck.Value == 1
            buttons(savebutton, []); % Click save button before proceeding
        end
        
        % Save settings file
        settings = struct();
        settings.autosave = autosavecheck.Value;
        settings.lastfile = fnames{fileslist.Value};
        settings.dir = directory;
        
        % Save into stepperdlcvalidator.set
        save(settingsFile, 'settings');

        stop(vtimer); % Stops frame succession if it was running
        drawnow; % Update figure
        closereq; % Close figure
    end
end