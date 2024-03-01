function Kolus(varargin)
% Kolus - Record Ultrasonic Sound + Other signals
%
% With additions to stimulate/trigger other devices
%
% Requirements:
% NI Daq-MX ,compatible NI card, Matlab 2014a, MS excel
% Ispy at https://www.ispyconnect.com/
% voicebox at https://github.com/ImperialCollegeLondon/sap-voicebox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%   SETUP  %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1. Add Kolus folder to PATH
%2. Specify experimental setup in the K_config file
%   by adding channels, sampling rates, stim parameters, etc.
%   To change config during experiment, reload Kolus
%3. Run Kolus with experimental directory as input

% Written by Benjamin Gan-Or
% Last Major Update: Jan 21, 2019
close all;
K_config;
if isempty(varargin)
    path = uigetdir(tag.dir_base); %ask user for exp folder
    cd(path)
else
    cd(varargin{1})
end

kolus_gen_fig; % Open GUI - GUI contains meta-data - don't close it
kolus_initDAQ; % Initialize data acquisition session