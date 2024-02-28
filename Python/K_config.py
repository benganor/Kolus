import numpy as np

################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
################%%%%%%%% CONFIGURATION VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

################%%%%%%%% National Instruments %%%%%%%%%%%%%%%%%%%%%%%%%%%%
daq_dev = 'Dev1'  # use daq.getDevices to find NI card
daq_terminal = 'Differential'  # SingleEnded OR Differential analog lines. can cause cross-talk.

# Specify channel as: name , physical line, IO type, sampling rate
# Last argument only for analog input: range of voltage,  digital output: type of signal
# Options for range in NI: 0.10 ,0.20 ,0.50 ,1.0 ,2.0 ,5.0 ,10
# Options for digital signal : stimuli, relay, trigger
# Physical line warning: some digital channels wont work with analog channels
# IO type corresponds to NI - options are: input, output, voltage
# usually sample sound at 250Khz, neural data at 50kHz, all others at 2.5Khz.
# Ideally sampling rates should be multiples to synchronize data
# NOTE on range: to avoid digitization, use smallest range possible
# NOTE on range: using different ranges can also cause cross-talk.
# Name of channel - 1st 4 letters determine variable in saved data
daq_channels = {
    'microphone': ('ai0', 'analog input', 250e3, np.array([-1, 1])), 
    'stimulus Record': ('ai7', 'analog input', 2500, np.array([-.2, .2])),
    'Stimulus Output': ('ao0', 'analog output', np.nan, np.array([-5, 5]), 'stimuli'),
    'LED trigger': ('port0/line2', 'digital output', np.nan, 'trigger')
}

################%%%%%%%% Plotting Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Plot channel options are: sound, time series, or digital
pp = {
    'fig_position': [0.01, 0.05, 0.98, 0.86],  # [left bottom width height]
    'daq_plot': [
        ('Microphone', 'sound'),
        ('Stimulus Record', 'digital', 'black')
    ],
    'ylims': [[0, 125]],
    'spec_threshold': 50,  # spectrogram noise threshold
    'win_disp': 2,  # seconds of data to display
    'win_FPS': 10,  # frames per second of updating. can cause weird behavior.
    'res_time': 452,  # ~ 1ms time resolution - bandwidth resolution in Hertz
    'res_freq': [1000, 1024, 125000]  # 122 frequences, just enough to see vocs.
}

################%%% Default Recording Parameters %%%%%%%%%%%%%%%%%%%%
tag = {
    'Duration': 300,  # default max duration of recording in seconds
    'Experiment': 'OS',  # name of experimental setup - optical stimulation
    'Block': 1,  # ID number of recording - where to start
    'Notes': [] 
}

################%%% Default Stimulation Parameters %%%%%%%%%%%%%%%%%%
# for interleaving stim, make param_stim(1), param_stim(2), etc.
# when interleaving, create stim with count 0 to set percentage of quiet trials directly
# possible stim types - 'continuous' pulse or 'train' of pulses
# times should be in increments of 1/window_FPS, ie .1 seconds
tag['param_stim'] = {
    'Type': 'train',  # 'train'
    'Duration_pre': 2,  # seconds
    'Duration': 10,  # seconds
    'Duration_post': 30,  # or 10 seconds
    'Duration_post_jitter': 3,  # seconds
    'Count': 10,  # default # of stimuli - Reduced if Chance < 1
    'Padding': 1,  # or 10 , padding between stimulus trains in seconds
    'Chance': 1,  # likelihood of stimulus occuring
    'Duration_pulse': 10,  # milliseconds
    'Freq': 20,  # Hertz - can be a CHIRP using start/end freq as in [5 20]
    'Power': 0  # set manually on hardware, raised cosine power set HERE
} 

################%%%%%%%% Default Folders %%%%%%%%%%%%%%%%%%%%%%%%%%%%
tag['dir_ispy'] = 'C:\\Program Files\\iSpy\\iSpy.exe'
tag['dir_base'] = 'D:\\Vocalization_Exploration\\LightStim_WT'
tag['xls'] = 'D:\\Vocalization_Exploration\\LightStim_WT\\OS_record.xls'

################%%%%%%% AUTOMATIC PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%
# Calculation logic will need translation to Python functions (more context needed)
