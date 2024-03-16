function output_stims = kolus_gen_stim(tag)
%KOLUS_gen_stim makes pulses, adds into train, randomizes, adds triggers
%Options for stim: trigger, continuous, train, raised cosine
output_stims = [];

for i = 1:length(tag.type_Out)
    if strcmp(tag.type_Out{i}, 'stimuli')
        switch tag.param_stim.Type
            case 'continuous'
                [output_stim, all_times] = pulse_continuous(tag);
            case 'cosine'
                output_pulse = pulse_train_cosine(tag);
                 output_stim = pulse_combine(output_pulse, tag);
            case 'train'
                [output_stim, all_times] = pulse_train(tag);
        end
        stim_pad = zeros(tag.fs*tag.param_stim.Padding, 1);
        output_stim = [stim_pad; output_stim; stim_pad];
        if exist('all_times')
        all_times = all_times + length(stim_pad);
        end
        output_stims(:,i) = output_stim;
    end
end

for i = 1:length(tag.type_Out)
    if strcmp( tag.type_Out(i), 'piezo')
        output_stims(:, i) = pulse_piezo(tag, length(output_stims), all_times);
    end
end

for i = 1:length(tag.type_Out)
    if strcmp( tag.type_Out(i), 'relay')
        output_stims(:, i) = pulse_relay(tag, output_stim);
    end
end

for i = 1:length(tag.type_Out)
    if strcmp( tag.type_Out(i), 'trigger')
        if ~exist('output_stim')
        output_stims = [ones((tag.Duration*tag.fs) - 1, 1); 0];
        else
        output_stims(:, i) = [ones(length(output_stim) - 1, 1); 0]; %ending zero for NI channel reset
        end
    end
end



function ind_rand = rand_index (vec_size)
rand_ind = rand(1,vec_size);
[~, ind_rand] = sort(rand_ind);


function [final_stim, all_times] = pulse_combine(input_pulse, tag)
%randomize pulses

pulses_on = ceil(tag.param_stim.Count * tag.param_stim.Chance);
pulse_randomize = [ones(pulses_on, 1); zeros(tag.param_stim.Count - pulses_on, 1)];
pulse_randomize = pulse_randomize(rand_index(tag.param_stim.Count));

all_times = [];
final_stim = [];
jitter = tag.param_stim.Duration_post_jitter;
pulse_start = find((input_pulse), 1);
for i = 1:length(pulse_randomize)
    t_jitter = ceil(tag.fs*rand*jitter);
%     t_rt = tag.refresh_time*tag.fs; %refresh time in samples
%     t_jitter = t_rt * floor(t_jitter / t_rt);
    trial_jitter = zeros(t_jitter,1);
    all_times(i) = pulse_start + length(final_stim);
    final_stim = [final_stim; (pulse_randomize(i)*input_pulse); trial_jitter];

end

%INTERLEAVING WILL GO HERE
% switch light_on_random(trial_num)
% 4 interleaved TRIAL TYPES
% ZEROS
% 0.5 sec stim
% 1 sec stim
% 1.5 sec stim
% 2 sec stim
% 2.5 sec stim


function [output_stim all_times] = pulse_continuous(tag)
%create single continuous pulse
output_pulse = [zeros(tag.fs*tag.param_stim.Duration_pre, 1); ...
    ones(tag.fs*tag.param_stim.Duration,1); ...
    zeros(tag.fs*tag.param_stim.Duration_post, 1) ...
    ];
output_pulse = output_pulse * 7.5;
[output_stim, all_times]= pulse_combine(output_pulse, tag);


function [output_stim all_times] = pulse_train(tag)

if tag.param_stim.Duration_pulse/1e3 * tag.param_stim.Freq > 1
    disp('error: frequency or pulse duration too high')
end

if length(tag.param_stim.Freq) == 2 %create CHIRP
    % Determine time values from 0 to 5 in steps of the sampling period
    t = 0 : 1/tag.fs : tag.param_stim.Duration;
    A = logspace(log10(tag.param_stim.Freq(1)), log10(tag.param_stim.Freq(2)/1.85), length(t));
    output_pulse = sin(2*pi*(A).*t);
    [peak_vals, stim_peaks] = findpeaks(output_pulse);
    stim_temp = zeros(1, tag.fs*(tag.param_stim.Duration_pre + tag.param_stim.Duration_post));
    stim_temp(stim_peaks+(tag.param_stim.Duration_pre*tag.fs)) = 1;
    stim_peaks = stim_peaks + (tag.param_stim.Duration_pre*tag.fs);
    for i = 1:length(stim_peaks)
        stim_temp(stim_peaks(i):(tag.param_stim.Duration_pulse*tag.fs*1e-3)+stim_peaks(i)) = 1;
    end
    output_pulse = stim_temp';
else %create single train of normal pulses
    l = 1/tag.param_stim.Freq; %length of one copy of stimulus
    w = tag.param_stim.Duration_pulse; %length of stimulation from ms to sec
    Ts = 1/tag.fs; %sampling points in 1 second of output
    t1 = 0:Ts:w; %time of stimulus
    t0 = w+Ts:Ts:l-Ts; %time of no-stimulus
    s1 = ones(size(t1)); %converting to 1 for stim
    s0 = zeros(size(t0)); %converting to 0 for no-stim
    s = [s1 s0]; %combining the two
    N = ceil(tag.param_stim.Duration * tag.param_stim.Freq); %How many repetitions of the wave
    s_full = [repmat(s,1,N) zeros(1, tag.fs)]; %repeating the pulse several times
    pre_stim = zeros(tag.fs*tag.param_stim.Duration_pre, 1);
    post_stim  = zeros(tag.fs*tag.param_stim.Duration_post,1);
    output_pulse = [pre_stim; s_full(1:(tag.param_stim.Duration*tag.fs))'; post_stim];
end

[output_stim, all_times] = pulse_combine(output_pulse, tag);
output_stim = output_stim * 5;%for analog compatability

function output_pulse = pulse_train_cosine(tag)
    beta = 1; %how steep the ramp is - rolloff factor
    span = pi/2; %length of full raised cosine - # of symbols
    sps = ceil((tag.fs*tag.param_stim.Duration_pulse) * (2/pi)); %total samples in pulse - oversample rate
    b = rcosdesign(beta,span,sps);
    b(end) = []; %for some reason, function adds extra sample
    b = b ./ max(abs(b));
    b = b * tag.param_stim.Power;
    b(b<0) = 0;
    b(b>0) = b(b>0) + tag.param_stim.DC_cosine;
    N = ceil(tag.param_stim.Duration * tag.param_stim.Freq); %How many repetitions of the wave
    s_full = repmat(b,1,N)'; %repeating the pulse several times
    pre_stim = zeros(tag.fs*tag.param_stim.Duration_pre, 1);
    post_stim  = zeros(tag.fs*tag.param_stim.Duration_post,1);
    output_pulse = [pre_stim; s_full; post_stim];
    plot(gca, output_pulse); pause(2);
    set(gca,  'TickLength',[ 0 0 ],  'color','none', ...
                        'xcolor', 'w', 'box', 'off' ,'xtick', [], 'ytick', [])
   


function output_stim = pulse_relay(tag, input_stim)
%creates continuous pulse during microstim to allow electrical recording
%pre-set 50ms earlier start from the start of microstimulation
%pre-set 50ms later end from the end of microstimulation
relay_delay = .05; %delay from microstim in seconds
input_stim = sum(input_stim); %find all times when output is present
output_pulse = input_stim;
output_pulse(find(input_stim) - (relay_delay*tag.fs)) = 1;
output_pulse(find(input_stim) + (relay_delay*tag.fs)) = 1;

function output_stim = pulse_piezo(tag, stim_length, all_times)
%creates piezo control pulse during laser stim at random times
%find stim times: 
tag.param_stim.Duration_pulse = .5;
tag.param_stim.Duration = 1;
tag.param_stim.Power = tag.param_stim.Piezo_Amp;
tag.param_stim.Freq = 1;
tag.param_stim.Duration_pre = tag.param_stim.Piezo_Delay;
tag.param_stim.Duration_post = 2;
% output_pulse = pulse_train_cosine(tag);
output_pulse = ones(1,250e3*.5);

stim = all_times;
output_stim = zeros(stim_length, 1);
pulses_on = ceil(length(stim) * tag.param_stim.Piezo_Chance);
pulse_randomize = [ones(pulses_on, 1); zeros(length(stim) - pulses_on, 1)];
pulse_randomize = pulse_randomize(rand_index(length(stim)));


for i = 1:length(pulse_randomize)
    s_start = stim(i);
    s_end = s_start  + length(output_pulse)-1;
    output_stim(s_start:s_end) = output_pulse * pulse_randomize(i);  
end
output_stim = output_stim * 10;
