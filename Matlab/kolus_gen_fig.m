function kolus_gen_fig
% generate monitor figure - based on configuration file
K_config;

handles.f_main = figure( 'color','w', 'Visible', 'off', 'Toolbar', 'figure');

%%%%%%%%%%%%%%%%%%%% DETERMINE SIZES of EACH AXIS %%%%%%%%%%%%%%%%%%%%%%%%
all_heights = repmat(1/pp.large_axis, 1, pp.large_axis);
all_bottoms = fliplr(cumsum(all_heights)) - 1/pp.large_axis + 0.03;
all_heights(1) = all_heights(1) - .06; %for control buttons

%%%%%%%%%%%%%%%%%%%% Create Axis for each data input %%%%%%%%%%%%%%%%%%%%
for i = 1:length(pp.daq_plot)
    switch pp.daq_plot{i}{2}
        case 'sound'
            handles.S(i) = axes('Position', ...
                [0.015 all_bottoms(i) 0.96 all_heights(i)] , 'TickLength',[0 0], 'fontsize', 14);
        case 'time series'
            handles.S(i) = axes('Position', ...
                [0.015 all_bottoms(i) 0.96 all_heights(i)], 'TickLength',[0 0], 'color','none');
        case 'digital'
            handles.S(i) = axes('Position', ...
                [0.015    0.03    0.96    0.15], 'color','none', 'xtick',[], 'ytick', [], 'box', 'off', 'XColor', 'w');
    end
end

%%%%%%%%%%%%% Handles for Y limits of large axes   %%%%%%%%%%%%%%%%%%%%%
xy_bottoms = fliplr((1 - all_bottoms) / 2);
for i = 1:pp.large_axis
    handles.y_text_low(i) = uicontrol('Style','edit', ...
        'String',num2str(pp.ylims(i,1)),'Units' , 'Normalized' , 'backgroundcolor', ...
        'w', 'Position',[.98,xy_bottoms(i) + .06,.02,0.02], 'fontsize', 12);
    handles.y_text_high(i) = uicontrol('Style','edit', ...
        'String',num2str(pp.ylims(i,2)),'Units' , 'Normalized' , 'backgroundcolor', ...
        'w', 'Position',[.98,xy_bottoms(i) + .08,.02,0.02], 'fontsize', 12);
end

%%%%% Handles for stimuli parameters  %%%%%
if tag.enablestim
    handles.stim_power = uicontrol('Style','edit', ...
        'String',num2str(tag.param_stim.Power),'Units', 'Normalized' , 'backgroundcolor', 'w', 'Position',[.4,.98,.02,0.02], 'fontsize', 12);
    handles.stim_duration = uicontrol('Style','edit', ...
        'String',num2str(tag.param_stim.Duration),'Units' , 'Normalized' , 'backgroundcolor', 'w', 'Position',[.425,.98,.02,0.02], 'fontsize', 12);
    handles.stim_pulsedur = uicontrol('Style','edit', ...
        'String',num2str(tag.param_stim.Duration_pulse),'Units' , 'Normalized' , 'backgroundcolor', 'w', 'Position',[.45,.98,.02,0.02], 'fontsize', 12);
    handles.stim_count = uicontrol('Style','edit', 'String',   ...
        num2str(tag.param_stim.Count),'Units' , 'Normalized' , 'backgroundcolor', 'w', 'Position',[.61,.98,.02,0.02], 'fontsize', 12);
    if length(tag.param_stim.Freq) == 2
        handles.stim_freq = uicontrol('Style','edit', ...
            'String',[num2str(tag.param_stim.Freq(1)), ':' ,num2str(tag.param_stim.Freq(2))],'Units' , ...
            'Normalized' , 'backgroundcolor', 'w', 'Position',[.475,.98,.02,0.02], 'fontsize', 12);
    else
        handles.stim_freq = uicontrol('Style','edit', ...
            'String',num2str(tag.param_stim.Freq),'Units' , 'Normalized' , 'backgroundcolor', 'w', 'Position',[.475,.98,.02,0.02], 'fontsize', 12);
    end
end

%%%%% Handles for control buttons  %%%%%
handles.button_stop  = uicontrol('Style','pushbutton','Callback', {@stopbutton_Callback}, ...
    'String','Stop','Units' , 'Normalized' , 'BackgroundColor', 'r', 'Position',[.3,.98,.1,0.02]);
handles.button_stopsave = uicontrol('Style','pushbutton','Callback', {@stopsavebutton_Callback}, ...
    'String','Save/Stop','Units' , 'Normalized' , 'BackgroundColor', [0.5843 0.8157 0.9882], 'Position',[.5,.98,.1,0.02]);
handles.button_options = uicontrol('Style','pushbutton','Callback', {@options_Callback, handles, pp}, ...
    'String','Options','Units' , 'Normalized' , 'BackgroundColor', [0.9294    0.6941    0.1255], 'Position',[.8,.98,.1,0.02]);
handles.block_text = uicontrol('Style','edit', ...
    'String','1','Units' , 'Normalized' , 'backgroundcolor', 'w', 'Position',[.7,.98,.02,0.02], 'fontsize', 12);
uicontrol('Style','text', 'String','Block #:','Units' , 'Normalized' ...
, 'backgroundcolor', 'w', 'Position',[.67,.98,.03,0.02], 'fontsize', 12);

%important after all other handles - it sends handles to record function callback
handles.record_button = uicontrol('Style','pushbutton','Callback', ...
    {@recordbutton_Callback, handles, pp}, ...
    'String','Record','Units' , 'Normalized' , 'BackgroundColor', 'g', 'Position',[.1,.98,.1,0.02]);

%%%% Make figure visible and resize it %%%%%
set(handles.f_main, 'visible', 'on');
set(handles.f_main, 'Units', 'normalized', 'Position', pp.fig_position)


function recordbutton_Callback(src, ~, handles, pp)
%START acquisition - default to save

tag = guidata(src);
tag.record = true; %SAVE data
guidata(src, tag);

kolus_button_record(handles, pp)


function stopbutton_Callback(src,~)
%STOP acquisition and delete data
tag = guidata(src);
tag.record = false; %DELETE data
guidata(src, tag);

global S
S.Daq.stop % Terminates data acquisition and plot loop


function stopsavebutton_Callback(src,~)
%STOP acquisition and save data (default option)
global S
S.Daq.stop % Terminates data acquisition and plot loop

function options_Callback(~,~, handles, pp)
%OPEN options dialogue - not ideal to open during acquisition
kolus_button_options(handles, pp)
