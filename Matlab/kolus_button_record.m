function kolus_button_record(handles, pp)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------- INITIALIZE STIMULI / FILE--------------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global DAQ_buffer S
tag = guidata(handles.f_main);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%    UPDATE VARIABLES     %%%%%%%%%%%%%%%%%%%%%%%%%%
if tag.enablestim
    tag.param_stim.Freq = sscanf(get(handles.stim_freq, 'String'), '%f:%f');
    tag.param_stim.Power = str2double(get(handles.stim_power, 'String'));
    tag.param_stim.Duration = str2double(get(handles.stim_duration, 'String'));
    tag.param_stim.Duration_pulse = str2double(get(handles.stim_pulsedur, 'String')) * 1e-3;
    tag.param_stim.Count = str2double(get(handles.stim_count, 'String'));
end

%%%%%%%%%%%%%%%%    ESTABLISH VARIABLES / PREALLOCATE     %%%%%%%%%%%%%%%%%
p_length = length(pp.res_freq(1):pp.res_freq(2):pp.res_freq(3));
p_start = 1;
ts_start = 1;
d_start = ones(1, sum(pp.digCh));
d_count = 1;
ylim_sound = [];


scans = 0;  %to ensure new scans have been received
%Pre-allocate data buffer the size of the display window - can be larger!
DAQ_buffer.Buffer = nan(pp.win_disp*sum(tag.refresh_time*tag.Rates), 1);
for i = 1:length(tag.Rates)
    p_skip(i) = tag.refresh_time*tag.Rates(i);
end
times_vec = cell(1, length(p_skip));
DAQ_buffer.Index = 1;
%buffer variable for scans: every scan is ~1 ms, 122 frequency bins
%each spectrogram on a chunk reduces window by 4ms due to overlap
 tag.Rates(2) =2500;
p_restart = (ceil(tag.refresh_time / pp.spec_time) - 4) * ...
    ceil(pp.win_disp / tag.refresh_time);
ts_restart = pp.win_disp * tag.Rates(2);
d_restart = pp.win_disp * tag.Rates(2);
d_restart = repmat(d_restart, 1, sum(pp.digCh));
p_spect = nan(p_length, p_restart);
p_timesrs = nan(1, pp.win_disp*tag.Rates(2)); %disable when not in use
%%%%%%%%%%%FIX
for i = 1:sum(pp.digCh)
p_dig{i} = nan(1, pp.win_disp*tag.Rates(2)); %%%FIX ME - d
end
%%%%%%%%%%%FIX
tag.Block = str2double(get(handles.block_text, 'String'));

% set(handles.f_main ,'CurrentAxes',handles.S(2))
stim_train = kolus_gen_stim(tag);
disp(['Session: ' num2str(tag.Block) '  Length: ' num2str(length(stim_train)/tag.fs)]);
if tag.enablestim
    k_viewstim(handles, stim_train(:,1), tag);
end

for i = 1:size(stim_train, 2)
tag.stim{i} = sig2stim(stim_train(:,i), tag.fs, 0.5);
end



tag.Duration = length(stim_train)/tag.fs;
tag.Fid = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------- QUEUE DATA AND RUN --------------------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DAQ_cleanup(S, tag) %IMPORTANT all recording AFTER this LINE
dos(strcat('"' , tag.dir_ispy , '"', ' commands "record"'));%slow ispy
queueOutputData(S.Daq, stim_train);
S.Daq.NotifyWhenDataAvailableExceeds = tag.fs*tag.refresh_time;  %notify at data points
S.Daq.prepare;
DAQ_buffer.Time = now; %pre-allocate
tag.start = datevec(DAQ_buffer.Time);
tag.file_mat  = ['VSR_' tag.Experiment '_' datestr(DAQ_buffer.Time, 'YYmmDD_HHMMSS_') ...
    num2str(tag.Block) '.mat'];
tag.file_dat = strrep(tag.file_mat,'.mat','.dat');
save(tag.file_mat, 'tag', '-v7.3', '-nocompression');

DAQ_buffer.Fid = fopen(tag.file_dat, 'Wb'); %buffered writing is faster with W
tag.Fid = DAQ_buffer.Fid;
% Start in Data Acquisition in background - pause for safety

S.Daq.startBackground;

while S.Daq.IsRunning || (scans <  tag.fs*tag.refresh_time)
    try %if plotting errors, will still close file / save meta data
        scans_total = single(S.Daq.ScansAcquired);
        if scans_total == scans; pause(tag.refresh_time/10); continue; end
        scans_new = scans_total- scans;
        scans = scans_total;

       times_vec_plot = scans2times(p_skip, scans_new, times_vec);

        for ii = 1:pp.large_axis
            pp.ylims(ii, :) = [str2double(get(handles.y_text_low(ii), 'String')) ...
                str2double(get(handles.y_text_high(ii), 'String')) ];
        end


        for i = 1:length(handles.S)
             set(handles.f_main ,'CurrentAxes',handles.S(i))
            switch pp.daq_plot{i}{2}
                case 'sound'
                     t_spec = ((scans/tag.fs) - pp.win_disp):(1/tag.fs): ...
                         ((scans/tag.fs) + pp.win_disp);
                        [~, F, P] = spgrambw(DAQ_buffer.Buffer(times_vec_plot{i}),...
                        tag.fs,'h',pp.res_time, pp.res_freq, ...
                        pp.spec_threshold ,'Jp' );
                    P = 10*log10(abs(P))';
                    p_end = (p_start-1) + size(P, 2);
                    p_spect(:, p_start:p_end) = P;
                    imagesc(t_spec, F, p_spect)
                    L = get(gca,'XLim');
                    set(gca, 'YDir','normal',   'TickLength',[ 0 0 ], ...
                        'fontsize',15, 'XTick',linspace(L(1),L(2),3), ...
                        'Ylim', pp.ylims(i, :)*1e3)
                    caxis([-90 -10])
                     p_start = p_end + 1;
                    if p_end >= p_restart
                        p_start = 1;
                    end

                case 'time series'
                    t_timesrs = linspace((scans/tag.fs) - pp.win_disp ,...
                        (scans/tag.fs) + pp.win_disp, length(p_timesrs));
                    chunk_length = length(times_vec_plot{i});
                    ts_end = chunk_length + (ts_start-1);
                    p_timesrs(ts_start:ts_end) = DAQ_buffer.Buffer(times_vec_plot{i});
                    plot(t_timesrs(1:1:end), p_timesrs(1:1:end))
                    set(gca,  'TickLength',[ 0 0 ],  'color','none', ...
                        'Xlim', [t_timesrs(1) t_timesrs(end)], 'xcolor', 'w', ...
                        'box', 'off' ,'xtick', [], 'ytick', [])
                    set(gca, 'Ylim', pp.ylims(i, :));
                    ts_start = ts_end + 1;
                    if ts_start >= ts_restart
                        ts_start = 1;
                        p_start = 1;
                    end
                case 'digital'
                    t_dig = linspace((scans/tag.fs) - pp.win_disp ,...
                        (scans/tag.fs) + pp.win_disp, length(p_dig{d_count}));
                    chunk_length = length(times_vec_plot{i});
                    d_end(d_count) = chunk_length + (d_start(d_count)-1);
                    p_dig{d_count}(d_start(d_count):d_end(d_count)) = DAQ_buffer.Buffer(times_vec_plot{i});
                    plot(t_dig, p_dig{d_count},pp.digCh_color{d_count}, 'linewidth', 4)
                    set(gca,  'TickLength',[ 0 0 ],  'color','none', ...
                        'Xlim', [t_dig(1) t_dig(end)], 'xcolor', 'w', ...
                        'box', 'off' ,'xtick', [], 'ytick', []);
                    set(gca, 'Ylim', [0 .2]);
                    d_start(d_count) = d_end(d_count) + 1;
                    if d_start(d_count) >= d_restart(d_count)
                        d_start(d_count) = 1;
                    end
                    d_count = 1 + d_count;
            end
        end
        DAQ_buffer.Index = 1;
        d_count = 1;

    catch err %enable for error checking
%         DAQ_cleanup(S, tag)
%         if strcmp(err.identifier, 'MATLAB:hg:dt_conv:Matrix_to_HObject:BadHandle')
%             break;
%         end
%         rethrow(err);
    end
end

tag.end = datevec(DAQ_buffer.Time);  %saving the final time of the trial
tag.Duration = double(S.Daq.ScansAcquired) / tag.fs;
DAQ_cleanup(S, tag)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------- UPDATE PARAMETERS / SAVE or DELETE FILE----------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% saving the file and moving to the next file name
tag_temp = guidata(handles.f_main);
if tag_temp.record %first option normal end, second is stop/save
    tag = rmfield(tag, {'Fid', 'dir_ispy', 'record'});
    tag.Notes = tag_temp.Notes;
    save(tag.file_mat, 'tag', '-v7.3', '-nocompression'); %save again if notes added and correct Duration
%     tag2xls(tag, tag.xls);
    tag.Block = tag.Block + 1;
        set(handles.block_text, 'String', num2str(tag.Block));
else
    delete(tag.file_mat)
    delete(tag.file_dat)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------------- VOCALIZATION CHECK --------------------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% kolus_voccheck

function DAQ_cleanup(S, tag)
%make sure DAQ is stopped and CLEAR to prevent errors
%handles file opening/closing and video start/end
S.Daq.stop

%CLOSE FILE
if ~isempty(tag.Fid)
    fclose(tag.Fid);
end

%CLEAR DAQ CHANNELS
S.Daq.IsContinuous = false;
tag.Fid = [];
pause(.01)
queueOutputData(S.Daq, zeros(1, sum(tag.type_Ch==0)) );  %clears multi channel
S.Daq.startBackground; S.Daq.stop
pause(1)

%TURN OFF CAMERA
dos(strcat('"' , tag.dir_ispy , '"', ' commands "recordstop"'));



function times_vec = scans2times(p_skip, scans_added, times_vec)
starts= [];
ends = [];
for i = 0:(scans_added / max(p_skip)) - 1
    starts = [starts [1 1+cumsum(p_skip(1:end-1))] + (sum(p_skip) * i)];
    ends = [ends cumsum(p_skip)+ (sum(p_skip)* i)];
end

for i = 1:length(p_skip)
    for ii = i:length(p_skip):length(starts)
        times_vec{i} = [times_vec{i} starts(ii):ends(ii)];
    end
end


function k_viewstim(handles, stimulus, tag)

set(handles.f_main ,'CurrentAxes',handles.S(1))
cla(handles.S(1))

stimulus_dur = length(stimulus)/tag.fs;
stimulus_diff = find(diff(stimulus));
stim_pairs = reshape(stimulus_diff, 2, length(stimulus_diff)/2)' / tag.fs;

if ~(length(stim_pairs > 200))
    for i = 1:size(stim_pairs, 1)
        patch([stim_pairs(i, 1) stim_pairs(i, 2) ...
            stim_pairs(i, 2) stim_pairs(i, 1)], [-1 -1 1 1], 'k');
    end
else 
   stimulus(stimulus>1) = 1;
   t_stim = linspace(1/tag.fs, length(stimulus)/tag.fs, length(stimulus(1:100:end)));
   plot(t_stim, stimulus(1:100:end))
end

if ~sum(stimulus)==0 %dont need x/y limits if no stimulus
xlim([0 stimulus_dur])
ylim([min(stimulus) max(stimulus)])
end

