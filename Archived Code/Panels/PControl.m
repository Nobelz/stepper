function varargout = PControl(varargin)
% PCONTROL M-file for PControl.fig

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PControl_OpeningFcn, ...
                   'gui_OutputFcn',  @PControl_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before PControl is made visible.
function PControl_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.Running = 0;

% run the init program - 
handles.PC = PControl_init;

set(handles.x_gain_slider, 'max', handles.PC.x_gain_max ,'min', ...
    handles.PC.x_gain_min,'Value',handles.PC.x_gain_val);
set(handles.x_gain_val, 'String', [num2str(handles.PC.x_gain_val) ' X']);

set(handles.y_gain_slider, 'max', handles.PC.y_gain_max ,'min', ...
    handles.PC.y_gain_min,'Value',handles.PC.y_gain_val);
set(handles.y_gain_val, 'String', [num2str(handles.PC.y_gain_val) ' X']);

set(handles.x_offset_slider, 'max', handles.PC.x_offset_max ,'min', ...
    handles.PC.x_offset_min,'Value',handles.PC.x_offset_val);
set(handles.x_offset_val, 'String', [num2str(handles.PC.x_offset_val) ' V']);

set(handles.y_offset_slider, 'max', handles.PC.y_offset_max ,'min', ...
    handles.PC.y_offset_min,'Value',handles.PC.y_offset_val);
set(handles.y_offset_val, 'String', [num2str(handles.PC.y_offset_val) ' V']);

% Update handles structure
guidata(hObject, handles);
update_status_display(handles, '> > > > >  Welcome to the Panels control program  < < < < < <');


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)

selection = questdlg('Close Panel Controller?','Close Request Function', 'Yes','No','Yes');
switch selection,
   case 'Yes',
     delete(hObject)
   case 'No'
     return
end


% --- Outputs from this function are returned to the command line.
function varargout = PControl_OutputFcn(hObject, eventdata, handles)
% no outputs, so this function does nothing fancy
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function x_gain_slider_CreateFcn(hObject, eventdata, handles)
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on slider movement.
function x_gain_slider_Callback(hObject, eventdata, handles)
handles.PC.x_gain_val = round(get(hObject,'Value')*10)/10;   % this is done so only one dec place
set(handles.x_gain_val, 'String', [num2str(handles.PC.x_gain_val) ' X']);
guidata(hObject, handles);
%send command to controller
Send_Gain_Bias(handles);

% --- Executes on button press in x_gain_zero.
function x_gain_zero_Callback(hObject, eventdata, handles)
% set slider value to zero and execute the slider call back
set(handles.x_gain_slider, 'Value', 0); 
x_gain_slider_Callback(handles.x_gain_slider, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function x_offset_slider_CreateFcn(hObject, eventdata, handles)
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on slider movement.
function x_offset_slider_Callback(hObject, eventdata, handles)
handles.PC.x_offset_val = round(get(hObject,'Value')*10)/10;
set(handles.x_offset_val, 'String', [num2str(handles.PC.x_offset_val) ' V']);
guidata(hObject, handles);
%send command to controller
Send_Gain_Bias(handles);

% --- Executes on button press in x_offset_zero.
function x_offset_zero_Callback(hObject, eventdata, handles)
% set slider value to zero and execute the slider call back
set(handles.x_offset_slider, 'Value', 0); 
x_offset_slider_Callback(handles.x_offset_slider, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function y_gain_slider_CreateFcn(hObject, eventdata, handles)
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on slider movement.
function y_gain_slider_Callback(hObject, eventdata, handles)

handles.PC.y_gain_val = round(get(hObject,'Value')*10)/10;
set(handles.y_gain_val, 'String', [num2str(handles.PC.y_gain_val) ' X']);
guidata(hObject, handles);
%send command to controller
Send_Gain_Bias(handles);


% --- Executes on button press in y_gain_zero.
function y_gain_zero_Callback(hObject, eventdata, handles)
% set slider value to zero and execute the slider call back
set(handles.y_gain_slider, 'Value', 0); 
y_gain_slider_Callback(handles.y_gain_slider, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function y_offset_slider_CreateFcn(hObject, eventdata, handles)
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on slider movement.
function y_offset_slider_Callback(hObject, eventdata, handles)
handles.PC.y_offset_val = round(get(hObject,'Value')*10)/10; 
set(handles.y_offset_val, 'String', [num2str(handles.PC.y_offset_val) ' V']);
guidata(hObject, handles);
%send command to controller
Send_Gain_Bias(handles);


% --- Executes on button press in y_offset_zero.
function y_offset_zero_Callback(hObject, eventdata, handles)
% set slider value to zero and execute the slider call back
set(handles.y_offset_slider, 'Value', 0); 
y_offset_slider_Callback(handles.y_offset_slider, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function Pattern_ID_menu_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



% --- Executes during object creation, after setting all properties.
function x_pos_val_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function x_pos_val_Callback(hObject, eventdata, handles)
%        str2double(get(hObject,'String')) returns contents of x_pos_val as a double
user_entry = str2double(get(hObject,'string'));
if isnan(user_entry)
    errordlg('You must enter a numeric value','Bad Input','modal')
    set(handles.x_pos_val, 'string', num2str(handles.PC.x_pos));
elseif (user_entry ~= round(user_entry) )
    errordlg('You must enter an integer','Bad Input','modal')
    set(handles.x_pos_val, 'string', num2str(handles.PC.x_pos));
elseif ( (user_entry < 0)|(user_entry > handles.PC.pattern_x_size(handles.PC.current_pattern) ) )
    errordlg('Number is out of the range for this pattern','Bad Input','modal')
    set(handles.x_pos_val, 'string', num2str(handles.PC.x_pos));
else  % once you get here this is actually good input
    handles.PC.x_pos = user_entry;
    guidata(hObject, handles);
    %send x and y pos out to controller
    Panel_com('set_position', [handles.PC.x_pos, handles.PC.y_pos]);
end



% --- Executes during object creation, after setting all properties.
function y_pos_val_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function y_pos_val_Callback(hObject, eventdata, handles)
%        str2double(get(hObject,'String')) returns contents of y_pos_val as a double
user_entry = str2double(get(hObject,'string'));
if isnan(user_entry)
    errordlg('You must enter a numeric value','Bad Input','modal')
    set(handles.y_pos_val, 'string', num2str(handles.PC.y_pos));
elseif (user_entry ~= round(user_entry) )
    errordlg('You must enter an integer','Bad Input','modal')
    set(handles.y_pos_val, 'string', num2str(handles.PC.y_pos));
elseif ( (user_entry < 0)|(user_entry > handles.PC.pattern_y_size(handles.PC.current_pattern)) )
    errordlg('Number is out of the range for this pattern','Bad Input','modal')
    set(handles.y_pos_val, 'string', num2str(handles.PC.y_pos));
else    % once you get here this is actually good input
    handles.PC.y_pos = user_entry;
    guidata(hObject, handles);
    %send x and y pos out to controller
    Panel_com('set_position', [handles.PC.x_pos, handles.PC.y_pos]);
end


% --- Executes on button press in x_pos_plus.
function x_pos_plus_Callback(hObject, eventdata, handles)
% increment the x_pos, wrap around if too big
temp_pos = handles.PC.x_pos + 1;
if (temp_pos > handles.PC.pattern_x_size(handles.PC.current_pattern))
    temp_pos = 1;
end
handles.PC.x_pos = temp_pos;
set(handles.x_pos_val, 'string', num2str(temp_pos));
guidata(hObject, handles);
%send x and y pos out to controller
Panel_com('set_position', [handles.PC.x_pos, handles.PC.y_pos]);


% --- Executes on button press in x_pos_minus.
function x_pos_minus_Callback(hObject, eventdata, handles)
% decrement the x_pos, wrap around if hits zero
temp_pos = handles.PC.x_pos - 1;
if (temp_pos <= 0) 
    temp_pos = handles.PC.pattern_x_size(handles.PC.current_pattern);
end
handles.PC.x_pos = temp_pos;
set(handles.x_pos_val, 'string', num2str(temp_pos));
guidata(hObject, handles);
%send x and y pos out to controller
Panel_com('set_position', [handles.PC.x_pos, handles.PC.y_pos]);


% --- Executes on button press in y_pos_plus.
function y_pos_plus_Callback(hObject, eventdata, handles)
% increment the y_pos, wrap around if too big
temp_pos = handles.PC.y_pos + 1;
if (temp_pos > handles.PC.pattern_y_size(handles.PC.current_pattern))
    temp_pos = 1;
end
handles.PC.y_pos = temp_pos;
set(handles.y_pos_val, 'string', num2str(temp_pos));
guidata(hObject, handles);
%send x and y pos out to controller
Panel_com('set_position', [handles.PC.x_pos, handles.PC.y_pos]);


% --- Executes on button press in y_pos_minus.
function y_pos_minus_Callback(hObject, eventdata, handles)
% decrement the y_pos, wrap around if hits zero
temp_pos = handles.PC.y_pos - 1;
if (temp_pos <= 0) 
    temp_pos = handles.PC.pattern_y_size(handles.PC.current_pattern);
end
handles.PC.y_pos = temp_pos;
set(handles.y_pos_val, 'string', num2str(temp_pos));
guidata(hObject, handles);
%send x and y pos out to controller
Panel_com('set_position', [handles.PC.x_pos, handles.PC.y_pos]);


% --------------------------------------------------------------------
function menu_commands_Callback(hObject, eventdata, handles)
% do nothing, this is just the first level menu callback.


% --------------------------------------------------------------------
function menu_reset_Callback(hObject, eventdata, handles)
% open up a dialog box to get the address of the panel to reset
prompt = {'Which panel to reset (0 for all) ?'};
dlg_title = 'Panel Reset';
num_lines= 1;
def     = {'0'};
answer  = inputdlg(prompt,dlg_title,num_lines,def);
% do some error checking
num_answer = str2double(answer);  
if ( ~isnan(num_answer) && (num_answer == round(num_answer)) )
    Panel_com('reset' , [num_answer]);  % call reset if OK
else    %otherwise, error and do nothing
    errordlg('Panel address must be an integer - no action taken','Bad Input','modal')
end
    

% --------------------------------------------------------------------
function menu_address_Callback(hObject, eventdata, handles)
% open up a dialog box to get the address of the panel to reset
prompt = {'current panel address', 'New panel address'};
dlg_title = 'Change Panel Address';
num_lines= 1;
def     = {'0', '0'};
answer  = inputdlg(prompt,dlg_title,num_lines,def);
% do some error checking
num_answer = str2double(answer); 
% here in 'if' use '&' for elementwise ANDing
if ( ~isnan(num_answer) & (num_answer == round(num_answer)) )
    Panel_com('address' , [num_answer]);  % call reset if OK
    update_status_display(handles, ['Panel address ' num2str(num_answer(1)) ' changed to ' num2str(num_answer(2))]);
else    %otherwise, error and do nothing
    errordlg('The panel addresses must be an integers - no action taken','Bad Input','modal')
end

% --------------------------------------------------------------------
function menu_all_off_Callback(hObject, eventdata, handles)
Panel_com('all_off'); 

% --------------------------------------------------------------------
function menu_all_on_Callback(hObject, eventdata, handles)
Panel_com('all_on'); 

% --------------------------------------------------------------------
function menu_g_levels_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function menu_g_0_Callback(hObject, eventdata, handles)
Panel_com('g_level_0');

% --------------------------------------------------------------------
function menu_g_1_Callback(hObject, eventdata, handles)
Panel_com('g_level_1');

% --------------------------------------------------------------------
function menu_g_2_Callback(hObject, eventdata, handles)
Panel_com('g_level_2');

% --------------------------------------------------------------------
function menu_g_3_Callback(hObject, eventdata, handles)
Panel_com('g_level_3');

% --------------------------------------------------------------------
function menu_g_4_Callback(hObject, eventdata, handles)
Panel_com('g_level_4');

% --------------------------------------------------------------------
function menu_g_5_Callback(hObject, eventdata, handles)
Panel_com('g_level_5');

% --------------------------------------------------------------------
function menu_g_6_Callback(hObject, eventdata, handles)
Panel_com('g_level_6');

% --------------------------------------------------------------------
function menu_g_7_Callback(hObject, eventdata, handles)
Panel_com('g_level_7');


% --------------------------------------------------------------------
function menu_patterns_Callback(hObject, eventdata, handles)
% do nothing, this is just the first level menu callback.

% --- Executes on button press in Start_button.
function Start_button_Callback(hObject, eventdata, handles)
if (handles.Running == 0)   %if not currently running
    Panel_com('start');     %send start command to the controller
    handles.Running = 1;    % set running flag to 1
    set(hObject, 'string', 'STOP');         % make button say STOP
    set(hObject, 'backgroundcolor', [0.9 0 0]);
else
    Panel_com('stop');     %send stop command to the controller
    handles.Running = 0;    % set running flag to off
    set(hObject, 'string', 'START');    % turn button to START
    set(hObject, 'backgroundcolor', [0 0.5 0]);
end
guidata(hObject, handles);


% --------------------------------------------------------------------
function menu_play_pattern_Callback(hObject, eventdata, handles)
% launch the GUI for playing the patterns
Pattern_Player;


% --------------------------------------------------------------------
function menu_functions_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function menu_function_X_Callback(hObject, eventdata, handles)
send_function('x')

% --------------------------------------------------------------------
function menu_function_Y_Callback(hObject, eventdata, handles)
send_function('y')

% --------------------------------------------------------------------
function menu_load_CF_Callback(hObject, eventdata, handles)
choose_pats;

% --- Executes during object creation, after setting all properties.
function x_loop_menu_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in x_loop_menu.
function x_loop_menu_Callback(hObject, eventdata, handles)
% mode value is the menu index minus 1, so 0, 1, or 2
handles.PC.x_mode = get(hObject,'Value') - 1 ;  
guidata(hObject, handles);
Panel_com('set_mode', [handles.PC.x_mode handles.PC.y_mode]);


% --- Executes during object creation, after setting all properties.
function y_loop_menu_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in y_loop_menu.
function y_loop_menu_Callback(hObject, eventdata, handles)
% mode value is the menu index minus 1, so 0, 1, or 2
handles.PC.y_mode = get(hObject,'Value') - 1;  
guidata(hObject, handles);
Panel_com('set_mode', [handles.PC.x_mode handles.PC.y_mode]);


% --------------------------------------------------------------------
function menu_exit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figure1_CloseRequestFcn(gcf, eventdata, handles);


% --------------------------------------------------------------------
function update_gui_Callback(hObject, eventdata, handles)
% resets the GUI, currently all this does is rerun the GUI init functiom

handles.PC = PControl_init;
guidata(hObject, handles);
update_status_display(handles, 'GUI info has been updated');


function update_status_display(handles, new_string)
% this function updates the status display box at the bottom of the GUI

buffer_length = 12;   % number of lines of text
max_string_length = 100;   % max length for each string

cut_length = min(length(new_string), max_string_length);

temp_cell_array = get(handles.status_display, 'String');
temp_cell_array{end+1} = [' > ' new_string(1:cut_length)];
if (length(temp_cell_array) > buffer_length)
    set(handles.status_display, 'String', temp_cell_array(2:end));
else
    set(handles.status_display, 'String', temp_cell_array);
end

function Update_current_patterns(handles, Pattern_ID)
% update the current pattern
% pattern_ID should be an integer 1-10
handles.PC.current_pattern = Pattern_ID;
handles.PC.y_pos = 1;
handles.PC.x_pos = 1;
set(handles.x_pos_val, 'string', 1);
set(handles.y_pos_val, 'string', 1);
guidata(gcf, handles);
update_status_display(handles, ['Pattern ' num2str(Pattern_ID) ' is the current pattern']);

function Send_Gain_Bias(handles)
% this function sends out the new gain and bias values to the controller
gain_x = round(100*handles.PC.x_gain_val/(handles.PC.x_gain_max));
gain_y = round(100*handles.PC.y_gain_val/(handles.PC.y_gain_max));
bias_x = round(100*handles.PC.x_offset_val/(handles.PC.x_offset_max));
bias_y = round(100*handles.PC.y_offset_val/(handles.PC.y_offset_max));
Panel_com('send_gain_bias', [gain_x, bias_x, gain_y, bias_y]);
update_status_display(handles, ['Sending: gain_x = ' num2str(gain_x) ', bias_x = ' num2str(bias_x) ...
    ', gain_y = ' num2str(gain_y) ', bias_y = ' num2str(bias_y)]);


% --------------------------------------------------------------------
function menu_reset_ctrl_Callback(hObject, eventdata, handles)
% resets the controller CPU (and eventually the CF controller also
Panel_com('ctr_reset');

  
% --------------------------------------------------------------------
function menu_LED_blink_Callback(hObject, eventdata, handles)
% % toggles controller LED - as a check that controller is responsive
Panel_com('led_tog');


% --------------------------------------------------------------------
function menu_set_Pat_ID_Callback(hObject, eventdata, handles)
% open up a dialog box to get the pattern number
prompt = {'Enter a pattern index'};
dlg_title = 'set pattern ID';
num_lines= 1; def     = {'1'};
answer  = inputdlg(prompt,dlg_title,num_lines,def);
% do some error checking
num_answer = str2double(answer);  
if ( ~isnan(num_answer) && (num_answer == round(num_answer)) && (num_answer > 0) && (num_answer <= handles.PC.num_patterns) )
% if ( ~isnan(num_answer) && (num_answer == round(num_answer)) && (num_answer > 0)) %&& (num_answer <= handles.PC.num_patterns) )
    Panel_com('set_pattern_id', [num_answer]);  % call reset if OK
    Update_current_patterns(handles, num_answer)
else    %otherwise, error and do nothing
    errordlg(['Pattern ID must be a positive integer, not greater than ' num2str(handles.PC.num_patterns) ' -- no action taken'],'Bad Input','modal')
end



% --------------------------------------------------------------------
function menu_test_adc_Callback(hObject, eventdata, handles)
% open up a dialog box to get the channel number
prompt = {'Enter the ADC channel to test, from 0 to 7'};
dlg_title = 'test ADC';
num_lines= 1; def     = {'0'};
answer  = inputdlg(prompt,dlg_title,num_lines,def);
% do some error checking
num_answer = str2double(answer);  
if ( ~isnan(num_answer) && (num_answer == round(num_answer)) && (num_answer >= 0) && (num_answer <= 7) )
    Panel_com('adc_test', [num_answer]);  
    helpdlg(['Please connect DAC1 to ADC channel ' num2str(num_answer) ', and connect DAC2 to a scope. You should see a 0 - 4 Volt triangle wave for about 20 seconds.']);
else    %otherwise, error and do nothing
    errordlg('ADC channel to test must be a positive integer from 0 to 7 -- no action taken','Bad Input','modal')
end

% --------------------------------------------------------------------
function menu_test_DIO_Callback(hObject, eventdata, handles)
% open up a dialog box to get the channel number
prompt = {'Enter the ADC channel to test, from 0 to 7'};
dlg_title = 'test ADC and DIO';
num_lines= 1; def     = {'0'};
answer  = inputdlg(prompt,dlg_title,num_lines,def);
% do some error checking
num_answer = str2double(answer);  
if ( ~isnan(num_answer) && (num_answer == round(num_answer)) && (num_answer >= 0) && (num_answer <= 7) )
    Panel_com('dio_test', [num_answer]);  
    helpdlg(['Please connect any of INT1-4 to ADC channel ' num2str(num_answer) ', and connect DAC2 to a scope. You should see a square wave for about 20 seconds.']);
else    %otherwise, error and do nothing
    errordlg('ADC channel to test must be a positive integer from 0 to 7 -- no action taken','Bad Input','modal')
end




% --------------------------------------------------------------------
function bench_pattern_Callback(hObject, eventdata, handles)
helpdlg(['To see the results of this benchmark, you need to have a serial connection between the RS-232 CoProcessor Port and a terminal program on this PC']);
Panel_com('bench_pattern');


% --------------------------------------------------------------------
function menu_pos_func_X_Callback(hObject, eventdata, handles)
send_position_function('x');

% --------------------------------------------------------------------
function menu_pos_func_Y_Callback(hObject, eventdata, handles)
send_position_function('y');



% --------------------------------------------------------------------
function menu_v_mode_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function menu_p_mode_Callback(hObject, eventdata, handles)
