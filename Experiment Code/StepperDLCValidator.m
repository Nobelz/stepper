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
    BODY_COLOR = [253, 141, 60] ./ 255;
    HEAD_COLOR = [43, 140, 190] ./ 255;
    EDIT_COLOR = [26, 152, 80] ./ 255;
    DEFAULT_CALC_METHOD = [1 1];
    COLOR_MAP = hsv(13); % Color map used for points
    LOOP = 0; % Whether to loop back to the beginning for next frames

    BODY_NAMES = {'LeftAntMed', 'LeftAntDist', 'RightAntMed', ...
        'RightAntDist', 'LeftWingRoot', 'RightWingRoot', ...
        'LeftShoulder', 'RightShoulder', 'Neck', 'Waist', 'Abdomen', ...
        'LeftWingTip', 'RightWingTip'};
    
    %% Load Settings
    settingsLoaded = 0;

    while ~settingsLoaded
        % Locate settings file
        directory = pwd;
        settingsFile = [directory filesep 'stepperdlcvalidator.set'];
        
        % Load settings if found
        if isfile(settingsFile)
            load(settingsFile, '-mat', 'settings'); % Load settings from file
            autosave = settings.autosave;
            directory = settings.dir;
    
            [videoNames, displayNames, csvNames, procNames] = getVideoNames(directory);
    
            lastVideoIndex = find(strcmp(videoNames, settings.lastfile), 1); % Find the last video open
            
            % If last video cannot be found, just go to the first one
            if isempty(lastVideoIndex)
                lastVideoIndex = 1;
            end
        else
            % Have user get the correct directory
            directory = uigetdir('.', 'Select Video Folder');
            [videoNames, displayNames, csvNames, procNames] = getVideoNames(directory);
    
            autosave = 0;
            lastVideoIndex = 1; % Start at first video
        end
    
        % Check if the directory has any video files
        if length(videoNames) < 1
            uiwait(msgbox({'The selected directory does not contain any videos.', ...
                'Please select a different folder.'}, 'No Videos'));
            settingsFile = []; % Reset settings file
        else
            settingsLoaded = 1; % Exit loop condition met
        end
    end

    %% Define Variables
    updatedFrames = []; % Stores the frame numbers of the frames updated using the validator
    videoReader = VideoReader(videoNames{lastVideoIndex}); % Load last loaded file, or first file if last loaded doesn't exist 
    videoTimer = timer('Period', .01, 'TimerFcn', @nextFrame, 'ExecutionMode', 'fixedRate'); % Initiate video player on 100 fps
    bodyCalcMethod = DEFAULT_CALC_METHOD(1);
    headCalcMethod = DEFAULT_CALC_METHOD(2);
    showPoints = []; % Specifies which indices of BODY_NAMES should be shown in the video
    frameIndex = 1; % Specifies the current frame index, set at the start of the video in the beginning (frame 1)
    
    fly = struct(); % Stores the fly struct
    csv = []; % Stores the csv representation of all body points of the fly
    xPoints = []; % Stores the x coords of each of the body points of the fly
    yPoints = []; % Stores the y coords of each of the body points of the fly
    pPoints = []; % Stores the probabilies of each of the body points of the fly, as determined by the neural network
    
    headAngles = []; % Stores the head angles for each frame
    headLinePoints = []; % Stores the points to draw the line for the head
    bodyAngles = []; % Stores the body angles for each frame
    bodyLinePoints = []; % Stores the points to draw the line for the body

    currentVideoIndex = lastVideoIndex; % Stores the index of the current video being displayed

    loadFly(currentVideoIndex);

    % if isfile(procNames{currentVideoIndex}) % Check if video proc file exists
    %     % Pull fly data if it exists
    %     load(procNames{currentVideoIndex}, 'fly'); % Load fly struct
    %     csv = fly.csv;
    %     xPoints = fly.pts.X;
    %     yPoints = fly.pts.Y;
    %     pPoints = fly.pts.P;
    % 
    %     updatedFrames = fly.track.frameidx;
    %     bodyCalcMethod = fly.track.bodymethod;
    %     headCalcMethod = fly.track.headmethod;
    % else
    %     loadCSV();
    % end
getheadang;
getbodyang;
numFrames = videoReader.NumFrames;
curframe = setFrameIndex(1);
vwidth = videoReader.Width;
vheight = videoReader.Height;
hyp = sqrt(vwidth^2 + vheight^2);
vwidth = round(768*(vwidth/vheight));
vheight = 768;
uiheight = vheight;
uiwidth = vwidth+480;

c = figure('Name','Stepper DLC Validator','NumberTitle','off',...
    'MenuBar','none','Position',[100 100 1280 800],...
    'CloseRequestFcn',@onClose,'SizeChangedFcn',@szch);

fileslist = uicontrol(c,'Style','listbox','String',displayNames,...
    'Position',[0 0 480 600],'Callback',@buttons,'Value',lastVideoIndex);

vidax = axes(c,'unit','pixel','Position',[480 0 vwidth vheight],'XTick',[],'YTick',[]);
dataX = axes(c,'unit','pixel','Position',[0 0 100 100]);
zoomax = axes(c,'unit','pixel','Position',[0 0 100 100]);
editLines = plot(dataX,nan,nan);
xlim(dataX,[0 numFrames]);
xticks(dataX,[1 500:500:numFrames]);
dataX.XTickLabelRotation = 45;
ylim(dataX,[-180 180]);
yticks(dataX,-180:45:180);
xlabel(dataX,'Frame #');
hold(dataX,'on');
bodyline = plot(dataX,1:numFrames,bodyAngles,'--','Color',BODY_COLOR,'LineWidth',2.5);
headline = plot(dataX,1:numFrames,headAngles,'Color',HEAD_COLOR,'LineWidth',1);
fline = xline(dataX,1,'LineWidth',1.5);
dataX.XGrid = 'on';
dataX.YGrid = 'on';
hold(dataX,'off');
dataX.ButtonDownFcn = @buttons;

hold(zoomax,'on')
bodyzmline = plot(zoomax,1:numFrames,bodyAngles,'--','Color',BODY_COLOR,'LineWidth',2.5);
headzmline = plot(zoomax,1:numFrames,headAngles,'Color',HEAD_COLOR,'LineWidth',1);
zmfline = xline(zoomax,1,'LineWidth',1);
zoomax.XGrid = 'on';
zoomax.YGrid = 'on';
zoomax.XTick = 1:numFrames;
hold(zoomax,'off');

im = image(vidax,curframe);
hold(vidax,'on');
bodyaxline = plot(vidax,[nan nan],[nan nan],'--','Color',BODY_COLOR,'LineWidth',2);
headaxline = plot(vidax,[nan nan],[nan nan],'Color',HEAD_COLOR,'LineWidth',2);
if SHOW_WINGS
    wingLline = plot(vidax,[nan nan],[nan nan],'Color','r','LineWidth',2);
    wingRline = plot(vidax,[nan nan],[nan nan],'Color','r','LineWidth',2);
end
drpts = plot(vidax,nan,nan,'*','Color','m','Visible','off');
edpts = {};
if SHOW_WINGS;uptopt = 13;else;uptopt = 11;end
for ptix = 1:uptopt
    edpts{end+1} = images.roi.Point(vidax);
    edpts{end}.Color = COLOR_MAP(ptix,:);
    edpts{end}.Label = BODY_NAMES{ptix};
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

playPauseButton = uicontrol(c,'Style','pushbutton','String','>',...
    'Position',[0 143 48 25],'Callback',@buttons,'FontSize',20);

stopButton = uicontrol(c,'Style','pushbutton','String',string(char(11036)),...
    'Position',[0 143 48 25],'Callback',@buttons,'FontSize',20);

frameDisplay = uicontrol(c,'Style', 'edit',... 
    'String',['Frame 1 of ' num2str(numFrames)],'ButtonDownFcn',@buttons,...
    'Position', [52 143 428 25],'Enable','off');

progressBar = uicontrol(c,'Style','slider', 'Min',1,'Max',numFrames,'Value',1,...
    'SliderStep',[1/(numFrames-1) 1/(numFrames-1)],...
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

updatetrackingparams(headbtns(headCalcMethod));
        
deletemarkerbtn = uicontrol(c,'Style','pushbutton','String','Revert Frame to CSV',...
    'Position',[0 0 1 1],'Callback',@buttons);
gotomarkerbtn = uicontrol(c,'Style','pushbutton','String','Goto Fixed Frame',...
    'Position',[0 0 1 1],'Callback',@buttons);
updatedFramesDropdownMenu = uicontrol(c,'Style','popupmenu','String',' ',...
    'Position',[0 55 200 23]);

nextmarkerbtn = uicontrol(c,'Style','pushbutton','String','V',...
    'Position',[0 0 1 1],'Callback',@buttons);
prevmarkerbtn = uicontrol(c,'Style','pushbutton','String',string(char(923)),...
    'Position',[0 0 1 1],'Callback',@buttons);
szch(c);
c.WindowState='maximized';

if isfile(procNames{lastVideoIndex})
    updateFrames;
end
curframe = setFrameIndex(1);
showframe;

    function updatetrackingparams(h,~)
        if SHOW_WINGS
            showPoints = [5,6,12,13];
        else
            showPoints = [];
        end
        mx = find(h==bodybtns);
        if ~isempty(mx)
            bodyCalcMethod = mx;
        end
        for i = 1:6
            if i==bodyCalcMethod
                bodybtns(i).Enable = 'off';
            else
                bodybtns(i).Enable = 'on';
            end
        end
        getbodyang();
        bodyline.YData = bodyAngles;
        bodyzmline.YData =bodyAngles;
        
        mx = find(h==headbtns);
        if ~isempty(mx)
            headCalcMethod = mx;
        end
        for i = 1:4
            if i==headCalcMethod
                headbtns(i).Enable = 'off';
            else
                headbtns(i).Enable = 'on';
            end
        end
        getheadang()
        headline.YData = headAngles;
        headzmline.YData = headAngles;
        if strcmp(videoTimer.Running,'off')
            for i = 1:uptopt
                if ismember(i,showPoints)
                    edpts{i}.Visible = 'on';
                else
                    edpts{i}.Visible = 'off';
                end
            end
            showframe;
        end
    end

    %% Next Frame Function
    function nextFrame(~, ~)
        if (frameIndex + 1) > numFrames
            if LOOP
                curframe = setFrameIndex(1);
            else
                stop(videoTimer);
                playPauseButton.String = '>';
            end
        else
            curframe = setFrameIndex(frameIndex+1);
        end
        showframe();
    end

    function showframe()
        im.CData = curframe;
        xdat = xPoints(frameIndex,:);
        ydat = yPoints(frameIndex,:);
        badix = pPoints(frameIndex,:)<.90;
        
        bpts = bodyLinePoints(frameIndex,:);
        bodyaxline.XData = bpts([1 3]);
        bodyaxline.YData = bpts([2 4]);
        
        hpts = headLinePoints(frameIndex,:);
        headaxline.XData = hpts([1 3]);
        headaxline.YData = hpts([2 4]);
        if strcmp(videoTimer.Running,'on')
            drpts.XData = xdat(showPoints);
            drpts.YData = ydat(showPoints);
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
        
        zoomax.XLim = [frameIndex-10 frameIndex+10];
        drawnow limitrate;
    end

    function getbodyang()
        X = xPoints;
        Y = yPoints;
        switch bodyCalcMethod
            case 1 %7Pt LR
                showPoints = [showPoints 5:11];
                ctr = [mean(X(:,5:8),2) mean(Y(:,5:8),2)];
                upt = [mean(X(:,[7:9]),2) mean(Y(:,[7:9]),2)];
                dnt = [mean(X(:,[5,6,10,11]),2) mean(Y(:,[5,6,10,11]),2)];
                bodyAngles = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 2 %6PT UD
                showPoints = [showPoints 5:10];
                ctr = [mean(X(:,5:8),2) mean(Y(:,5:8),2)];
                upt = [mean(X(:,[7:9]),2) mean(Y(:,[7:9]),2)];
                dnt = [mean(X(:,[5,6,10]),2) mean(Y(:,[5,6,10]),2)];
                bodyAngles = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 3 %4Pt LR
                showPoints = [showPoints 5:8];
                ctr = [mean(X(:,5:8),2) mean(Y(:,5:8),2)];
                Lt = [mean(X(:,[5,7]),2) mean(Y(:,[5,7]),2)];
                Rt = [mean(X(:,[6,8]),2) mean(Y(:,[6,8]),2)];
                bodyAngles = (atan2d(Lt(:,2)-Rt(:,2),Lt(:,1)-Rt(:,1)))+90;
            case 4 %4Pt UD
                showPoints = [showPoints 5:8];
                ctr = [mean(X(:,5:8),2) mean(Y(:,5:8),2)];
                upt = [mean(X(:,[7,8]),2) mean(Y(:,[7,8]),2)];
                dnt = [mean(X(:,[5,6]),2) mean(Y(:,[5,6]),2)];
                bodyAngles = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 5 %Shoulders
                showPoints = [showPoints 7:8];
                ctr = [mean(X(:,[7,8]),2) mean(Y(:,[7,8]),2)];
                bodyAngles = atan2d(Y(:,8)-Y(:,7),X(:,8)-X(:,7))+90;
            case 6 %WingRoots
                showPoints = [showPoints 5:6];
                ctr = [mean(X(:,[5,6]),2) mean(Y(:,[5,6]),2)];
                bodyAngles = atan2d(Y(:,6)-Y(:,5),X(:,6)-X(:,5))+90;
        end
        showPoints = unique(showPoints);
        bodyLinePoints = [ctr(:,1) + 200*cosd(bodyAngles) ctr(:,2) + 200*sind(bodyAngles) ctr(:,1) - 200*cosd(bodyAngles) ctr(:,2) - 200*sind(bodyAngles)];
        bodyAngles = bodyAngles-bodyAngles(1);
        bodyAngles = wrapTo180(bodyAngles);
    end

    function getheadang()
        X = xPoints;
        Y = yPoints;
        switch headCalcMethod
            case 1 %Head 7UD
                showPoints = [showPoints,1:4,7:9];
                ctr = [mean(X(:,[1:4 7:9]),2) mean(Y(:,[1:4 7:9]),2)];
                upt = [mean(X(:,[1:4]),2) mean(Y(:,[1:4]),2)];
                dnt = [mean(X(:,[7:9]),2) mean(Y(:,[7:9]),2)];
                headAngles = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 2 %Head 6UD
                showPoints = [showPoints,1:4,7:8];
                ctr = [mean(X(:,[1:4 7:8]),2) mean(Y(:,[1:4 7:8]),2)];
                upt = [mean(X(:,[1:4]),2) mean(Y(:,[1:4]),2)];
                dnt = [mean(X(:,[7:8]),2) mean(Y(:,[7:8]),2)];
                headAngles = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 3 %Head 4LR
                showPoints = [showPoints 1:4];
                ctr = [mean(X(:,[1:4]),2) mean(Y(:,[1:4]),2)];
                Lt = [mean(X(:,[1,2]),2) mean(Y(:,[1,2]),2)];
                Rt = [mean(X(:,[3,4]),2) mean(Y(:,[3,4]),2)];
                headAngles = (atan2d(Lt(:,2)-Rt(:,2),Lt(:,1)-Rt(:,1)))+90;
            case 4 %Head 4UD
                showPoints = [showPoints 1:4];
                ctr = [mean(X(:,[1:4]),2) mean(Y(:,[1:4]),2)];
                upt = [mean(X(:,[2,4]),2) mean(Y(:,[2,4]),2)];
                dnt = [mean(X(:,[1,3]),2) mean(Y(:,[1,3]),2)];
                headAngles = (atan2d(upt(:,2)-dnt(:,2),upt(:,1)-dnt(:,1)));
            case 5 %Tips only
                showPoints = [showPoints 2,4];
                ctr = [mean(X(:,[2,4]),2) mean(Y(:,[2,4]),2)];
                headAngles = atan2d(Y(:,4)-Y(:,2),X(:,4)-X(:,2))+90;
            case 6 %Roots only
                showPoints = [showPoints 1,3];
                ctr = [mean(X(:,[1,3]),2) mean(Y(:,[1,3]),2)];
                headAngles = atan2d(Y(:,3)-Y(:,1),X(:,3)-X(:,1))+90;
        end
        showPoints = unique(showPoints);
        headLinePoints = [ctr(:,1) + 30*cosd(headAngles) ctr(:,2) + 30*sind(headAngles) ctr(:,1) - 30*cosd(headAngles) ctr(:,2) - 30*sind(headAngles)];
        headAngles = headAngles-headAngles(1);
        headAngles = wrapTo180(headAngles);
    end

    function eventcb(h,e)
        pix = find(strcmp(BODY_NAMES,h.Label));
        xPoints(frameIndex,pix) =  h.Position(1);
        yPoints(frameIndex,pix) =  h.Position(2);
        pPoints(frameIndex,pix) = inf;%will still be higher than any cutoff but also unambiguously an edited point
        getbodyang();
        getheadang();
        if strcmp(e.EventName,'ROIMoved')
            bodyline.YData = bodyAngles;
            bodyzmline.YData = bodyAngles;
            headline.YData = headAngles;
            headzmline.YData = headAngles;
            mx = find(updatedFrames==frameIndex,1);
            if isempty(mx)
                updatedFrames = [updatedFrames; frameIndex];
                updateFrames;
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
                if b.Value~=currentVideoIndex && autosavecheck.Value == 1
                    buttons(savebutton,[]);
                end
                loadvid(b.Value);
            case nextfilebtn
                if fileslist.Value~=length(videoNames)
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
            case progressBar
%                 b.Value = min([numframes,round(b.Value)]);
                ix = round(b.Value);
                if ix>numFrames;ix = numFrames;end
                if ix<1; ix = 1;end
                curframe = setFrameIndex(ix);
            case playPauseButton
                if strcmp(b.String,'>')
                    if frameIndex == numFrames
                        curframe = setFrameIndex(1);
                    end
                    b.String = string(char(449));
                    drpts.Visible = 'on';
                    for i = 1:uptopt
                        edpts{i}.Visible = 'off';
                    end
                    start(videoTimer);
                else
                    stop(videoTimer);
                    drpts.Visible = 'off';
                    for i = showPoints
                        edpts{i}.Visible = 'on';
                    end
                    b.String = '>';
                end
            case stopButton
                if strcmp(videoTimer.Running,'on')
                    stop(videoTimer);
                    drpts.Visible = 'off';
                    for i = showPoints
                        edpts{i}.Visible = 'on';
                    end
                    playPauseButton.String = '>';
                end
                curframe = setFrameIndex(1);
            case nextframebtn
                if frameIndex<numFrames && strcmp(videoTimer.Running,'off')
                    curframe = setFrameIndex(frameIndex+1);
                end
            case prevframebtn
                if frameIndex>1 && strcmp(videoTimer.Running,'off')
                    curframe = setFrameIndex(frameIndex-1);
                end
            case frameDisplay
                value = inputdlg('Pick Frame:','',[1,30],{num2str(frameIndex)});
                if ~isempty(value) && all(isstrprop(strip(value{1}),'digit'))
                    value = str2num(value{1});
                    if value>0 && value<= numFrames
                        curframe=setFrameIndex(value);
                    else
                        return
                    end
                else
                    return
                end            
            case savebutton
%                 assignin('base','controlpoints',outstruct);
                fn = procNames{currentVideoIndex};
                fly = struct;
                fly.csv = csv;
                fly.pts.X = xPoints;
                fly.pts.Y = yPoints;
                fly.pts.P = pPoints;
                fly.proc.HeadAng = headAngles;
                fly.proc.BodyAng = bodyAngles;
                fly.track.frameidx = updatedFrames;
                fly.track.bodymethod = bodyCalcMethod;
                fly.track.headmethod = headCalcMethod;
                save(fn,'fly');
                if ~strcmp(displayNames{currentVideoIndex}(1),'*')
                    displayNames{currentVideoIndex} = ['*' displayNames{currentVideoIndex}];
                    fileslist.String= displayNames;
                end
                return
            case deletebutton
                fn = procNames{fileslist.Value};
                if isfile(fn)                    
                    delete(fn)
                end
                if strcmp(displayNames{fileslist.Value}(1),'*')
                    displayNames{fileslist.Value} = displayNames{fileslist.Value}(2:end);
                    fileslist.String= displayNames;
                end
            case quitbutton
                onClose;
                return
            case deletemarkerbtn
                if isempty(updatedFrames);return;end
                ix = updatedFramesDropdownMenu.Value;
                revix = updatedFrames(ix);
                xPoints(revix,:) = csv(revix,2:3:end);
                yPoints(revix,:) = csv(revix,3:3:end);
                pPoints(revix,:) = csv(revix,4:3:end);
                updatedFrames(ix) = [];
                updateFrames;
                getheadang;
                getbodyang;
                headline.YData = headAngles;
                bodyline.YData = bodyAngles;
                if ix>1
                    updatedFramesDropdownMenu.Value = ix-1;
                end
            case gotomarkerbtn
                if isempty(updatedFrames);return;end
                curframe = setFrameIndex(updatedFrames(updatedFramesDropdownMenu.Value));
            case nextmarkerbtn
                if isempty(updatedFrames);return;end
                if updatedFramesDropdownMenu.Value==length(updatedFrames)
                    ix = 1;
                else
                    ix = updatedFramesDropdownMenu.Value+1;
                end
                updatedFramesDropdownMenu.Value = ix;
                curframe = setFrameIndex(updatedFrames(ix));
            case prevmarkerbtn
                if isempty(updatedFrames);return;end
                if updatedFramesDropdownMenu.Value==1
                    ix = length(updatedFrames);
                else
                    ix = updatedFramesDropdownMenu.Value-1;
                end
                updatedFramesDropdownMenu.Value = ix;
                curframe = setFrameIndex(updatedFrames(ix));
            case dataX
                if e.Button==1
                    ix = round(e.IntersectionPoint(1));
                    if ix>numFrames;ix = numFrames;end
                    if ix<1; ix = 1;end
                    curframe = setFrameIndex(ix);
                end
            otherwise
                disp('!');
        end
        if strcmp(videoTimer.Running,'off')
            showframe;
        end
    end

    function loadvid(ix)
        if strcmp(videoTimer.Running,'on')
            stop(videoTimer);
            playPauseButton.String = '>';
        end        
        currentVideoIndex = ix;
        videoReader = VideoReader(videoNames{ix});
        hyp = sqrt(videoReader.Width^2 + videoReader.Height^2);
        numFrames = videoReader.NumFrames;
        progressBar.Value = 1;
        progressBar.SliderStep = [1/(numFrames-1) 1/(numFrames-1)];
        progressBar.Max = numFrames;
        curframe=setFrameIndex(1);
        im = image(vidax,curframe);
        hold(vidax,'on');
        clear('bodyaxline');
        clear('headaxline');
        clear('drpts');
        clear('edpts');
        bodyaxline = plot(vidax,[nan nan],[nan nan],'--','Color',BODY_COLOR,'LineWidth',1.5);
        headaxline = plot(vidax,[nan nan],[nan nan],'Color',HEAD_COLOR,'LineWidth',2.5);
        if SHOW_WINGS
            wingLline = plot(vidax,[nan nan],[nan nan],'Color','r','LineWidth',2);
            wingRline = plot(vidax,[nan nan],[nan nan],'Color','r','LineWidth',2);
        end
        drpts = plot(vidax,nan,nan,'*','Color','m','Visible','off');
        edpts = {};
        for i = 1:uptopt
            edpts{end+1} = images.roi.Point(vidax);
            edpts{end}.Color = COLOR_MAP(i,:);
            edpts{end}.Label = BODY_NAMES{i};
            edpts{end}.LabelVisible = 'hover';
            edpts{end}.Deletable = false;
            if ismember(i,showPoints)
                edpts{end}.Visible = 'on';
            else
                edpts{end}.Visible = 'off';
            end
            addlistener(edpts{end},'MovingROI',@eventcb);
            addlistener(edpts{end},'ROIMoved',@eventcb);
        end

        loadFly(ix);
        
%         pts = plot(vidax,nan(1,13),nan(1,13),'m*');
        hold(vidax,'off');
        xticks(vidax,[]);
        yticks(vidax,[]);
        xlim(dataX,[0 numFrames]);
        xticks(dataX,[1 500:500:numFrames]);
        getheadang;
        getbodyang;
        hold(dataX,'on');
        bodyline.XData = 1:numFrames;
        bodyline.YData = bodyAngles;
        headline.XData = 1:numFrames;
        headline.YData = headAngles;
        bodyzmline.XData = 1:numFrames;
        bodyzmline.YData = bodyAngles;
        headzmline.XData = 1:numFrames;
        headzmline.YData = headAngles;
        zoomax.XTick = 1:numFrames;
%         bodyline = plot(datax,1:numframes,BodyAng,'--','Color',BCOLOR,'LineWidth',1.5);
%         headline = plot(datax,1:numframes,HeadAng,'Color',HCOLOR,'LineWidth',2.5);
        hold(dataX,'off');
        updatetrackingparams(bodybtns(bodyCalcMethod));
        updateFrames
        showframe;
    end
    
    %% Update Frames Function
    % This function updates the revised frames in the dropdown menu and on
    % the angle graph.
    function updateFrames()
        [updatedFrames, sortingIndices] = sort(updatedFrames); % Sort frames in increasing order

        % If there are no updated frames anymore, clear the dropdown menu
        if isempty(updatedFrames)
            updatedFramesDropdownMenu.Value = 1;
            updatedFramesDropdownMenu.String = ' ';
        else
            frameStrings = cell(length(updatedFrames)); % Store the names of the frames that were updated
            
            % Add each updated frame's name with 'F' prepended to the
            % dropdown menu
            for i = 1 : length(updatedFrames)
                frameStrings{i} = ['F' num2str(updatedFrames(i))];
            end
            updatedFramesDropdownMenu.String = frameStrings; % Set the frames in the dropdown menu
            updatedFramesDropdownMenu.Value = sortingIndices(end); % Set the selection to be the last updated frame
        end    
        
        timerRunning = strcmp(videoTimer.Running, 'on'); % Check if the video timer was running before
        if timerRunning
            stop(videoTimer); % Stop video timer if it was running
        end

        % Plot edited lines
        hold(dataX, 'on');

        % Delete existing edited lines
        delete(editLines);

        if ~isempty(updatedFrames)
            try
                editLines = plot(dataX, [updatedFrames updatedFrames]', [-180 180], '--', 'Color', EDIT_COLOR);
            catch
                disp('!');
            end

            % Coder's note: I do not know why there is a try/catch
            % here, but I'm not removing it. - nxz157, 7/19/2023

            drawnow; % Update figure
        end

        dataX.XGrid = 'on';
        hold(dataX, 'off');

        % Restart timer if it was running before
        if timerRunning
            start(videoTimer);
        end
    end
    
    %% Load Fly Function
    % This function loads the fly struct from the PROC file if created;
    % otherwise, it calls loadCSV() to get the X and Y points from the DLC
    % CSV.
    function loadFly(index)
        if isfile(procNames{index}) % Check if fly struct already exists in proc file
            load(procNames{index}, 'fly'); % Load fly struct
            csv = fly.csv;
            xPoints = fly.pts.X;
            yPoints = fly.pts.Y;
            pPoints = fly.pts.P;
            updatedFrames = fly.track.frameidx;
            bodyCalcMethod = fly.track.bodymethod;
            headCalcMethod = fly.track.headmethod;
        else
            loadCSV();
        end
    end

    %% Load CSV File Function
    % This function loads the DLC CSV file and pulls the X and Y points, as
    % well as the confidence.
    function loadCSV()
        csv = readmatrix(csvNames{currentVideoIndex}, 'Range', 4);
        xPoints = csv(:, 2 : 3 : end);
        yPoints = csv(:, 3 : 3 : end);
        pPoints = csv(:, 4 : 3 : end);
    end

    %% Set Frame Index Function
    % This function sets the frame index to the specified index, changing
    % the progress bar, the display, and the video reader to reflect that
    % change.
    function frame = setFrameIndex(index)
        frameIndex = index; % Set frame index to the new index
        frame = read(videoReader, index); % Read in new index
        progressBar.Value = index;
        frameDisplay.String = ['Frame ' num2str(index) ' of ' num2str(numFrames)];
        fline.Value = index;
        zmfline.Value = index;
    end

    %% Get Video Names Function
    % The main file lookup function, this function gets the video names,
    % display names, dlc .csv files, and proc files from the supposed
    % directory.
    function [videoFiles, displayNames, dlcFiles, procFiles] = getVideoNames(directory)
        trackingFiles = dir([directory filesep '**\*DLC_resnet*.csv']);
        videoFiles = {};
        dlcFiles = {};
        displayNames = {};
        procFiles = {};
    
        % Loop through each tracking file
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
        dataX.Position(1) = vidax.Position(3)+35;
        dataX.Position(2) = 75;
        dataX.Position(3) = h.Position(3)-vidax.Position(3)-35; 
        dataX.Position(4) = h.Position(4)-430;
        zoomax.Position(1) = dataX.Position(1);
        zoomax.Position(2) = dataX.Position(2)+dataX.Position(4)+30;
        zoomax.Position(3) = dataX.Position(3);
        zoomax.Position(4) = 200;
        playPauseButton.Position(1) = vidax.Position(3)+5;
        playPauseButton.Position(2) = h.Position(4)-55;
        playPauseButton.Position(3) = 50;
        playPauseButton.Position(4) = 50;
        stopButton.Position = playPauseButton.Position;
        stopButton.Position(1) = stopButton.Position(1)+50;
        frameDisplay.Position(1) = stopButton.Position(1)+stopButton.Position(3)+7;
        frameDisplay.Position(2) = h.Position(4)-30;
%         dispframe.Position(3) = 300;
        frameDisplay.Position(3) = h.Position(3)-frameDisplay.Position(1)-7;
        frameDisplay.Position(4) = 25;
        progressBar.Position(1) = stopButton.Position(1)+stopButton.Position(3)+7;
        progressBar.Position(2) = h.Position(4)-55;
%         progress.Position(3) = 300;
        progressBar.Position(3) = h.Position(3)-progressBar.Position(1)-7;
        progressBar.Position(4) = 25;
        
        prevframebtn.Position = playPauseButton.Position;
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
        
        updatedFramesDropdownMenu.Position = prevmarkerbtn.Position;
        updatedFramesDropdownMenu.Position(1) = prevmarkerbtn.Position(1)+33;
        updatedFramesDropdownMenu.Position(3) = 299;

        gotomarkerbtn.Position = nextmarkerbtn.Position;
        gotomarkerbtn.Position(1) = nextmarkerbtn.Position(1)+33;
        gotomarkerbtn.Position(3) = 150;
        deletemarkerbtn.Position = gotomarkerbtn.Position;
        deletemarkerbtn.Position(1) = gotomarkerbtn.Position(1)+150;
    end
    
    %% Closing Function
    % The below function is run whenever a user attempts to close the 
    % figure. A confirmation is given, and then the settings are
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
        settings.lastfile = videoNames{fileslist.Value};
        settings.dir = directory;
        
        % Save into stepperdlcvalidator.set
        save(settingsFile, 'settings');

        stop(videoTimer); % Stops frame succession if it was running
        drawnow; % Update figure
        closereq; % Close figure
    end
end