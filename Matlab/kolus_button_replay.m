function replaybutton_record_neur_mic(handles)
tag = guidata(handles.f_main);
   [FileName,PathName,FilterIndex] = uigetfile('.mat','replay' ,tag.folder);
    load([PathName FileName]);

t_replay = input('Give start and stop time [start:stop], or no entry is full file');
if isempty(t_replay)
  t_replay = [1 tag.Duration]
else
  t_replay = sscanf(t_replay, '%f:%f');
end

%for use
scans = scans + refresh_time*Fs_mic;
pause(refresh_time)
data_globe.mic(max(1, scans - Fs_mic*refresh_time+1):scans)
%%%%Finalized button_record goes here
