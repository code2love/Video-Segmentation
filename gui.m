function varargout = gui(varargin)
% GUI MATLAB code for gui.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui

% Last Modified by GUIDE v2.5 01-Mar-2021 20:52:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui (see VARARGIN)

% Choose default command line output for gui
handles.output = hObject;

% Initialize GUI variables
handles.imreader = 0;
handles.image_left = uint8(zeros(600, 800, 3));
handles.image_right = uint8(zeros(600, 800, 3));
handles.image_background = uint8(zeros(600, 800, 3));
handles.timer_playback = timer;
handles.timer_playback.Period = 0.033;
handles.timer_playback.ExecutionMode = 'fixedSpacing';
handles.timer_playback.TimerFcn = @(~,~) timer_playback_callback(hObject);

% Install event listeners
addlistener(handles.text_directory, ...
            'String', ...
            'PostSet', ...
            @(hObj, evnt) execute_callbacks( ...
                { ...
                    @imagereader_init, ...
                    @update_images, ...
                    @draw_images ...
                }, ...
                hObject ...
            ) ...
);
addlistener(handles.text_start, ...
            'String', ...
            'PostSet', ...
            @(hObj, evnt) execute_callbacks( ...
                { ...
                    @sanitize_text_start, ...
                    @imagereader_init, ...
                    @update_images, ...
                    @draw_images ...
                }, ...
                hObject ...
            ) ...
);
addlistener(handles.text_n, ...
            'String', ...
            'PostSet', ...
            @(hObj, evnt) execute_callbacks( ...
                { ...
                    @sanitize_text_lag, ...
                    @imagereader_init, ...
                    @update_images, ...
                    @draw_images ...
                }, ...
                hObject ...
            ) ...
);
addlistener(handles.text_lag, ...
            'String', ...
            'PostSet', ...
            @(hObj, evnt) execute_callbacks( ...
                { ...
                    @sanitize_text_lag, ...
                    @update_images, ...
                    @draw_images ...
                }, ...
                hObject ...
            ) ...
);
addlistener(handles.popup_channel_left, ...
            'Value', ...
            'PostSet', ...
            @(hObj, evnt) execute_callbacks( ...
                { ...
                    @sanitize_popup_channel_left, ...
                    @imagereader_init, ...
                    @update_images, ...
                    @draw_images ...
                }, ...
                hObject ...
            ) ...
);
addlistener(handles.popup_channel_right, ...
            'Value', ...
            'PostSet', ...
            @(hObj, evnt) execute_callbacks( ...
                { ...
                    @sanitize_popup_channel_right, ...
                    @imagereader_init, ...
                    @update_images, ...
                    @draw_images ...
                }, ...
                hObject ...
            ) ...
);
addlistener(handles.text_background, ...
            'String', ...
            'PostSet', ...
            @(hObj, evnt) execute_callbacks( ...
                { ...
                    @draw_images, ...
                }, ...
                hObject ...
            ) ...
);
addlistener(handles.popup_mode, ...
            'Value', ...
            'PostSet', ...
            @(hObj, evnt) execute_callbacks( ...
                { ...
                    @sanitize_popup_mode ...
                    @draw_images, ...
                }, ...
                hObject ...
            ) ...
);
addlistener(handles.popup_channel_out, ...
            'Value', ...
            'PostSet', ...
            @(hObj, evnt) execute_callbacks( ...
                { ...
                    @draw_images, ...
                }, ...
                hObject ...
            ) ...
);

% Update handles structure
guidata(hObject, handles);

% Initialize figures
draw_images(hObject);

% UIWAIT makes gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Executes callbacks.
function execute_callbacks(callback_arr, figure)
% Helper function to guarantee execution order of callbacks.
% callback_arr    Array containing callback functions
% figure          Parent figure (gets passed to callbacks)
for i = 1:numel(callback_arr)
    cbfn = cell2mat(callback_arr(i));
    ret = cbfn(figure);
    if ~ret
        % Stop further callback execution if a callback returns false
        break;
    end
end


function ret = sanitize_text_lag(figure)
fprintf('sanitize_text_lag\n')
handles = guidata(figure);

% Read in tensor size
n_tensor = str2double(get(handles.text_n,'String'));
% Read in current lag
lag = str2double(get(handles.text_lag,'String'));

if lag < 0 || lag > n_tensor
    set(handles.text_lag, 'String', n_tensor);
    guidata(figure, handles);
end

ret = true;

% --- Sanitizes popup_channel_right input.
function ret = sanitize_popup_channel_right(figure)
fprintf('sanitize_popup_channel_right\n')
handles = guidata(figure);

% Read left channel selection
contents = cellstr(get(handles.popup_channel_left,'String'));
L = str2double(contents{get(handles.popup_channel_left,'Value')});

% Read right channel selection
contents = cellstr(get(handles.popup_channel_right,'String'));
R = str2double(contents{get(handles.popup_channel_right,'Value')});

if R == L
    msgbox('Linker und rechter Kanal müssen sich unterscheiden!');    
    set(handles.popup_channel_right, 'Value', 2);
    guidata(figure, handles);
end

ret = true;


% --- Sanitizes popup_channel_left input.
function ret = sanitize_popup_channel_left(figure)
fprintf('sanitize_popup_channel_left\n')
handles = guidata(figure);

% Read left channel selection
contents = cellstr(get(handles.popup_channel_left,'String'));
L = str2double(contents{get(handles.popup_channel_left,'Value')});

% Read right channel selection
contents = cellstr(get(handles.popup_channel_right,'String'));
R = str2double(contents{get(handles.popup_channel_right,'Value')});

if R == L
    msgbox('Linker und rechter Kanal müssen sich unterscheiden!');    
    set(handles.popup_channel_left, 'Value', 1);
    guidata(figure, handles);
end

ret = true;


% --- Sanitizes text_start input.
function ret = sanitize_text_start(figure)
fprintf('sanitize_text_start\n')
handles = guidata(figure);

% Read in start number
number = str2double(get(handles.text_start,'String'));
if isnan(number) || number < 1
    % Sanitize invalid values
    number = 1;
end

% Convert value to integer and update daata
set(handles.text_start, 'String', sprintf("%d", int32(number)))
guidata(figure, handles);
ret = true;


% --- Sanitizes popup_mode input.
function ret = sanitize_popup_mode(figure)
fprintf('sanitize_popup_mode\n')
handles = guidata(figure);

% Read selected rendermode
contents = cellstr(get(handles.popup_mode,'String'));
selected = contents{get(handles.popup_mode,'Value')};

% Check if valid option
if strcmp(selected, 'substitute') && strlength(get(handles.text_background, 'String')) == 0
    msgbox('Kein Hintergrundbild ausgewÃ¤hlt!');
    
    % Reset selected value and update data
    set(handles.popup_mode, 'Value', 1);
    guidata(figure, handles);
end
ret = true;


% --- Initializes imagereader property.
function ret = imagereader_init(figure)
fprintf('imagereader_init_callback\n')
handles = guidata(figure);

% Read left channel selection
contents = cellstr(get(handles.popup_channel_left,'String'));
L = str2double(contents{get(handles.popup_channel_left,'Value')});

% Read right channel selection
contents = cellstr(get(handles.popup_channel_right,'String'));
R = str2double(contents{get(handles.popup_channel_right,'Value')});

% Read other parameters for ImageReader
N = str2double(get(handles.text_n,'String'));
start = str2double(get(handles.text_start,'String'));
src = get(handles.text_directory,'String');

% Initialize ImageReader
handles.imreader = ImageReader(src, L, R, start, N);

% Enable Controls
set(handles.text_start, 'Enable', 'on');
set(handles.button_start_inc, 'Enable', 'on');
set(handles.button_start_decr, 'Enable', 'on');
set(handles.button_n_inc, 'Enable', 'on');
set(handles.button_n_decr, 'Enable', 'on');
set(handles.button_lag_inc, 'Enable', 'on');
set(handles.button_lag_decr, 'Enable', 'on');
set(handles.popup_channel_left, 'Enable', 'on');
set(handles.popup_channel_right, 'Enable', 'on');
set(handles.popup_channel_out, 'Enable', 'on');
set(handles.button_save, 'Enable', 'on');

% Update data
guidata(figure, handles);
ret = true;


% --- Draws left, right and output image.
function ret = draw_images(figure)
fprintf('draw_images\n')
handles = guidata(figure);

% Read in lag value
lag = str2double(get(handles.text_lag,'String'));
tensor_idx = (1:3) + (lag*3);

% Show left and right input channel
imshow(handles.image_left(:, :, tensor_idx), 'Parent', handles.axes_input_left);
imshow(handles.image_right(:, :, tensor_idx), 'Parent', handles.axes_input_right);

% Read output channel selection
outputchannel = get(handles.popup_channel_out,'Value');

% Calculate mask
mask = segmentation(handles.image_left, handles.image_right, outputchannel);

% Read rendermode selection
contents = cellstr(get(handles.popup_mode,'String'));
rendermode = contents{get(handles.popup_mode,'Value')};

% Render and show output image
tensor_sel = 0;
if outputchannel == 1
    tensor_sel = handles.image_left;
else
    tensor_sel = handles.image_right;
end
image_output = render(tensor_sel(:, :, tensor_idx), mask, handles.image_background, rendermode);
imshow(image_output, 'Parent', handles.axes_output);

% Update data
guidata(figure, handles);
ret = true;


% --- Updates properties image_left and image_right with next images.
function ret = update_images(figure)
fprintf('update_images\n')
handles = guidata(figure);

% Read next tensors from ImageReader
[tensor_left, tensor_right, ~] = handles.imreader.next();

% Store first images from tensors in buffer
handles.image_left = tensor_left;
handles.image_right = tensor_right;

% Update data
guidata(figure, handles);
ret = true;


% --- Function periodically called by timer_playback.
function timer_playback_callback(figure)
fprintf('timer_playback_callback\n')
handles = guidata(figure);

% Read next tensors from ImageReader
[tensor_left, tensor_right, loop] = handles.imreader.next();

% Store first images from tensors in buffer
handles.image_left = tensor_left;
handles.image_right = tensor_right;

% Check if end of sequence reached
if loop && ~get(handles.checkbox_loop, 'Value')
    stop(handles.timer_playback);
    
    % Reset controls
    set(handles.button_stop, 'Enable', 'off');
    set(handles.button_play, 'Enable', 'on');
    set(handles.text_start, 'Enable', 'on');
    set(handles.button_start_inc, 'Enable', 'on');
    set(handles.button_start_decr, 'Enable', 'on');
    set(handles.button_n_inc, 'Enable', 'on');
    set(handles.button_n_decr, 'Enable', 'on');
    set(handles.button_lag_inc, 'Enable', 'on');
    set(handles.button_lag_decr, 'Enable', 'on');
    set(handles.popup_channel_left, 'Enable', 'on');
    set(handles.popup_channel_right, 'Enable', 'on');
end

% Update data
guidata(figure, handles);

% Show buffered images and output image
draw_images(figure);


% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in button_change_directory.
function button_change_directory_Callback(hObject, eventdata, handles)
% hObject    handle to button_change_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
directory = uigetdir;
if directory ~= 0
    set(handles.text_directory, 'String', directory);
end


function text_directory_Callback(hObject, eventdata, handles)
% hObject    handle to text_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_directory as text
%        str2double(get(hObject,'String')) returns contents of text_directory as a double


% --- Executes during object creation, after setting all properties.
function text_directory_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_change_background.
function button_change_background_Callback(hObject, eventdata, handles)
% hObject    handle to button_change_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, path] = uigetfile({'*.jpg';'*.jpeg';'*.bmp';'*.*'}, 'Hintergrundbild auswÃ¤hlen');
if ~isscalar(file) && ~isscalar(path)
    filepath = append(path,file);
    set(handles.text_background, 'String', filepath);
    data = guidata(hObject);
    data.image_background = imread(filepath);
    guidata(hObject, data);
    draw_images(hObject);
end


function text_background_Callback(hObject, eventdata, handles)
% hObject    handle to text_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_background as text
%        str2double(get(hObject,'String')) returns contents of text_background as a double


% --- Executes during object creation, after setting all properties.
function text_background_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function text_start_Callback(hObject, eventdata, handles)
% hObject    handle to text_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_start as text
%        str2double(get(hObject,'String')) returns contents of text_start as a double


% --- Executes during object creation, after setting all properties.
function text_start_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_start_decr.
function button_start_decr_Callback(hObject, eventdata, handles)
% hObject    handle to button_start_decr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
number = str2double(get(handles.text_start,'String'));
if number > 1
    set(handles.text_start,'String', sprintf("%d", number - 1));
end


% --- Executes on button press in button_start_inc.
function button_start_inc_Callback(hObject, eventdata, handles)
% hObject    handle to button_start_inc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
number = str2double(get(handles.text_start,'String'));
set(handles.text_start,'String', sprintf("%d", number + 1));


% --- Executes on selection change in popup_mode.
function popup_mode_Callback(hObject, eventdata, handles)
% hObject    handle to popup_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_mode


% --- Executes during object creation, after setting all properties.
function popup_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_play.
function button_play_Callback(hObject, eventdata, handles)
% hObject    handle to button_play (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strlength(get(handles.text_directory, 'String')) == 0
    msgbox('Kein Szenenordner ausgewählt!');
else
    set(handles.button_play, 'Enable', 'off');
    set(handles.button_pause, 'Enable', 'on');
    set(handles.button_stop, 'Enable', 'on');
    set(handles.text_start, 'Enable', 'off');
    set(handles.button_start_inc, 'Enable', 'off');
    set(handles.button_start_decr, 'Enable', 'off');
    set(handles.button_n_inc, 'Enable', 'off');
    set(handles.button_n_decr, 'Enable', 'off');
    set(handles.button_lag_inc, 'Enable', 'off');
    set(handles.button_lag_decr, 'Enable', 'off');
    set(handles.popup_channel_left, 'Enable', 'off');
    set(handles.popup_channel_right, 'Enable', 'off');
    start(handles.timer_playback);
end


% --- Executes on button press in button_pause.
function button_pause_Callback(hObject, eventdata, handles)
% hObject    handle to button_pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop(handles.timer_playback);
set(handles.button_play, 'Enable', 'on');
set(handles.button_pause, 'Enable', 'off');


% --- Executes on button press in button_stop.
function button_stop_Callback(hObject, eventdata, handles)
% hObject    handle to button_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop(handles.timer_playback);
set(handles.button_play, 'Enable', 'on');
set(handles.button_pause, 'Enable', 'off');
set(handles.button_stop, 'Enable', 'off');
set(handles.text_start, 'Enable', 'on');
guidata(hObject,handles)
imagereader_init(hObject);
update_images(hObject);
draw_images(hObject);


% --- Executes on button press in checkbox_loop.
function checkbox_loop_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_loop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_loop


% --- Executes on button press in button_save.
function button_save_Callback(hObject, eventdata, handles)
% hObject    handle to button_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Select file path
[file,path] = uiputfile({'*.avi'}, 'Speicherort auswÃ¤hlen');

if ~isstr(file)
    return;
end

filepath = fullfile(path,file);

% Read left channel selection
contents = cellstr(get(handles.popup_channel_left,'String'));
L = str2double(contents{get(handles.popup_channel_left,'Value')});

% Read right channel selection
contents = cellstr(get(handles.popup_channel_right,'String'));
R = str2double(contents{get(handles.popup_channel_right,'Value')});

% Read other parameters for ImageReader
N = str2double(get(handles.text_n,'String'));
start = str2double(get(handles.text_start,'String'));
src = get(handles.text_directory,'String');

% Initialize ImageReader
imreader = ImageReader(src, L, R, start, N);

% Read rendermode selection
contents = cellstr(get(handles.popup_mode,'String'));
rendermode = contents{get(handles.popup_mode,'Value')};

% Read in lag value
lag = str2double(get(handles.text_lag,'String'));
tensor_idx = (1:3) + (lag*3);

prompt = {'Wie viele Folgebilder  sollen gerendert werden (-1 für alle) ?'};
dlgtitle = 'Anzahl Bilder';
definput = {'-1'};
n = inputdlg(prompt,dlgtitle,[1 40],definput);

if isempty(n)
    return;
end

set(handles.button_save, 'Enable', 'off');
set(handles.button_change_directory, 'Enable', 'off');

n = cell2mat(n);
n = str2double(n);

f = waitbar(0,'Rendere Video ...');
set(f,'WindowStyle','modal');

i = 1;

% Open videowriter
videoWriter = VideoWriter(filepath);
open(videoWriter);

while true
    
    if n ~= -1 && n < i
        break;
    end
    
    % Get next images
    [tensor_left, tensor_right, loop] = imreader.next();
    
    % Read output channel selection
    outputchannel = get(handles.popup_channel_out,'Value');
    
    % Calculate mask
    mask = segmentation(tensor_left, tensor_right, outputchannel);

    % Render output image
    tensor_sel = 0;
    if outputchannel == 1
        tensor_sel = tensor_left;
    else
        tensor_sel = tensor_right;
    end
    image_output = render(tensor_sel(:, :, tensor_idx), mask, handles.image_background, rendermode);
    
    % Save video
    writeVideo(videoWriter,image_output);  
    
    fprintf('Wrote frame: %d\n', i);
    progress = i/n;
    waitbar(max(progress, atan(i/100) / pi * 2),f,'Rendere Video ...');
    
    if loop == 1
        break;
    end
    
    i = i + 1;
end
  
% Close videowriter
close(videoWriter);

waitbar(1,f,'Rendern abgeschlossen');
pause(1)

set(handles.button_save, 'Enable', 'on');
set(handles.button_change_directory, 'Enable', 'on');


% --- Executes on selection change in popup_channel_left.
function popup_channel_left_Callback(hObject, eventdata, handles)
% hObject    handle to popup_channel_left (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_channel_left contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_channel_left


% --- Executes during object creation, after setting all properties.
function popup_channel_left_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_channel_left (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_channel_right.
function popup_channel_right_Callback(hObject, eventdata, handles)
% hObject    handle to popup_channel_right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_channel_right contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_channel_right


% --- Executes during object creation, after setting all properties.
function popup_channel_right_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_channel_right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_n_Callback(hObject, eventdata, handles)
% hObject    handle to text_n (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_n as text
%        str2double(get(hObject,'String')) returns contents of text_n as a double


% --- Executes during object creation, after setting all properties.
function text_n_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_n (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_n_decr.
function button_n_decr_Callback(hObject, eventdata, handles)
% hObject    handle to button_n_decr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
number = str2double(get(handles.text_n,'String'));
if number > 1
    set(handles.text_n,'String', sprintf("%d", number - 1));
end


% --- Executes on button press in button_n_inc.
function button_n_inc_Callback(hObject, eventdata, handles)
% hObject    handle to button_n_inc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
number = str2double(get(handles.text_n,'String'));
set(handles.text_n,'String', sprintf("%d", number + 1));


% --- Executes on selection change in popup_channel_out.
function popup_channel_out_Callback(hObject, eventdata, handles)
% hObject    handle to popup_channel_out (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_channel_out contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_channel_out


% --- Executes during object creation, after setting all properties.
function popup_channel_out_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_channel_out (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_lag_Callback(hObject, eventdata, handles)
% hObject    handle to text_lag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_lag as text
%        str2double(get(hObject,'String')) returns contents of text_lag as a double


% --- Executes during object creation, after setting all properties.
function text_lag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_lag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_lag_decr.
function button_lag_decr_Callback(hObject, eventdata, handles)
% hObject    handle to button_lag_decr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
number = str2double(get(handles.text_lag,'String'));
set(handles.text_lag,'String', sprintf("%d", number - 1));


% --- Executes on button press in button_lag_inc.
function button_lag_inc_Callback(hObject, eventdata, handles)
% hObject    handle to button_lag_inc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
number = str2double(get(handles.text_lag,'String'));
set(handles.text_lag,'String', sprintf("%d", number + 1));
