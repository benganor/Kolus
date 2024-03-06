function generate_options_figure_vsr(handles, pp)
tag = guidata(handles.f_main);

optionshandles.f_options = figure( 'color','w', 'Visible', 'off', 'Toolbar', 'figure',  'WindowStyle', 'normal', 'Position', [50   0    1200   750], 'name', 'options');
optionshandles.stim_full = axes( 'Position',[0.5    0.1    0.45    0.9] ,  'TickLength',[ 0 0 ],  'color','none');

optionshandles.Duration_text = uicontrol('Style','edit',  'tag', 'Duration',  ...
             'String',num2str(tag.Duration),'Units' , 'Normalized' , 'backgroundcolor', 'w', 'Position',[.3,.3,.1,0.05], 'fontsize', 12);
uicontrol('Style','text', 'String','Record Time:', ...
'Units' , 'Normalized' , 'backgroundcolor', 'w', 'Position',[.24,.27,.05,0.09], 'fontsize', 12);
uicontrol('Style','text', 'String','Notes:', ...
'Units' , 'Normalized' , 'backgroundcolor', 'w', 'Position',[0,.27,.05,0.09], 'fontsize', 12);
optionshandles.Notes_text = uicontrol('Style','edit',  'tag', 'Notes',  ...
            'String','','Units' , 'Normalized' , 'backgroundcolor', 'w', 'Position',[.05,.3,.15,0.1], 'fontsize', 12);

optionshandles.replay = uicontrol('Style','pushbutton','Callback', {@replaybutton_Callback, handles, pp}, ...
             'String','Replay','Units' , 'Normalized' , 'BackgroundColor', 'm', 'Position',[0, 0.2,0.3,0.05], 'fontsize', 16);
optionshandles.generatestim = uicontrol('Style','pushbutton','Callback', {@generatestim_Callback, optionshandles, handles}, ...
             'String','Generate Stimulus','Units' , 'Normalized' , 'BackgroundColor', 'c', 'Position',[0,.45,0.3,0.05], 'fontsize', 16);
optionshandles.saveoptions = uicontrol('Style','pushbutton','Callback', {@saveoptions_Callback, optionshandles, handles}, ...
             'String','Confirm Options','Units' , 'Normalized' , 'BackgroundColor', [0.9294    0.6941    0.1255], 'Position',[0,0,1,0.05], 'fontsize', 16);


set(optionshandles.f_options, 'visible', 'on');

function saveoptions_Callback(~,~, optionshandles, handles)

    tag = guidata(handles.f_main);
    tag.Duration = str2double(get(optionshandles.Duration_text, 'string'));
    tag.Notes = get(optionshandles.Notes_text, 'string');
    guidata(handles.f_main, tag);
    close(optionshandles.f_options)
    figure(handles.f_main)

function generatestim_Callback(~,~, optionshandles, handles)

tag = guidata(handles.f_main);
output_stims = kolus_gen_stim(tag);
stim_t = linspace(1/tag.fs, length(output_stims)/tag.fs, length(output_stims));

set(optionshandles.f_options ,'CurrentAxes',optionshandles.stim_full)
plot(stim_t, output_stims);
xlim([0 length(output_stims)/tag.fs])

function replaybutton_Callback(~,~, handles, pp)
    kolus_button_replay(handles, pp)
