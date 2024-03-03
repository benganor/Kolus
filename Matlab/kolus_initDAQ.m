function kolus_initDAQ()
% Initialize data acquisition setup using National Instruments Card
K_config;
global S
S.Daq = daq.createSession('ni');
tag.type_Out = {};

for i  = 1:length(daq_channels)
    Ch_current = daq_channels{i};
    switch Ch_current{3}
        case 'digital output'
            io_type = 'OutputOnly';
            tag.type_Ch(i) = 0;
            tag.type_Out = [tag.type_Out Ch_current{end}];
            S.Ch(i) = S.Daq.addDigitalChannel(daq_dev,Ch_current{2}, io_type);
        case 'digital input'
            io_type = 'InputOnly';
            tag.type_Ch(i) = 1;
            S.Ch(i) = S.Daq.addDigitalChannel(daq_dev,Ch_current{2}, io_type);
        case 'analog input'
            io_type = 'Voltage';
            tag.type_Ch(i) = 1;
            S.Ch(i) = S.Daq.addAnalogInputChannel(daq_dev,Ch_current{2}, io_type);
            S.Ch(i).Range = Ch_current{5};
            S.Ch(i).TerminalConfig = daq_terminal;
        case 'analog output'
            io_type = 'Voltage';
            tag.type_Ch(i) = 0;
            tag.type_Out = [tag.type_Out Ch_current{end}];
            S.Ch(i) = S.Daq.addAnalogOutputChannel(daq_dev,Ch_current{2}, io_type);
            S.Ch(i).Range = Ch_current{5};
        otherwise
            warning('Error in K_config input/output field')
            pause(1e3)
    end
    S.Ch(i).Name = Ch_current{1};
end

S.Daq.Rate = max(tag.Rates);

tag.fs = S.Daq.Rate; %NI Rate - all recording happens at max rate
tag.folder = cd; %experiment folder
guidata(gcf, tag) %pass tag on for modifications/saving

%Pre-allocate buffer for saving
SaveData = nan(sum(tag.refresh_time*tag.Rates), 1);

addlistener(S.Daq,'DataAvailable',...
    @(src,obj)Kolus_datasave(src,obj,SaveData, tag.Rates));
% addlistener(S.Daq, 'DataRequired', @Kolus_continuous); %for continuous


function Kolus_datasave(src,obj, SaveData, Rates)

global DAQ_buffer
Fs = src.Rate;
DAQ_buffer.Time = obj.TriggerTime;

if ~isempty(DAQ_buffer.Fid)
%     tic
    chunk_end = 0;
    for i = 1:length(Rates)
        chunk_start = chunk_end + 1;
        chunk_end = (chunk_start - 1) + ( size(obj.Data,1) * (Rates(i) / Fs) );
        SaveData(chunk_start:ceil(chunk_end)) = ...
            obj.Data(1:(Fs/Rates(i)):end, i);
    end
    fwrite(DAQ_buffer.Fid, SaveData, 'double'); %avg. time .2 MS for every 100ms data
    start_b = DAQ_buffer.Index;
    DAQ_buffer.Buffer(start_b:(length(SaveData)+ start_b - 1)) = SaveData;
    DAQ_buffer.Index = start_b + length(SaveData);
%     toc
end

function Kolus_continuous(src,~)
%%%Queue 10 seconds of zeros - no stimulus
queueOutputData(src, zeros(src, 1));
