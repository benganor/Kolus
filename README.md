# **Kolus**
A data acquisition software for recording signals and stimulating while visualizing ultrasonic vocalizations

## Description

This is collection of scripts and modules for data acquisition (DAQ), analysis, and visualization, written in both Python and MATLAB. It is designed for use with a DAQ device from National Instruments.

Here's a brief overview of what each script or module does:

Kolus_button_record: These scripts handle the recording of data from the DAQ device. They are responsible for setting up the DAQ device, starting the data acquisition process, and storing the acquired data for later analysis.

button_options: These scripts provide a user interface for setting options or parameters related to the data acquisition process.

gen_fig: These scripts generate figures or plots based on the acquired data. They use libraries like matplotlib (in Python) or MATLAB's built-in plotting functions to visualize the data.

gen_stim: These scripts generate stimuli that can are sent to the DAQ device. This could are useful in experiments where you want to try multiple types of stimuli.

K_config: These scripts handle the configuration of all parameters. Most parameters are set on execution. These include the DAQ device sampling rate, trigger source, and channel configuration. Some stimuli parameters are changeable during run-time in the GUI.

bin2hdf5 and bin2mat: These scripts convert binary data to other formats. The Python script converts binary data to the HDF5 format, which is a widely-used format for storing large amounts of scientific data. The MATLAB script converts binary data to MATLAB's .mat format, which can are easily loaded into the MATLAB workspace for analysis.

tag2xls: These scripts convert meta-data to excel sheets for logging experiments.

Kolus: These are the main scripts that tie everything together. They provide a user interface for running the data acquisition process, setting options, and visualizing the results.

The config_examples directory contains example configuration scripts for different types of experiments or setups.

## No Installation Required

```sh
git clone https://github.com/arenganor/Kolus.git
cd Kolus