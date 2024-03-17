import numpy as np
import matplotlib.pyplot as plt
import time  
import pyvisa
from PyQt5 import QtWidgets, QtGui, QtCore   # Example using PyQt 
from scipy.signal import spectrogram  # Example using SciPy
import pandas as pd 
import h5py # Example using h5py for file I/O



def kolus_button_record(handles, pp):  

    # DAQ Initialization:
    rm = pyvisa.ResourceManager()
    daq_device = rm.open_resource("DAQ_resource_name")  # Replace with the actual resource name

    # Example Configuration:  Adjust according to your DAQ device's capabilities and requirements

    daq_device.write("CONFIGURE:CHANNEL 0, ANALOG_INPUT, 0, 10")  # Configure an analog input channel
    daq_device.write("CONFIGURE:SAMPLE:RATE 250e3")  # Set the sampling rate
    daq_device.write("CONFIGURE:TRIGGER:SOURCE IMMEDIATE")  # Immediate triggering

    # ... Other configuration commands for channels, acquisition modes, etc.  

    try:
       # ... Real-time plotting loop ...
    except Exception as e:
       print(f"Error during recording: {e}") 
    finally:
       tag['end'] = time.time()  
       tag['Duration'] = daq_device.scans_acquired / tag['fs']
       DAQ_cleanup(daq_device, tag)



def DAQ_cleanup(daq_device, tag):
    daq_device.stop()  # Stop any ongoing acquisition

     # Clear any queued data or pending operations
    daq_device.clear()  

    # (Optional) Reset DAQ to a default state, if desired. 
    # daq_device.write("*RST")   # Uncomment if you want a hard reset

    if 'Fid' in tag:
        fclose(tag['Fid'])  # Python file I/O equivalent 

    tag['Fid'] = []
    time.sleep(0.01)  

    daq_device.close()  # Close the DAQ resource 



def scans2times(p_skip, scans_added, times_vec):
    starts = []
    ends = []
    for i in range(int(scans_added / np.max(p_skip))):
        starts += [1, * (1 + np.cumsum(p_skip[:-1]))] + (np.sum(p_skip) * i) 
        ends += np.cumsum(p_skip) + (np.sum(p_skip) * i)   

    for i, skip in enumerate(p_skip):
        times_vec[i] += np.concatenate([np.arange(start, end + 1) for start, end in  zip(starts[i::len(p_skip)], ends[i::len(p_skip)])])

    return times_vec


def k_viewstim(handles, stimulus, tag):
    plt.sca(handles.S[1])  # Assuming handles.S stores axes references
    plt.cla()

    stimulus_dur = len(stimulus) / tag['fs']
    stimulus_diff = np.where(np.diff(stimulus))[0]
    stim_pairs = np.reshape(stimulus_diff / tag['fs'], (-1, 2))

    if len(stim_pairs) <= 200:
        for pair in stim_pairs:
            plt.fill(pair, [-1, -1, 1, 1], 'k') 
    else:
        stimulus[stimulus > 1] = 1
        t_stim = np.arange(1 / tag['fs'], stimulus_dur + 1 / tag['fs'], 1 / tag['fs'])[::100] 
        plt.plot(t_stim, stimulus[::100])

    if np.any(stimulus):  
        plt.xlim([0, stimulus_dur])
        plt.ylim([np.min(stimulus), np.max(stimulus)])

def calculate_spectrogram(data, fs, pp):
    f, t, Sxx = signal.spectrogram(data, fs, nperseg=pp['res_time'], noverlap=pp['res_time'] - 1)
    return f, t, Sxx  # Return the frequencies, time points, and spectrogram


# ... Other helper functions for data processing, file saving, etc. 

def filter_data(data, fs, low_cutoff, high_cutoff, order=5):
    nyq = 0.5 * fs  # Nyquist frequency
    low = low_cutoff / nyq
    high = high_cutoff / nyq
    b, a = signal.butter(order, [low, high], btype='band')  # Butterworth bandpass
    return signal.filtfilt(b, a, data)

def normalize_data(data, range=(-1, 1)):
    data_min, data_max = np.min(data), np.max(data)
    return ((data - data_min) * (range[1] - range[0]) / (data_max - data_min)) + range[0] 

def save_data_csv(data, filename):
    df = pd.DataFrame(data)
    df.to_csv(filename, index=False)

def save_data_hdf5(data, filename, key='data'):
    with h5py.File(filename, 'w') as h5f:
        h5f.create_dataset(key, data=data) 

def setup_gui():
    app = QtWidgets.QApplication([])  # Create the application

    # Main Window Setup
    window = QtWidgets.QMainWindow()
    window.setWindowTitle("Analysis Interface")

    # Example Widgets
    record_button = QtWidgets.QPushButton("Start Recording")
    plot_area = QtWidgets.QWidget()  # Area for your matplotlib plots 

     # Layout (Adapt to use your preferred Qt layout managers)
    layout = QtWidgets.QVBoxLayout()  
    layout.addWidget(record_button)
    layout.addWidget(plot_area)  
    central_widget = QtWidgets.QWidget()  
    central_widget.setLayout(layout)
    window.setCentralWidget(central_widget)  

    # (Connect button clicks to functions, etc.)

    window.show()  
    app.exec_() 
