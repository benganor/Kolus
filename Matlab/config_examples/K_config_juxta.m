%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% CONFIGURATION VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%% National Instruments %%%%%%%%%%%%%%%%%%%%%%%%%%%%
daq_dev = 'Dev3'; %use daq.getDevices to find NI card
daq_terminal = 'Differential'; %SingleEnded OR Differential analog lines. can cause cross-talk.
%Specify channel as: name , physical line, IO type, sampling rate
%Last argument only for analog input: range of voltage,  digital output: type of signal
%Options for range in NI: 0.10 ,0.20 ,0.50 ,1.0 ,2.0 ,5.0 ,10
%Options for digital signal : stimuli, relay, trigger
%Physical line warning: some digital channels wont work with analog channels
%IO type corresponds to NI - options are: input, output, voltage
%usually sample sound at 250Khz, neural data at 50kHz, all others at 2.5Khz.
%Ideally sampling rates should be multiples to synchronize data
%NOTE on range: to avoid digitization, use smallest range possible
%NOTE on range: using different ranges can also cause cross-talk.
%Name of channel - 1st 4 letters determine variable in saved data
daq_channels = { ...
{'microphone' , 'ai0', 'analog input', 250e3, [-1,1]}, ...
{'neuron', 'ai5', 'analog input', 50000, [-5,5]} , ...
{'wheel', 'port0/line0', 'digital input', 2500}, ...
{'LED trigger' , 'port0/line2', 'digital output', nan, 'trigger'}
};

%%%%%%%%%%%%%%%%%%%%%%%% Plotting Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Plot channel options are: sound, time series, or digital
pp.fig_position = [0.01,0.05,0.98,0.86]; %[left bottom width height]
pp.daq_plot = { ...
{'Microphone', 'sound'}, ...
{'neuron', 'time series'}, ...
{'wheel', 'digital', 'green'} ...
};
pp.ylims = [[0 125]; [-5 5]];
pp.spec_threshold = 50; %spectrogram noise threshold
pp.win_disp = 2; %seconds of data to display
pp.win_FPS = 10; %frames per second of updating. can cause weird behavior.
pp.res_time = 452; % ~ 1ms time resolution - bandwidth resolution in Hertz
pp.res_freq = [1000 1024 125000]; %122 frequences, just enough to see vocs.


%%%%%%%%%%%%%%%%%%% Default Recording Parameters %%%%%%%%%%%%%%%%%%%%
tag.Duration = 300; %default max duration of recording in seconds
tag.Experiment = 'JU'; %name of experimental setup - juxtacellular recording
tag.Block = 1; %ID number of recording - where to start
tag.Notes = {};

%%%%%%%%%%%%%%%%%%% Default Stimulation Parameters %%%%%%%%%%%%%%%%%%
%for interleaving stim, make param_stim(1), param_stim(2), etc.
%when interleaving, create stim with count 0 to set percentage of quiet trials directly
%possible stim types - 'continuous' pulse or 'train' of pulses
%times should be in increments of 1/window_FPS, ie .1 seconds
tag.param_stim.Type = 'cosine'; % 'train'
tag.param_stim.Duration_pre = 0.5; %seconds
tag.param_stim.Duration = 0.5; %seconds
tag.param_stim.Duration_post = 1; %or 10 seconds
tag.param_stim.Duration_post_jitter = 3; %seconds
tag.param_stim.Count = 10; %default # of stimuli - Reduced if Chance < 1
tag.param_stim.Padding = 1; %or 10 , padding between stimulus trains in seconds
tag.param_stim.Chance = 0; %likelihood of stimulus occuring
%For trains of pulses
tag.param_stim.Duration_pulse = 500; %milliseconds
tag.param_stim.Freq = 20; %Hertz - can be a CHIRP using start/end freq as in [5 20]
%for raised pulse_train_cosine
tag.param_stim.Power = 10; %set manually on hardware, raised cosine power set HERE

%%%%%%%%%%%%%%%%%%%%%%%% Default Folders %%%%%%%%%%%%%%%%%%%%%%%%%%%%
tag.dir_ispy = 'C:\Program Files\iSpy\iSpy.exe';
tag.dir_base = 'D:\Vocalization_Exploration\LightStim_WT'; %starting directory
tag.xls = 'D:\Vocalization_Exploration\LightStim_WT\OS_record.xls';


%%%%%%%%%%%%%%%%%%%%%%% AUTOMATIC PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%
tag.enablestim = sum(cellfun(@(x) strcmp(x(end),'stimuli'), daq_channels));
tag.Rates = cellfun(@(x) x{4}, daq_channels);
tag.Rates = tag.Rates(~isnan(tag.Rates));
tag.Channels = cellfun(@(x) x(1), daq_channels);
tag.refresh_time =  1 / pp.win_FPS;
pp.spec_time = 1.81/(4*pp.res_time); % from spgrambw default time setting
pp.large_axis = sum(cellfun(@(x) sum(ismember({'sound', 'time series'}, x(2))), pp.daq_plot));
pp.digCh = cellfun(@(x) sum(ismember({'digital'}, x(2))), pp.daq_plot);
pp.digCh_color = cellfun(@(x) x(end), pp.daq_plot(logical(pp.digCh)));
