function StepperTool
    STEPPER_PORT = 'COM3';
    stepper = serialport(STEPPER_PORT, 9600);
    stepper.OutputBufferSize = 1024;

    f = figure;
    f.Resize = 'off';
    f.NumberTitle = 'off';
    f.MenuBar = 'none';
    f.Name = 'Stepper Motor Tool';
    f.Position = [100 200 300 600];
    
    resetbtn = uicontrol(f,'style','pushbutton','Callback',@buttons,...
        'Position',[0 500 300 100],'string','Reset Stepper Controller');
    
    leftbtn = uicontrol(f,'style','pushbutton','Callback',@buttons,...
        'Position',[0 400 150 100],'string','< Single Step Left');
    rightbtn = uicontrol(f,'style','pushbutton','Callback',@buttons,...
        'Position',[150 400 150 100],'string','Single Step Right >');
    
    left12btn = uicontrol(f,'style','pushbutton','Callback',@buttons,...
        'Position',[0 300 150 100],'string','< Step Left 1/8 Turn');
    right12btn = uicontrol(f,'style','pushbutton','Callback',@buttons,...
        'Position',[150 300 150 100],'string','Step Right 1/8 Turn >');
    
    left24btn = uicontrol(f,'style','pushbutton','Callback',@buttons,...
        'Position',[0 200 150 100],'string','< Step Left 1/4 Turn');
    right24btn = uicontrol(f,'style','pushbutton','Callback',@buttons,...
        'Position',[150 200 150 100],'string','Step Right 1/4 Turn >');
    
    left48btn = uicontrol(f,'style','pushbutton','Callback',@buttons,...
        'Position',[0 100 150 100],'string','< Step Left 1/2 Turn');
    right48btn = uicontrol(f,'style','pushbutton','Callback',@buttons,...
        'Position',[150 100 150 100],'string','Step Right 1/2 Turn >');
    
    left96btn = uicontrol(f,'style','pushbutton','Callback',@buttons,...
        'Position',[0 0 150 100],'string','< Step Left Full Turn');
    right96btn = uicontrol(f,'style','pushbutton','Callback',@buttons,...
        'Position',[150 0 150 100],'string','Step Right Full Turn >');
    function buttons(h,~)
        

        switch h
            case resetbtn
                Stepper_com(stepper, 'reset');
            case leftbtn
                Stepper_com(stepper, 'step_left',1)
            case rightbtn
                Stepper_com(stepper, 'step_right',1)
            case left12btn
                Stepper_com(stepper, 'step_left',12)
            case right12btn
                Stepper_com(stepper, 'step_right',12)
            case left24btn
                Stepper_com(stepper, 'step_left',24)
            case right24btn
                Stepper_com(stepper, 'step_right',24)
            case left48btn
                Stepper_com(stepper, 'step_left',48)
            case right48btn
                Stepper_com(stepper, 'step_right',48)
            case left96btn
                Stepper_com(stepper, 'step_left',96)
            case right96btn
                Stepper_com(stepper, 'step_right',96)
        end
    end
end