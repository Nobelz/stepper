function StepperDLCValidator()
% StepperDLCValidator.m
% Validates DLC pose estimations with custom GUI.
%
% Author: Mike Rauscher and Nobel Zhou
% Date: 20 July 2023
% Version: 0.2
%
% VERSION CHANGELOG:
% - v0.1 (???): Initial commit
% - v0.2 (7/20/2023): Make code more readable

    %% Define Constants
    SHOW_WINGS = 1; % Whether to show wings or not
    DLC_FOLDER = 'D:/DLCNetworks/StepperTether-FoxLab-2023-09-12';
    FINAL_DATA_FOLDER = '../../Stepper Data/Analyzed Data';
    REJECTED_DATA_FOLDER = '../../Stepper Data/Rejected Data';
    BODY_COLOR = [253, 141, 60] ./ 255;
    HEAD_COLOR = [43, 140, 190] ./ 255;
    EDIT_COLOR = [26, 152, 80] ./ 255;
    BAD_COLOR = [105, 105, 105] ./ 255;
    DEFAULT_CALC_METHOD = [1 1];
    COLOR_MAP = hsv(13); % Color map used for points
    LOOP = 0; % Whether to loop back to the beginning for next frames

    BODY_NAMES = {'LeftAntMed', 'LeftAntDist', 'RightAntMed', ...
        'RightAntDist', 'LeftWingRoot', 'RightWingRoot', ...
        'LeftShoulder', 'RightShoulder', 'Neck', 'Waist', 'Abdomen', ...
        'LeftWingTip', 'RightWingTip'};
    
    %% Load Settings
    settingsLoaded = 0;

    markedFiles = {}; % Stores which files should be moved to deeplabcut for frame extraction analysis
    savedFiles = {}; % Stores which files should be saved and moved to the save folder

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
            
            if ~isempty(videoNames)
                lastVideoIndex = find(strcmp(videoNames, settings.lastfile), 1); % Find the last video open
                
                % If last video cannot be found, just go to the first one
                if isempty(lastVideoIndex)
                    lastVideoIndex = 1;
                end
                settingsLoaded = 1;
            else
                % Have user get the correct directory
                directory = uigetdir('.', 'Select Video Folder');
                if directory
                    [videoNames, displayNames, csvNames, procNames] = getVideoNames(directory);
                    autosave = 0;
                    lastVideoIndex = 1; % Start at first video
                else
                    videoNames = {};
                end
            end
         else
             % Have user get the correct directory
             directory = uigetdir('.', 'Select Video Folder');
             if directory
                 [videoNames, displayNames, csvNames, procNames] = getVideoNames(directory);
                 autosave = 0;
                 lastVideoIndex = 1; % Start at first video
             else
                 videoNames = {};
             end
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
    loadFly(currentVideoIndex); % Load fly information

    % Display points
    getHeadAngles();
    getBodyAngles();
    
    numFrames = videoReader.NumFrames;
    curFrame = setFrameIndex(1); % Get current frame

    % Get video reader dimensions and scale it up
    videoWidth = round(768 * (videoReader.Width / videoReader.Height));
    videoHeight = 768;
    
    % Setup Python
    pe = pyenv;
    if strcmp(pe.Version, '')
        error('Python not installed or not setup correctly.');
    end
    pyrun('import deeplabcut'); % Import deeplabcut

    %% Create GUI
    % Make GUI Figure
    c = figure('Name', 'Stepper DLC Validator', ...
        'NumberTitle', 'off', 'MenuBar', 'none', ...
        'Position', [100 100 1280 800], 'CloseRequestFcn', @onClose, ...
        'SizeChangedFcn', @onSizeChanged);
    
    % Make file list in bottom left
    filesList = uicontrol(c, 'Style', 'listbox', 'String', displayNames, ...
        'Position', [0 0 480 600], 'Callback', @onClick, 'Value', lastVideoIndex);

    % Specify axes
    videoAxis = axes(c, 'unit', 'pixel', 'Position', [480 0 videoWidth videoHeight], ...
        'XTick', [], 'YTick', []); % Axes for video reader
    dataAxis = axes(c, 'unit', 'pixel', 'Position', [0 0 100 100]); % Axes for whole data graph
    zoomAxis = axes(c, 'unit', 'pixel', 'Position', [0 0 100 100]); % Axes for zoomed in data graph (on top)
    editLines = plot(dataAxis, nan, nan); % Plot no edit lines at first
    
    % Edit data axis
    xlim(dataAxis, [0 numFrames]); % Set frames to go through all frames
    xticks(dataAxis, [1 500 : 500 : numFrames]); % X tick for every 500 frames
    dataAxis.XTickLabelRotation = 45;
    ylim(dataAxis, [-180 180]);
    yticks(dataAxis, -180 : 30: 180);
    xlabel(dataAxis, 'Frame #');

    % Plot data axis
    hold(dataAxis, 'on');
    bodyDataLine = plot(dataAxis, 1 : numFrames, bodyAngles, '--', ...
        'Color', BODY_COLOR, 'LineWidth', 2.5);
    headDataLine = plot(dataAxis, 1 : numFrames, headAngles, ...
        'Color', HEAD_COLOR, 'LineWidth', 1);
    curFrameLine = xline(dataAxis, 1, 'LineWidth', 1.5); % Specifies line of current frame, currently set to 1
    dataAxis.XGrid = 'on';
    dataAxis.YGrid = 'on';
    hold(dataAxis,'off');
    
    dataAxis.ButtonDownFcn = @onClick; % Attach handler when they click on data axis
    
    % Plot zoomed axis
    hold(zoomAxis, 'on')
    zoomBody = plot(zoomAxis, 1 : numFrames, bodyAngles, '--', ...
        'Color', BODY_COLOR, 'LineWidth', 2.5);
    zoomHead = plot(zoomAxis, 1 : numFrames, headAngles, ...
        'Color', HEAD_COLOR, 'LineWidth', 1);
    curFrameZoomLine = xline(zoomAxis, 1, 'LineWidth', 1);
    zoomAxis.XGrid = 'on';
    zoomAxis.YGrid = 'on';
    zoomAxis.XTick = 1 : numFrames;
    hold(zoomAxis, 'off');

    % Plot video axis
    im = image(videoAxis, curFrame); % Add frame to video
    
    hold(videoAxis, 'on');
    bodyVideoLine = plot(videoAxis, [nan nan], [nan nan], '--', ...
        'Color', BODY_COLOR, 'LineWidth', 2);
    headVideoLine = plot(videoAxis, [nan nan], [nan nan], ...
        'Color', HEAD_COLOR, 'LineWidth', 2);
    
    % Show wings if necessary
    if SHOW_WINGS
        wingLline = plot(videoAxis, [nan nan], [nan nan], 'Color', 'r', 'LineWidth', 2);
        wingRline = plot(videoAxis, [nan nan], [nan nan], 'Color', 'r', 'LineWidth', 2);
        numEditPoints = 13;
    else
        numEditPoints = 11;
    end

    % Plot "quick" points if the video is playing
    readOnlyPoints = plot(videoAxis, nan, nan, '*', 'Color', 'm', 'Visible', 'off');
    
    % Plot points that can be edited and moved around, for use if the video
    % is not playing
    editPoints = cell(1, numEditPoints);
    
    % Make menu for ROI points
    wingPointMenu = uicontextmenu;
    badTrackingMenuItem = uimenu(wingPointMenu, 'Text', 'Bad Tracking', 'Checked', 'off');
    badTrackingMenuItem.MenuSelectedFcn = @onClick;
    
    % Loop through each point that can be displayed
    for j = 1 : numEditPoints
        newPoint = images.roi.Point(videoAxis);
        newPoint.Label = BODY_NAMES{j};
        newPoint.Color = COLOR_MAP(j, :);
        newPoint.LabelVisible = 'hover';
        newPoint.Deletable = 0;
        addlistener(newPoint, 'MovingROI', @onPointMoved);
        addlistener(newPoint, 'ROIMoved', @onPointMoved);
        addlistener(newPoint, 'ROIClicked', @onClick);
        
        editPoints{j} = newPoint;

        if j > 11
            set(newPoint, 'uicontextmenu', wingPointMenu);
        end
    end

    xticks(videoAxis, []);
    yticks(videoAxis, []);
    hold(videoAxis, 'off');

    % Coder's note: the layout is not set here, but instead in the
    % onSizeChanged() function. - nxz157, 7/20/2023

    % Add folder display
    folderDisplay = uicontrol(c, 'Style', 'edit', 'ToolTip', directory, ...
        'String', directory, 'ButtonDownFcn', @onClick, ...
        'Position', [0 0 480 40], 'Enable', 'off');
    
    % Add video buttons
    playPauseButton = uicontrol(c, 'Style', 'pushbutton', 'String', '>', ...
        'Position', [0 143 48 25], 'Callback', @onClick, 'FontSize', 20);
    stopButton = uicontrol(c, 'Style', 'pushbutton', 'String', string(char(11036)), ...
        'Position',[0 143 48 25], 'Callback', @onClick, 'FontSize', 20);
    
    % Add frame display
    frameDisplay = uicontrol(c, 'Style', 'edit', 'String', ['Frame 1 of ' num2str(numFrames)], ...
        'ButtonDownFcn', @onClick, 'Position', [52 143 428 25], 'Enable', 'off');
    
    % Add progress bar
    progressBar = uicontrol(c, 'Style', 'slider', 'Min', 1, 'Max', ...
        numFrames, 'Value', 1, 'SliderStep', [1 / (numFrames - 1) 1 / (numFrames - 1)], ...
        'Position', [0 118 480 25], 'Callback', @onClick);
    
    % Add file buttons
    nextFileButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'V', ...
        'Position', [0 0 1 1], 'Callback', @onClick, 'FontSize', 28);
    prevFileButton = uicontrol(c, 'Style', 'pushbutton', 'String', string(char(923)), ...
        'Position', [0 0 1 1], 'Callback', @onClick, 'FontSize', 28);
    
    % Add autosave checkbox
    autosaveCheckBox = uicontrol(c, 'Style', 'checkbox', 'String', 'Autosave', ...
        'Position', [0 0 1 1], 'Value', autosave);

    % Add DLC button
    sendToDLCButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'Send to DLC', ...
        'Position', [0 0 1 1], 'Callback', @onClick);

    % Add mark button
    markButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'Mark', ...
        'Position', [0 0 1 1], 'Callback', @onClick);

    % Add unmark button
    unmarkButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'Unmark', ...
        'Position', [0 0 1 1], 'Callback', @onClick);

    % Add save button
    saveButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'Save', ...
        'Position', [0 0 1 1], 'Callback', @onClick);

    % Add delete button
    deleteButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'Delete', ...
        'Position', [0 0 1 1], 'Callback', @onClick);

    % Add move button
    moveButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'Move Files...', ...
        'Position', [0 0 1 1], 'Callback', @onClick);
    
    % Add frame buttons
    nextFrameButton = uicontrol(c, 'Style', 'pushbutton', 'String', '>', ...
        'Position', [0 0 1 1], 'Callback', @onClick);
    prevFrameButton = uicontrol(c, 'Style', 'pushbutton', 'String', '<', ...
        'Position', [0 0 1 1], 'Callback', @onClick);

    % Add body buttons
    body7PtButton = uicontrol(c, 'Style', 'pushbutton', 'String', '7pt Body', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    body6UDButton = uicontrol(c,'Style', 'pushbutton', 'String', '6pt Body', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    body4LRButton = uicontrol(c,'Style', 'pushbutton', 'String', '4Pt LR Body', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    body4UDButton = uicontrol(c, 'Style', 'pushbutton', 'String', '4Pt UD Body', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    body2SButton = uicontrol(c,'Style', 'pushbutton', 'String', 'Shoulders', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    body2WButton = uicontrol(c,'Style', 'pushbutton', 'String', 'Wing Roots', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    bodyButtons = [body7PtButton, body6UDButton, body4LRButton, ...
        body4UDButton, body2SButton, body2WButton];
    
    % Add head buttons
    head7PtButton = uicontrol(c, 'Style', 'pushbutton', 'String', '7Pt Head', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    head6UDButton = uicontrol(c, 'Style', 'pushbutton', 'String', '6Pt Head', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    head4LRButton = uicontrol(c, 'Style', 'pushbutton', 'String', '4Pt LR Head', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    head4UDButton = uicontrol(c, 'Style' ,'pushbutton', 'String', '4Pt UD Head', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    head2TButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'Tips', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    head2RButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'Roots', ...
        'Position', [0 0 1 1], 'Callback', @updateTrackingParameters);
    headButtons = [head7PtButton, head6UDButton, head4LRButton, ...
        head4UDButton, head2TButton, head2RButton];

    % Update tracking parameters
    updateTrackingParameters(headButtons(headCalcMethod));
    
    % Add marker buttons
    deleteMarkerButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'Revert Frame to CSV', ...
        'Position', [0 0 1 1], 'Callback', @onClick);
    gotoMarkerButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'Goto Fixed Frame', ...
        'Position', [0 0 1 1], 'Callback', @onClick);
    nextMarkerButton = uicontrol(c, 'Style', 'pushbutton', 'String', 'V', ...
        'Position', [0 0 1 1], 'Callback', @onClick);
    prevMarkerButton = uicontrol(c, 'Style', 'pushbutton', 'String', string(char(923)), ...
        'Position', [0 0 1 1], 'Callback', @onClick);

    % Add updated frames dropdown menu
    markerDropdownMenu = uicontrol(c, 'Style', 'popupmenu', 'String', ' ', ...
        'Position', [0 55 200 23]);

    % Update GUI to size
    onSizeChanged(c);
    c.WindowState = 'maximized'; % Maximize window

    if isfile(procNames{lastVideoIndex})
        updateFrames();
    else
        sendToDLCButton.Enable = 'off';
    end
    curFrame = setFrameIndex(1);
    showFrame();
    
    %% Update Tracking Parameters Function
    % This function is called whenever we are changing the tracking
    % calculation method. 
    function updateTrackingParameters(h, ~)
        % Add wing points if wings should be shown
        if SHOW_WINGS
            showPoints = [5, 6, 12, 13];
        else
            showPoints = [];
        end
        
        % Update body data
        selectedButton = find(h == bodyButtons); % Find which button is selected
        if ~isempty(selectedButton)
            bodyCalcMethod = selectedButton; % Must mean that it's a head button or it's on startup
        end

        for i = 1 : 6
            if i == bodyCalcMethod
                bodyButtons(i).Enable = 'off'; % Disable the button that you just clicked
            else
                bodyButtons(i).Enable = 'on';
            end
        end
        
        getBodyAngles();
        bodyDataLine.YData = bodyAngles;
        zoomBody.YData = bodyAngles;
        
        % Update head data
        selectedButton = find(h == headButtons);
        if ~isempty(selectedButton)
            headCalcMethod = selectedButton;
        end

        for i = 1 : 4
            if i == headCalcMethod
                headButtons(i).Enable = 'off';
            else
                headButtons(i).Enable = 'on';
            end
        end

        getHeadAngles();
        headDataLine.YData = headAngles;
        zoomHead.YData = headAngles;

        % Update which points are shown if the video is not playing
        if strcmp(videoTimer.Running, 'off')
            for i = 1 : numEditPoints
                if ismember(i, showPoints)
                    editPoints{i}.Visible = 'on';
                else
                    editPoints{i}.Visible = 'off';
                end
            end
            showFrame(); % Update frame
        end
    end

    %% Next Frame Function
    % This function is called whenever we want to advance the frame.
    function nextFrame(~, ~)
        if (frameIndex + 1) > numFrames
            if LOOP
                curFrame = setFrameIndex(1);
            else
                stop(videoTimer);
                readOnlyPoints.Visible = 'off';
                for i = showPoints
                    editPoints{i}.Visible = 'on';
                end
                playPauseButton.String = '>';
            end
        else
            curFrame = setFrameIndex(frameIndex + 1);
        end
        showFrame();
    end
    
    %% Show Frame Function
    % This function updates the frame according to different tracking
    % calcultions, and displays the points
    function showFrame()
        % Pull data from frame index
        im.CData = curFrame; % Update image data
        xData = xPoints(frameIndex, :);
        yData = yPoints(frameIndex, :);
        % badPoints = pPoints(frameIndex, :) < .90;
        
        % Get body and head points
        bodyPoints = bodyLinePoints(frameIndex, :);
        bodyVideoLine.XData = bodyPoints([1 3]);
        bodyVideoLine.YData = bodyPoints([2 4]);
        
        headPoints = headLinePoints(frameIndex,:);
        headVideoLine.XData = headPoints([1 3]);
        headVideoLine.YData = headPoints([2 4]);
    
        % Update read only points if running, otherwise update editable
        % points
        if strcmp(videoTimer.Running,'on')
            readOnlyPoints.XData = xData(showPoints);
            readOnlyPoints.YData = yData(showPoints);
        else
            for i = 1 : numEditPoints
                editPoints{i}.Position = [xData(i) yData(i)];

                if pPoints(frameIndex, i) == -inf
                    editPoints{i}.Color = BAD_COLOR;
                else
                    editPoints{i}.Color = COLOR_MAP(i, :);
                end
            end
        end

        % % Get rid of bad points
        % xData(badPoints) = nan;
        % yData(badPoints) = nan;

        % Update wing lines if they should be displayed
        if SHOW_WINGS
            wingLline.XData = xData([5 12]);
            wingLline.YData = yData([5 12]);
            wingRline.XData = xData([6 13]);
            wingRline.YData = yData([6 13]);
        end
        
        % Update zoom axis x range
        zoomAxis.XLim = [frameIndex - 10 frameIndex + 10];

        drawnow limitrate; % Update GUI display

        % Check if "outlier"
        if frameIndex > 1 && frameIndex < numFrames && ...
            ((abs(headAngles(frameIndex - 1) - headAngles(frameIndex)) > 12 ...
                && abs(headAngles(frameIndex + 1) - headAngles(frameIndex)) > 12) ...
                || (abs(bodyAngles(frameIndex - 1) - bodyAngles(frameIndex)) > 12 ...
                && abs(bodyAngles(frameIndex + 1) - bodyAngles(frameIndex)) > 12)) ...
                && strcmp(videoTimer.Running, 'on')
            % If outlier and video timer running, stop at outlier to ensure
            % that it's correct
            stop(videoTimer);
            readOnlyPoints.Visible = 'off';
            for i = showPoints
                editPoints{i}.Visible = 'on';
            end
            playPauseButton.String = '>';

            showFrame();
        end
    end
    
    %% Get Body Angles Function
    % Using the X and Y points, as well as the calculation method, this
    % function calculates the body angle.
    function getBodyAngles()
        x = xPoints;
        y = yPoints;
        switch bodyCalcMethod
            case 1 % 7-point Body
                showPoints = [showPoints 5 : 11];
                center = [mean(x(:, 5 : 8), 2) mean(y(:, 5 : 8), 2)];
                up = [mean(x(:, 7 : 9), 2) mean(y(:, 7 : 9), 2)];
                down = [mean(x(:, [5, 6, 10, 11]), 2) mean(y(:,[5, 6, 10, 11]), 2)];
                bodyAngles = atan2d(up(:, 2) - down(:, 2), up(:, 1) - down(:, 1));
            case 2 % 6-point UD
                showPoints = [showPoints 5 : 10];
                center = [mean(x(:, 5 : 8), 2) mean(y(:, 5 : 8), 2)];
                up = [mean(x(:, 7 : 9), 2) mean(y(:, 7 : 9), 2)];
                down = [mean(x(:, [5, 6, 10]), 2) mean(y(:, [5, 6, 10]), 2)];
                bodyAngles = atan2d(up(:, 2) - down(:, 2), up(:, 1) - down(:, 1));
            case 3 % 4-point LR
                showPoints = [showPoints 5 : 8];
                center = [mean(x(:, 5 : 8), 2) mean(y(:, 5 : 8), 2)];
                left = [mean(x(:, [5, 7]), 2) mean(y(:, [5, 7]), 2)];
                right = [mean(x(:, [6, 8]), 2) mean(y(:, [6 ,8]), 2)];
                bodyAngles = atan2d(left(:, 2) - right(:, 2), left(:, 1) - right(:, 1)) + 90;
            case 4 % 4-point UD
                showPoints = [showPoints 5 : 8];
                center = [mean(x(:, 5 : 8), 2) mean(y(:, 5 : 8), 2)];
                up = [mean(x(:, [7 8]), 2) mean(y(:, [7 8]), 2)];
                down = [mean(x(:, [5 6]), 2) mean(y(:, [5 6]), 2)];
                bodyAngles = atan2d(up(:, 2) - down(:, 2), up(:, 1) - down(:, 1));
            case 5 % Shoulders Only
                showPoints = [showPoints 7 : 8];
                center = [mean(x(:, [7 8]), 2) mean(y(:, [7 8]), 2)];
                bodyAngles = atan2d(y(:, 8) - y(:, 7), x(:, 8) - x(:, 7)) + 90;
            case 6 % WingRoots Only
                showPoints = [showPoints 5 : 6];
                center = [mean(x(:, [5 6]), 2) mean(y(:, [5 6]), 2)];
                bodyAngles = atan2d(y(:, 6) - y(:, 5), x(:, 6) - x(:, 5)) + 90;
        end

        showPoints = unique(showPoints); % Get rid of duplicate points (don't display a point twice)
        bodyLinePoints = [center(:, 1) + 200 * cosd(bodyAngles) ...
            center(:, 2) + 200 * sind(bodyAngles) ...
            center(:, 1) - 200 * cosd(bodyAngles) ...
            center(:, 2) - 200 * sind(bodyAngles)];
        bodyAngles = bodyAngles - bodyAngles(1);
        bodyAngles = wrapTo180(bodyAngles);
    end

    %% Get Head Angles Function
    % Using the X and Y points, as well as the calculation method, this
    % function calculates the head angle.
    function getHeadAngles()
        x = xPoints;
        y = yPoints;
        switch headCalcMethod
            case 1 % 7-point Head
                showPoints = [showPoints, 1 : 4, 7 : 9];
                center = [mean(x(:, [1 : 4, 7 : 9]), 2) mean(y(:, [1 : 4, 7 : 9]), 2)];
                up = [mean(x(:, 1 : 4), 2) mean(y(:, 1 : 4), 2)];
                down = [mean(x(:, 7 : 9), 2) mean(y(:, 7 : 9), 2)];
                headAngles = atan2d(up(:, 2) - down(:, 2), up(:, 1) - down(:, 1));
            case 2 % 6-point UD
                showPoints = [showPoints, 1 : 4, 7 : 8];
                center = [mean(x(:, [1 : 4, 7 : 8]), 2) mean(y(:, [1 : 4, 7 : 8]), 2)];
                up = [mean(x(:, 1 : 4), 2) mean(y(:, 1 : 4), 2)];
                down = [mean(x(:, 7 : 8), 2) mean(y(:, 7 : 8), 2)];
                headAngles = atan2d(up(:, 2) - down(:, 2), up(:, 1) - down(:, 1));
            case 3 % 4-point LR
                showPoints = [showPoints 1 : 4];
                center = [mean(x(:, 1 : 4), 2) mean(y(:, 1 : 4), 2)];
                left = [mean(x(:, [1 2]), 2) mean(y(:, [1 2]), 2)];
                right = [mean(x(:, [3 4]), 2) mean(y(:, [3 4]), 2)];
                headAngles = atan2d(left(:, 2) - right(:, 2), left(:, 1) - right(:, 1)) + 90;
            case 4 % 4-point UD
                showPoints = [showPoints 1 : 4];
                center = [mean(x(:, 1 : 4), 2) mean(y(:, 1 : 4), 2)];
                up = [mean(x(:, [2 4]), 2) mean(y(:, [2 4]), 2)];
                down = [mean(x(:, [1 3]), 2) mean(y(:, [1 3]), 2)];
                headAngles = atan2d(up(:, 2) - down(:, 2), up(:, 1) - down(:, 1));
            case 5 % Tips Only
                showPoints = [showPoints 2, 4];
                center = [mean(x(:, [2 4]), 2) mean(y(:, [2 4]), 2)];
                headAngles = atan2d(y(:, 4) - y(:, 2), x(:, 4) - x(:, 2)) + 90;
            case 6 % Roots Only
                showPoints = [showPoints 1, 3];
                center = [mean(x(:, [1 3]), 2) mean(y(:, [1 3]), 2)];
                headAngles = atan2d(y(:, 3) - y(:, 1), x(:, 3) - x(:, 1)) + 90;
        end
        showPoints = unique(showPoints); % Get rid of duplicate points (don't display a point twice)
        headLinePoints = [center(:, 1) + 30 * cosd(headAngles) ...
            center(:, 2) + 30 * sind(headAngles) ...
            center(:, 1) - 30 * cosd(headAngles) ...
            center(:, 2) - 30 * sind(headAngles)];
        headAngles = headAngles - headAngles(1);
        headAngles = wrapTo180(headAngles);
    end

    %% Point Changed
    % This function is called whenever a point is moved and edited.
    function onPointMoved(h, e)
        pointIndex = find(strcmp(BODY_NAMES, h.Label));

        % Update point location
        if pPoints(frameIndex, pointIndex) ~= -inf
            xPoints(frameIndex, pointIndex) =  h.Position(1);
            yPoints(frameIndex, pointIndex) =  h.Position(2);
            pPoints(frameIndex, pointIndex) = inf; % Since this is human inputted, the probability should be inf to signify an unambiguous edited point
            getBodyAngles();
            getHeadAngles();
        end
        
        % If the point is done moving, we must update the body and head
        % angle data for the fly
        if strcmp(e.EventName, 'ROIMoved')
            bodyDataLine.YData = bodyAngles;
            zoomBody.YData = bodyAngles;
            headDataLine.YData = headAngles;
            zoomHead.YData = headAngles;
            markerIndex = find(updatedFrames == frameIndex, 1);

            % If marker has not been added, add it
            if isempty(markerIndex)
                updatedFrames = [updatedFrames; frameIndex];
                updateFrames();
            end
        end
        showFrame();
    end

    %% Button Click Function
    % This function is called whenever something is clicked. It involves 
    % a switch case to determine which button was clicked, and then does
    % stuff accordingly.
    function onClick(b, e)
        fileSwitch('off'); % Disable file switching

        if b ~= playPauseButton
            stop(videoTimer);
            readOnlyPoints.Visible = 'off';
            for i = showPoints
                editPoints{i}.Visible = 'on';
            end
            playPauseButton.String = '>';
        end

        changeDisplay = 1;
        status = 0; % Stores whether the program has exited
        
        switch b
            case folderDisplay
                goodDirectory = 0;
                originalDirectory = directory;
                
                while ~goodDirectory
                    directory = uigetdir(directory, 'Select Video Folder');
                    
                    % If cancel is pressed, directory goes back to original
                    % directory
                    if ~directory
                        directory = originalDirectory;
                    end

                    [videoNames, displayNames, csvNames, procNames] = getVideoNames(directory);
                    
                    if length(videoNames) < 1
                        uiwait(msgbox({'The selected directory does not contain any videos.', ...
                            'Please select a different folder.'}, 'No Videos'));
                    else
                        goodDirectory = 1;
                    end
                end

                b.String = directory;
                filesList.Value = 1;
                filesList.String = displayNames;
                loadVideo(filesList.Value); % Load first video
            case filesList 
                % Save the current video if autosave is selected
                if b.Value ~= currentVideoIndex && autosaveCheckBox.Value == 1
                    onClick(saveButton, []);
                end

                if b.Value ~= currentVideoIndex
                    loadVideo(b.Value); % Load new video only if different index was selected
                end
            case nextFileButton
                if filesList.Value ~= length(videoNames)
                    if autosaveCheckBox.Value == 1
                        onClick(saveButton, []); % Save the current video if autosave is selected
                    end
                    filesList.Value = filesList.Value + 1;
                    loadVideo(filesList.Value);
                end
            case prevFileButton                
                if filesList.Value ~= 1
                    if autosaveCheckBox.Value == 1
                        onClick(saveButton, []);
                    end
                    filesList.Value = filesList.Value - 1;    
                    loadVideo(filesList.Value);
                end
            case progressBar
                val = round(b.Value);
                if val > numFrames
                    val = numFrames;
                elseif val < 1
                    val = 1;
                end
                curFrame = setFrameIndex(val);
            case playPauseButton
                if strcmp(b.String,'>')
                    if frameIndex == numFrames
                        curFrame = setFrameIndex(1);
                    end
                    b.String = string(char(449)); % Set to pause symbol
                    readOnlyPoints.Visible = 'on';
                    for i = 1 : numEditPoints
                        editPoints{i}.Visible = 'off';
                    end
                    start(videoTimer);
                else
                    stop(videoTimer);
                    readOnlyPoints.Visible = 'off';
                    for i = showPoints
                        editPoints{i}.Visible = 'on';
                    end
                    b.String = '>';
                end
            case stopButton
                if strcmp(videoTimer.Running, 'on')
                    stop(videoTimer);
                    readOnlyPoints.Visible = 'off';
                    for i = showPoints
                        editPoints{i}.Visible = 'on';
                    end
                    playPauseButton.String = '>';
                end
                curFrame = setFrameIndex(1);
            case nextFrameButton
                if frameIndex < numFrames && strcmp(videoTimer.Running,'off')
                    curFrame = setFrameIndex(frameIndex + 1);
                end
            case prevFrameButton
                if frameIndex > 1 && strcmp(videoTimer.Running, 'off')
                    curFrame = setFrameIndex(frameIndex - 1);
                end
            case frameDisplay
                value = inputdlg('Pick Frame:', '', [1 30], {num2str(frameIndex)});
                if ~isempty(value) && all(isstrprop(strip(value{1}),'digit')) % Check if it is a digit
                    value = str2double(value{1});
                    if value > 0 && value <= numFrames
                        curFrame = setFrameIndex(value);
                    else
                        changeDisplay = 0;
                    end
                else
                    changeDisplay = 0;
                end            
            case saveButton
                onClick(unmarkButton, []); % Unmark file
                
                procName = procNames{currentVideoIndex};
                fly = struct();
                fly.csv = csv;
                fly.pts.X = xPoints;
                fly.pts.Y = yPoints;
                fly.pts.P = pPoints;
                fly.proc.HeadAng = headAngles;
                fly.proc.BodyAng = bodyAngles;
                fly.track.frameidx = updatedFrames;
                fly.track.bodymethod = bodyCalcMethod;
                fly.track.headmethod = headCalcMethod;
                save(procName, 'fly');

                % Add asterisk to indicate that it has been saved
                if ~strcmp(displayNames{currentVideoIndex}(1), '*')
                    displayNames{currentVideoIndex} = ['*' displayNames{currentVideoIndex}];
                    filesList.String = displayNames;
                end

                index = 0;
                for i = 1 : length(savedFiles)
                    saveFile = savedFiles{i};
                    if strcmp(saveFile{1}, videoNames{currentVideoIndex})
                        index = i;
                        break;
                    end
                end
                if ~index
                    savedFiles{end + 1} =  {videoNames{currentVideoIndex}};
                end

                changeDisplay = 0;
            case deleteButton
                procName = procNames{filesList.Value};
                if isfile(procName)                    
                    delete(procName)
                end

                % Remove asterisk to indicate it has been unsaved
                if strcmp(displayNames{filesList.Value}(1), '*')
                    displayNames{filesList.Value} = displayNames{filesList.Value}(2 : end);
                    filesList.String = displayNames;
                end
                
                index = 0;
                for i = 1 : length(savedFiles)
                    saveFile = savedFiles{i};
                    if strcmp(saveFile{1}, videoNames{currentVideoIndex})
                        index = i;
                        break;
                    end
                end
                if index
                    if length(savedFiles) == 1
                        savedFiles = {};
                    else
                        savedFiles{index} = savedFiles{end};
                        savedFiles = {savedFiles{1 : end - 1}};
                    end
                end
            case moveButton
                if isempty(savedFiles) && isempty(markedFiles)
                    uiwait(msgbox({'There are no videos to move yet.', 'Please mark/save videos first.'}, 'No Videos'));
                    changeDisplay = 0;
                else
                    % Locate config file
                    configFile = dir([DLC_FOLDER filesep 'config.yaml']);
                    if isempty(configFile)
                        error('Cannot find config file. Please confirm that the DLC folder address is set properly.');
                    end
                    
                    % Move videos to final folder
                    for i = 1 : length(savedFiles)
                        moveVideo(savedFiles{i}{1}, FINAL_DATA_FOLDER);
                    end
                    
                    if ~isempty(markedFiles)
                        markedFileString = '';
                        for i = 1 : length(markedFiles)
                            markedFileString = [markedFileString '"' markedFiles{i}{1} '",'];
                        end
                        markedFileString = markedFileString(1 : end - 1); % Get rid of last comma
                        % Add rejected videos to training dataset
                        pyCommand = ['deeplabcut.add_new_videos("' configFile.folder filesep configFile.name '", [' markedFileString '], copy_videos=True)'];
                        pyCommand = strrep(pyCommand, '\', '/');
                        pyrun(pyCommand);
    
                        for i = 1 : length(markedFiles)
                            moveVideo(markedFiles{i}{1}, REJECTED_DATA_FOLDER);
                        end
                    end

                    status = onClose(c, 0, 1);
                end 

                changeDisplay = 0;
            case deleteMarkerButton
                if isempty(updatedFrames)
                    changeDisplay = 0;
                else
                    val = markerDropdownMenu.Value;
                    revised = updatedFrames(val);

                    % Pull from CSV file again
                    xPoints(revised, :) = csv(revised, 2 : 3 : end);
                    yPoints(revised, :) = csv(revised, 3 : 3 : end);
                    pPoints(revised, :) = csv(revised, 4 : 3 : end);
                    updatedFrames(val) = [];
                    updateFrames();
                    getHeadAngles();
                    getBodyAngles();
                    headDataLine.YData = headAngles;
                    bodyDataLine.YData = bodyAngles;
                    if val > 1
                        markerDropdownMenu.Value = val - 1;
                    else
                        sendToDLCButton.Enable = 'off';
                    end
                end
            case gotoMarkerButton
                if isempty(updatedFrames)
                    changeDisplay = 0;
                else
                    curFrame = setFrameIndex(updatedFrames(markerDropdownMenu.Value));
                end
            case nextMarkerButton
                if isempty(updatedFrames)
                    changeDisplay = 0;
                else
                    if markerDropdownMenu.Value == length(updatedFrames)
                        val = 1;
                    else
                        val = markerDropdownMenu.Value + 1;
                    end
                    markerDropdownMenu.Value = val;
                    curFrame = setFrameIndex(updatedFrames(val));
                end
            case prevMarkerButton
                if isempty(updatedFrames)
                    changeDisplay = 0;
                else
                    if markerDropdownMenu.Value == 1
                        val = length(updatedFrames);
                    else
                        val = markerDropdownMenu.Value - 1;
                    end
                    markerDropdownMenu.Value = val;
                    curFrame = setFrameIndex(updatedFrames(val));
                end
            case dataAxis
                if e.Button == 1
                    % Get x coordinate of the place touched
                    val = round(e.IntersectionPoint(1));
                    if val > numFrames
                        val = numFrames;
                    elseif val < 1
                        val = 1;
                    end
                    curFrame = setFrameIndex(val);
                end
            case markButton
                onClick(deleteButton, []); % Delete file proc

                % Add exclamation point to indicate that it has been marked
                if ~strcmp(displayNames{currentVideoIndex}(1), '!')
                    displayNames{currentVideoIndex} = ['!!!' displayNames{currentVideoIndex}];
                    filesList.String = displayNames;
                end
                
                index = 0;
                for i = 1 : length(markedFiles)
                    markedFile = markedFiles{i};
                    if strcmp(markedFile{1}, videoNames{currentVideoIndex})
                        index = i;
                        break;
                    end
                end
                if ~index
                    markedFiles{end + 1} = {videoNames{currentVideoIndex}};
                end

                changeDisplay = 0;
            case unmarkButton
                index = 0;
                for i = 1 : length(markedFiles)
                    markedFile = markedFiles{i};
                    if strcmp(markedFile{1}, videoNames{currentVideoIndex})
                        index = i;
                        break;
                    end
                end
                if index
                    if length(markedFiles) == 1
                        markedFiles = {};
                    else
                        markedFiles{index} = markedFiles{end};
                        markedFiles = {markedFiles{1 : end - 1}};        
                    end
                end

                % Remove exclamation point to indicate it has been unsaved
                if strcmp(displayNames{filesList.Value}(1), '!')
                    displayNames{filesList.Value} = displayNames{filesList.Value}(4 : end);
                    filesList.String = displayNames;
                end

                changeDisplay = 0;
            case sendToDLCButton
                confirm = questdlg('Send to DLC?', 'Confirm', 'Yes', 'No', 'No');

                if strcmp(confirm, 'Yes')
                    sendToDLC();
                end
            case badTrackingMenuItem
                pointIndex = strcmp(BODY_NAMES, b.Parent.Tag);

                % Update point location
                if strcmp(b.Checked, 'off')
                    pPoints(frameIndex, pointIndex) = -inf; % Since this is human inputted, the probability should be inf to signify an unambiguous edited point
                else
                    pPoints(frameIndex, pointIndex) = inf;
                end
                
                getBodyAngles();
                getHeadAngles();
                
                % It marker is not added, add it
                markerIndex = find(updatedFrames == frameIndex, 1);
                if isempty(markerIndex)
                    updatedFrames = [updatedFrames; frameIndex];
                    updateFrames();
                end

                showFrame();
            case editPoints
                b.ContextMenu.Tag = b.Label;
                
                pointIndex = find(strcmp(BODY_NAMES, b.Label), 1);
                if ~isempty(pointIndex)
                    if pPoints(frameIndex, pointIndex) == -inf
                        badTrackingMenuItem.Checked = 'on';
                    else
                        badTrackingMenuItem.Checked = 'off';
                    end
                end
            otherwise
                error('I do not know how you did this, but you did something wrong. Contact your local Mike Rauscher for assistance');
        end

        % If display needs to be changed 
        if strcmp(videoTimer.Running, 'off') && changeDisplay
            showFrame();
        end
        
        if ~status
            fileSwitch('on'); % Enable file switching
        end
    end

    %% File Switching GUI Function
    % This function fixes the bug where autosave will accidentally save 
    % the wrong information for the wrong video. To remedy this issue, 
    % this function will block the file switching GUI until the GUI is 
    % finished executing.
    function fileSwitch(status)
        prevFileButton.Enable = status;
        nextFileButton.Enable = status;
        markButton.Enable = status;
        unmarkButton.Enable = status;
        moveButton.Enable = status;
        sendToDLCButton.Enable = status;
        deleteButton.Enable = status;
        saveButton.Enable = status;
        filesList.Enable = status;

        if ~isempty(updatedFrames)
            sendToDLCButton.Enable = status;
        end
    end

    %% Move Video Function
    % This function moves the video to the specified folder.
    function moveVideo(videoName, folder)
        baseName = extractBefore(videoName, '_0000');
        relatedFiles = dir([baseName '*']);

        for i = 1 : length(relatedFiles)
            file = fullfile(relatedFiles(i).folder, relatedFiles(i).name);
            movefile(file, folder);
        end
    end

    %% Load Video Function
    % Loads the video at a certain index.
    function loadVideo(videoIndex)
        % Stop video playback if running
        if strcmp(videoTimer.Running, 'on')
            stop(videoTimer);
            playPauseButton.String = '>';
        end        
        
        % Update video reader
        currentVideoIndex = videoIndex;
        videoReader = VideoReader(videoNames{videoIndex});

        numFrames = videoReader.NumFrames;
        progressBar.Value = 1;
        progressBar.SliderStep = [1 / (numFrames - 1) 1 / (numFrames - 1)];
        progressBar.Max = numFrames;
        
        curFrame = setFrameIndex(1);
        im = image(videoAxis, curFrame); % Add frame to video

        % Update video frame
        clear('bodyVideoLine');
        clear('headVideoLine');
        clear('readOnlyPoints');
        clear('editPoints');
        
        hold(videoAxis, 'on');
        bodyVideoLine = plot(videoAxis, [nan nan], [nan nan], '--', ...
            'Color', BODY_COLOR, 'LineWidth', 1.5);
        headVideoLine = plot(videoAxis, [nan nan], [nan nan], ...
            'Color', HEAD_COLOR, 'LineWidth', 2.5);

        if SHOW_WINGS
            wingLline = plot(videoAxis, [nan nan], [nan nan], ...
                'Color', 'r', 'LineWidth', 2);
            wingRline = plot(videoAxis, [nan nan], [nan nan], ...
                'Color', 'r', 'LineWidth', 2);
        end

        readOnlyPoints = plot(videoAxis, nan, nan, '*', ...
            'Color', 'm', 'Visible','off');

        % Plot points that can be edited and moved around, for use if the video
        % is not playing
        editPoints = cell(1, numEditPoints);
        
        % Make menu for ROI points
        wingPointMenu = uicontextmenu;
        badTrackingMenuItem = uimenu(wingPointMenu, 'Text', 'Bad Tracking', 'Checked', 'off');
        badTrackingMenuItem.MenuSelectedFcn = @onClick;

        % Loop through each point that can be displayed
        for k = 1 : numEditPoints
            newPoint = images.roi.Point(videoAxis);
            newPoint.Color = COLOR_MAP(k, :);
            newPoint.Label = BODY_NAMES{k};
            newPoint.LabelVisible = 'hover';
            newPoint.Deletable = 0;
            addlistener(newPoint, 'MovingROI', @onPointMoved);
            addlistener(newPoint, 'ROIMoved', @onPointMoved);
            addlistener(newPoint, 'ROIClicked', @onClick);
    
            editPoints{k} = newPoint;

            if k > 11
                set(newPoint, 'uicontextmenu', wingPointMenu);
            end
        end

        xticks(videoAxis, []);
        yticks(videoAxis, []);
        hold(videoAxis, 'off');

        % Update fly data
        loadFly(videoIndex);
        getHeadAngles();
        getBodyAngles();

        % Update data axis
        hold(dataAxis, 'on');
        xlim(dataAxis, [0 numFrames]);
        xticks(dataAxis,[1 500 : 500 : numFrames]);
        bodyDataLine.XData = 1 : numFrames;
        bodyDataLine.YData = bodyAngles;
        headDataLine.XData = 1 : numFrames;
        headDataLine.YData = headAngles;
        zoomBody.XData = 1 : numFrames;
        zoomBody.YData = bodyAngles;
        zoomHead.XData = 1 : numFrames;
        zoomHead.YData = headAngles;
        zoomAxis.XTick = 1 : numFrames;
        hold(dataAxis, 'off');
        
        updateTrackingParameters(bodyButtons(bodyCalcMethod));
        updateFrames();
        showFrame();
    end
    
    %% Update Frames Function
    % This function updates the revised frames in the dropdown menu and 
    % on the angle graph.
    function updateFrames()
        [updatedFrames, sortingIndices] = sort(updatedFrames); % Sort frames in increasing order

        % If there are no updated frames anymore, clear the dropdown menu
        if isempty(updatedFrames)
            markerDropdownMenu.Value = 1;
            markerDropdownMenu.String = ' ';
            sendToDLCButton.Enable = 'off';
        else
            frameStrings = cell(length(updatedFrames)); % Store the names of the frames that were updated
            
            % Add each updated frame's name with 'F' prepended to the
            % dropdown menu
            for i = 1 : length(updatedFrames)
                frameStrings{i} = ['F' num2str(updatedFrames(i))];
            end
            markerDropdownMenu.String = frameStrings; % Set the frames in the dropdown menu
            markerDropdownMenu.Value = sortingIndices(end); % Set the selection to be the last updated frame
            sendToDLCButton.Enable = 'on';
        end    
        
        timerRunning = strcmp(videoTimer.Running, 'on'); % Check if the video timer was running before
        if timerRunning
            stop(videoTimer); % Stop video timer if it was running
        end

        % Plot edited lines
        hold(dataAxis, 'on');

        % Delete existing edited lines
        delete(editLines);

        if ~isempty(updatedFrames)
            try
                editLines = plot(dataAxis, [updatedFrames updatedFrames]', [-180 180], '--', 'Color', EDIT_COLOR);
            catch
                disp('!');
            end

            % Coder's note: I do not know why there is a try/catch
            % here, but I'm not removing it. - nxz157, 7/19/2023

            drawnow; % Update figure
        end

        dataAxis.XGrid = 'on';
        hold(dataAxis, 'off');

        % Restart timer if it was running before
        if timerRunning
            start(videoTimer);
        end
    end
    
    %% Load Fly Function
    % This function loads the fly struct from the PROC file if created;
    % otherwise, it calls loadCSV() to get the X and Y points from the 
    % DLC CSV.
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
    % This function loads the DLC CSV file and pulls the X and Y points, 
    % as well as the confidence.
    function loadCSV()
        csv = readmatrix(csvNames{currentVideoIndex}, 'Range', 4);
        xPoints = csv(:, 2 : 3 : end);
        yPoints = csv(:, 3 : 3 : end);
        pPoints = csv(:, 4 : 3 : end);
        updatedFrames = [];
    end

    %% Set Frame Index Function
    % This function sets the frame index to the specified index, 
    % changing the progress bar, the display, and the video reader to 
    % reflect that change.
    function frame = setFrameIndex(index)
        frameIndex = index; % Set frame index to the new index
        frame = read(videoReader, index); % Read in new index
        progressBar.Value = index;
        frameDisplay.String = ['Frame ' num2str(index) ' of ' num2str(numFrames)];
        curFrameLine.Value = index;
        curFrameZoomLine.Value = index;
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
                    
                    index = 0;
                    for i = 1 : length(savedFiles)
                        saveFile = savedFiles{i};
                        if strcmp(saveFile{1}, videoFiles{end})
                            index = i;
                            break;
                        end
                    end
                    if ~index
                        savedFiles{end + 1} =  {videoFiles{end}};
                    end
                end
            end
        end
    end
    
    %% Update GUI Function
    % Whenever the size of the window is changed, this function adjusts 
    % the components of the GUI to fit the newly updated window.
    function onSizeChanged(h, ~)
        % Update video reader
        videoAxis.Position(2) = h.Position(4) * .3;
        videoAxis.Position(4) = h.Position(4) - videoAxis.Position(2) + 1;
        videoAxis.Position(3) = videoAxis.Position(4) * 4 / 3;
        videoAxis.Position(1) = 0;

        % Update file list
        filesList.Position(1) = 0;
        filesList.Position(3) = videoAxis.Position(3) - 225;
        filesList.Position(4) = videoAxis.Position(2) - 25;

        % Update file buttons
        prevFileButton.Position(1) = filesList.Position(3);
        prevFileButton.Position(2) = filesList.Position(4) / 2;
        prevFileButton.Position(3) = 75;
        prevFileButton.Position(4) = filesList.Position(4) / 2;

        nextFileButton.Position(1) = filesList.Position(3); 
        nextFileButton.Position(2) = 0;
        nextFileButton.Position(3) = 75;
        nextFileButton.Position(4) = filesList.Position(4) / 2;

        % Update move button
        moveButton.Position(1) = filesList.Position(3) + 150;
        moveButton.Position(2) = 0;
        moveButton.Position(3) = 75;
        moveButton.Position(4) = filesList.Position(4) / 3;

        % Update delete button
        deleteButton.Position = moveButton.Position;
        deleteButton.Position(2) = deleteButton.Position(2) + deleteButton.Position(4);
        
        % Update save button
        saveButton.Position = deleteButton.Position;
        saveButton.Position(2) = saveButton.Position(2) + saveButton.Position(4);
        
        % Update mark button
        sendToDLCButton.Position(1) = filesList.Position(3) + 75;
        sendToDLCButton.Position(2) = 0;
        sendToDLCButton.Position(3) = 75;
        sendToDLCButton.Position(4) = filesList.Position(4) / 3;
        
        % Update unmark button
        unmarkButton.Position = sendToDLCButton.Position;
        unmarkButton.Position(2) = sendToDLCButton.Position(2) + sendToDLCButton.Position(4);

        % Update send to DLC button
        markButton.Position = unmarkButton.Position;
        markButton.Position(2) = unmarkButton.Position(2) + unmarkButton.Position(4);

        % Update folder display
        folderDisplay.Position(1) = 0;
        folderDisplay.Position(2) = filesList.Position(4);
        folderDisplay.Position(3) = filesList.Position(3) + 100;
        folderDisplay.Position(4) = 25;
    
        % Update autosave checkbox
        autosaveCheckBox.Position = saveButton.Position;
        autosaveCheckBox.Position(1) = folderDisplay.Position(1) + folderDisplay.Position(3) + 20;
        autosaveCheckBox.Position(2) = autosaveCheckBox.Position(2) + autosaveCheckBox.Position(4);
        autosaveCheckBox.Position(3) = autosaveCheckBox.Position(3) + 20;
        autosaveCheckBox.Position(4) = 20;

        % Update data window
        dataAxis.Position(1) = videoAxis.Position(3) + 35;
        dataAxis.Position(2) = 75;
        dataAxis.Position(3) = h.Position(3) - videoAxis.Position(3) - 35; 
        dataAxis.Position(4) = h.Position(4) - 430;

        % Update zoomed data window
        zoomAxis.Position(1) = dataAxis.Position(1);
        zoomAxis.Position(2) = dataAxis.Position(2) + dataAxis.Position(4) + 30;
        zoomAxis.Position(3) = dataAxis.Position(3);
        zoomAxis.Position(4) = 200;

        % Update video buttons
        playPauseButton.Position(1) = videoAxis.Position(3) + 5;
        playPauseButton.Position(2) = h.Position(4) - 55;
        playPauseButton.Position(3) = 50;
        playPauseButton.Position(4) = 50;

        stopButton.Position = playPauseButton.Position;
        stopButton.Position(1) = stopButton.Position(1) + 50;

        % Update frame display buttons
        frameDisplay.Position(1) = stopButton.Position(1) + stopButton.Position(3) + 7;
        frameDisplay.Position(2) = h.Position(4) - 30;
        frameDisplay.Position(3) = h.Position(3) - frameDisplay.Position(1) - 7;
        frameDisplay.Position(4) = 25;

        % Update progress bar
        progressBar.Position(1) = stopButton.Position(1) + stopButton.Position(3) + 7;
        progressBar.Position(2) = h.Position(4) - 55;
        progressBar.Position(3) = h.Position(3) - progressBar.Position(1) - 7;
        progressBar.Position(4) = 25;
        
        % Update frame buttons
        prevFrameButton.Position = playPauseButton.Position;
        prevFrameButton.Position(2) = prevFrameButton.Position(2) - 60;
        nextFrameButton.Position = prevFrameButton.Position;
        nextFrameButton.Position(1) = nextFrameButton.Position(1) + 50;
        
        % Update body buttons
        body7PtButton.Position(1) = nextFrameButton.Position(1) + nextFrameButton.Position(3) + 7;
        body7PtButton.Position(2)= nextFrameButton.Position(2) + 25;
        body7PtButton.Position(3) = 70;
        body7PtButton.Position(4) = 25;
        
        body6UDButton.Position(1) = nextFrameButton.Position(1) + nextFrameButton.Position(3) + 7;
        body6UDButton.Position(2)= nextFrameButton.Position(2);
        body6UDButton.Position(3) = 70;
        body6UDButton.Position(4) = 25;
        
        body4LRButton.Position(1) = body7PtButton.Position(1) + body7PtButton.Position(3) + 1;
        body4LRButton.Position(2) = body7PtButton.Position(2);
        body4LRButton.Position(3) = 70;
        body4LRButton.Position(4) = 25;
        
        body4UDButton.Position(1) = body6UDButton.Position(1) + body6UDButton.Position(3) + 1;
        body4UDButton.Position(2) = body6UDButton.Position(2);
        body4UDButton.Position(3) = 70;
        body4UDButton.Position(4) = 25;
        
        body2SButton.Position(1) = body4UDButton.Position(1) + body4UDButton.Position(3) + 1;
        body2SButton.Position(2) = body4UDButton.Position(2);
        body2SButton.Position(3) = 70;
        body2SButton.Position(4) = 25;
        
        body2WButton.Position(1) = body4LRButton.Position(1) + body4LRButton.Position(3) + 1;
        body2WButton.Position(2) = body4LRButton.Position(2);
        body2WButton.Position(3) = 70;
        body2WButton.Position(4) = 25;                
        
        % Update head buttons
        head7PtButton.Position(1) = body2WButton.Position(1) + body2WButton.Position(3) + 7;
        head7PtButton.Position(2) = body2WButton.Position(2);
        head7PtButton.Position(3) = 70;
        head7PtButton.Position(4) = 25;
        
        head6UDButton.Position(1) = body2SButton.Position(1) + body2SButton.Position(3) + 7;
        head6UDButton.Position(2) = body2SButton.Position(2);
        head6UDButton.Position(3) = 70;
        head6UDButton.Position(4) = 25;
        
        head4LRButton.Position(1) = head7PtButton.Position(1) + head7PtButton.Position(3) + 1;
        head4LRButton.Position(2) = head7PtButton.Position(2);
        head4LRButton.Position(3) = 70;
        head4LRButton.Position(4) = 25;
        
        head4UDButton.Position(1) = head6UDButton.Position(1) + head6UDButton.Position(3) + 1;
        head4UDButton.Position(2) = head6UDButton.Position(2);
        head4UDButton.Position(3) = 70;
        head4UDButton.Position(4) = 25; 
        
        head2TButton.Position(1) = head4LRButton.Position(1) + head4LRButton.Position(3) + 1;
        head2TButton.Position(2) = head4LRButton.Position(2);
        head2TButton.Position(3) = 70;
        head2TButton.Position(4) = 25;
        
        head2RButton.Position(1) = head4UDButton.Position(1) + head4UDButton.Position(3) + 1;
        head2RButton.Position(2) = head4UDButton.Position(2);
        head2RButton.Position(3) = 70;
        head2RButton.Position(4) = 25;     

        % Update marker buttons
        nextMarkerButton.Position(1) = h.Position(3) - 340;
        nextMarkerButton.Position(2) = nextFrameButton.Position(2);
        nextMarkerButton.Position(3) = 30;
        nextMarkerButton.Position(4) = 25;        
        
        prevMarkerButton.Position = nextMarkerButton.Position;
        prevMarkerButton.Position(2) = nextMarkerButton.Position(2) + 25;

        gotoMarkerButton.Position = nextMarkerButton.Position;
        gotoMarkerButton.Position(1) = nextMarkerButton.Position(1) + 33;
        gotoMarkerButton.Position(3) = 150;

        deleteMarkerButton.Position = gotoMarkerButton.Position;
        deleteMarkerButton.Position(1) = gotoMarkerButton.Position(1)+150;

        % Update marker dropdown menu
        markerDropdownMenu.Position = prevMarkerButton.Position;
        markerDropdownMenu.Position(1) = prevMarkerButton.Position(1) + 33;
        markerDropdownMenu.Position(3) = 299;
    end

    %% Send to DLC Function
    % This function sends the revised points to DLC. This also saves the
    % points to the PROC file as well.
    function sendToDLC()
        % Clear bad tracking points and set them to NaN
        dlcXPoints = xPoints(updatedFrames, :);
        dlcYPoints = yPoints(updatedFrames, :);
        dlcPPoints = pPoints(updatedFrames, :);
        [row, col] = find(dlcPPoints == -inf);
        dlcXPoints(row, col) = nan;
        dlcYPoints(row, col) = nan;

        % Check if folder name exists
        folderName = extractAfter(extractBefore(displayNames{currentVideoIndex}, 'DLC_'), '*');
        folder = dir([DLC_FOLDER filesep 'labeled-data' filesep folderName]);
        
        % Check if folder exists
        if isempty(folder)
            dlcFolder = dir(DLC_FOLDER);
            dlcFolder = dlcFolder(1).folder;
            mkdir(fullfile(dlcFolder, 'labeled-data'), folderName);
            folder = dir([DLC_FOLDER filesep 'labeled-data' filesep folderName]);
        end

        % Locate config file
        configFile = dir([DLC_FOLDER filesep 'config.yaml']);
        if isempty(configFile)
            error('Cannot find config file. Please confirm that the DLC folder address is set properly.');
        end

        % Load config file
        configFile = configFile(1);
        config = fileread([configFile.folder filesep configFile.name]);
        scorer = char(extractBetween(config, 'scorer: ', 'date')); % Get scorer
        scorer = scorer(1 : end - 2); % Get rid of the last 2 characters since they are new line shenanigans
        
        csvFile = dir([folder(1).folder filesep '*.csv']);

        % Check if CSV file exists
        if isempty(csvFile)
            % Get points to go into csv file
            labeledPoints = zeros(length(updatedFrames), length(BODY_NAMES) * 2 + 1); % Make labeled points matrix

            % Add updated frames
            for i = 1 : length(updatedFrames)   
                newPoints = zeros(1, length(BODY_NAMES) + 1); % Pre-allocate new points matrix

                % Interleave x and y points
                for k = 1 : length(BODY_NAMES)
                    newPoints(k * 2) = dlcXPoints(i, k);
                    newPoints(k * 2 + 1) = dlcYPoints(i, k);
                end
                
                newPoints(1) = updatedFrames(i) - 1; % Prepend frame number (but starting with 0 indexing)
                labeledPoints(i, :) = newPoints; % Add row to labeledPoints
            end

            labeledPoints = sort(labeledPoints, 1); % Sort so frames are in order
        else
            % Load existing CSV file
            labeledData = fileread([csvFile(1).folder filesep csvFile(1).name]);
            labeledDataLines = splitlines(labeledData);

            % Get rid of last line if blank
            lastLine = labeledDataLines(end);
            if isempty(lastLine{1, 1})
                labeledDataLines = labeledDataLines(1 : end - 1);
            end
            labeledDataLines = labeledDataLines(4 : end); % Get rid of first 3 lines
            
            labeledPoints = zeros(count(labeledData, 'labeled-data'), length(BODY_NAMES) * 2 + 1); % Pre-allocate matrix
            
            for i = 1 : count(labeledData, 'labeled-data')
                line = labeledDataLines{i};

                % Extract image name
                frame = extractBetween(line, 'img', '.png');
                labeledPoints(i, 1) = str2double(frame);

                % Extract points
                pointString = extractAfter(line, '.png,');
                points = split(pointString, ','); % Split by commas

                % Loop through each point
                for k = 1 : length(points)
                    point = points(k);
                    if ~isempty(point)
                        labeledPoints(i, k + 1) = str2double(point); % There is some precision loss when converting to MATLAB most likely but it's negligible
                    else
                        labeledPoints(i, k + 1) = NaN; % If there is nothing there, that means that it wasn't marked
                    end
                end
            end
            
            % Add updated frames
            for i = 1 : length(updatedFrames)   
                newPoints = zeros(1, length(BODY_NAMES) + 1); % Pre-allocate new points matrix

                % Interleave x and y points
                for k = 1 : length(BODY_NAMES)
                    newPoints(k * 2) = dlcXPoints(i, k);
                    newPoints(k * 2 + 1) = dlcYPoints(i, k);
                end
                
                newPoints(1) = updatedFrames(i) - 1; % Prepend frame number (but starting with 0 indexing)

                rowIndex = find(labeledPoints(1, :) == newPoints(1), 1); % Find row of existing frame if it exists already
                % Add row to labeledPoints if they don't exist yet
                if isempty(rowIndex)
                    labeledPoints(end + 1, :) = newPoints; % Add row to end of labeledPoints
                else
                    labeledPoints(rowIndex, :) = newPoints; % Replace existing row with new data
                end
            end

            labeledPoints = sort(labeledPoints, 1); % Sort so frames are in order
        end

        % Make new CSV file
        % Make first lines
        scorerLine = [{'scorer'}, {''}, {''}, repmat({scorer}, 1, length(BODY_NAMES) * 2)];
        partsLine = [{'bodyparts'}, {''}, {''}];
        
        % Add body parts
        for i = 1 : length(BODY_NAMES)
            partsLine = [partsLine BODY_NAMES{i} BODY_NAMES{i}];
        end
        
        coordsLine = [{'coords'}, {''}, {''}, repmat([{'x'}, {'y'}], 1, length(BODY_NAMES))];
        
        firstLines = {scorerLine; partsLine; coordsLine};
        
        leadingZeros = ['%0' num2str(floor(log10(numFrames)) + 1) 'd']; % Get leading zeros to match DLC naming convention
                        
        % Add video using deeplabcut command
        pyCommand = ['deeplabcut.add_new_videos("' configFile.folder filesep configFile.name '", ["' videoNames{currentVideoIndex} '"], copy_videos=True)'];
        pyCommand = strrep(pyCommand, '\', '/'); % Replace slashes
        pyrun(pyCommand);

        dataLines = cell(size(labeledPoints, 1), 1);
        % Add actual data
        for i = 1 : size(labeledPoints, 1)
            imgName = ['img' num2str(labeledPoints(i, 1), leadingZeros) '.png']; % Gets image name
            
            % Add image line to new csv
            dataLine = [{'labeled-data'}, {folderName}, {imgName}];
            
            % Add bodypart coordinates
            for k = 1 : length(BODY_NAMES) * 2
                dataLine = [dataLine cellstr(num2str(labeledPoints(i, k + 1)))];
            end
            
            strrep(dataLine, 'NaN', ''); % Replace NaN values with empty Strings
            % Add to data lines
            dataLines{i, 1} = dataLine;

            % Create image for frame
            newFile = fullfile(folder(1).folder, imgName); % Create file
            newImage = read(videoReader, labeledPoints(i, 1) + 1); % Get image data
            imwrite(newImage, newFile); % Write to new file
        end

        % Combine all csv lines into one
        newCsv = [firstLines; dataLines];
        
        % Write table to CSV
        outCsvFileName = [folder(1).folder filesep ['CollectedData_' scorer '.csv']];
        outFile = fullfile(outCsvFileName);

        writetable(cell2table(newCsv), outFile, 'WriteVariableNames', 0); % Write to CSV file
        
        % Run Python CSV to h5 using deeplabcut
        pyCommand = ['deeplabcut.convertcsv2h5("' configFile.folder filesep configFile.name '", userfeedback=False)'];
        pyCommand = strrep(pyCommand, '\', '/'); % Replace slashes

        pyrun(pyCommand); % Convert csv to h5
    end
    
    %% Closing Function
    % The below function is run whenever a user attempts to close the 
    % figure. A confirmation is given, and then the settings are
    % saved for next time.
    function status = onClose(~, ~, force)
        if nargin < 3
            force = 0;
        end

        if force == 1
            uiwait(msgbox({'Videos moved successfully.', 'Quitting in 5 seconds...'}, 'Quitting'), 5);
            drawnow; % Update figure
            closereq; % Close figure
            status = 1;
            return;
        end

        % Display confirmation message
        confirm = questdlg('Quit?', '', 'Yes', 'No', 'No');

        if ~strcmp(confirm, 'Yes')
            return;
        end

        if autosaveCheckBox.Value == 1
            onClick(saveButton, []); % Click save button before proceeding
        end

        % Save settings file
        settings = struct();
        settings.autosave = autosaveCheckBox.Value;
        settings.lastfile = videoNames{filesList.Value};
        settings.dir = directory;

        % Save into stepperdlcvalidator.set
        save(settingsFile, 'settings');

        stop(videoTimer); % Stops frame succession if it was running
        drawnow; % Update figure
        closereq; % Close figure
        status = 0;
    end
end