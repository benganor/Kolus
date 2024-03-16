import numpy as np
from scipy.signal import rcosdesign


def kolus_gen_stim(tag):
    output_stims = []

    for i, out_type in enumerate(tag['type_Out']):
        if out_type == 'stimuli':
            if tag['param_stim']['Type'] == 'continuous':
                output_stim, all_times = pulse_continuous(tag)
            elif tag['param_stim']['Type'] == 'cosine':
                output_stim, all_times = pulse_train_cosine(tag)
            elif tag['param_stim']['Type'] == 'train':
                 output_stim, all_times = pulse_train(tag)
            else:
                print("Stimulus type not supported")
                return
            output_stims.append(output_stim)

        elif out_type == 'piezo':
            output_stim = pulse_piezo(tag, output_stims[0].shape[0]) 
            output_stims.append(output_stim)

        elif out_type == 'relay':
            output_stim = pulse_relay(tag, output_stims[0])  
            output_stims.append(output_stim)

        elif out_type == 'trigger':
            output_stim = np.zeros_like(output_stims[0]) 
            output_stim[:int(tag['Duration'] * tag['fs'])] = 1
            output_stims.append(output_stim) 

    return output_stims


def rand_index(vec_size):
    rand_ind = np.random.rand(vec_size)
    return np.argsort(rand_ind)


def pulse_continuous(tag):
    pre_stim = np.zeros(int(tag['fs'] * tag['param_stim']['Duration_pre']), dtype=float)
    stim = np.ones(int(tag['fs'] * tag['param_stim']['Duration']), dtype=float) * 7.5
    post_stim = np.zeros(int(tag['fs'] * tag['param_stim']['Duration_post']), dtype=float)
    output_stim = np.concatenate((pre_stim, stim, post_stim))
    all_times = None
    return output_stim, all_times


def pulse_train(tag):
    if tag['param_stim']['Duration_pulse'] / 1e3 * tag['param_stim']['Freq'] > 1:
        print("Error: frequency or pulse duration too high")
        return None, None  # Return None on error

    if len(tag['param_stim']['Freq']) == 2:  # Chirp
        t = np.arange(0, tag['param_stim']['Duration'], 1 / tag['fs'])
        A = np.logspace(np.log10(tag['param_stim']['Freq'][0]),
                        np.log10(tag['param_stim']['Freq'][1] / 1.85), len(t))
        chirp_pulse = np.sin(2 * np.pi * A * t)

        # Find peaks with greater than 90% of the maximum amplitude
        peak_indices = np.where(chirp_pulse > np.max(chirp_pulse) * 0.9)[0]

        # Create pulse train from peak indices
        output_pulse = np.zeros(int(tag['fs'] * (tag['param_stim']['Duration_pre'] + tag['param_stim']['Duration_post'])))
        pulse_duration_samples = int(tag['param_stim']['Duration_pulse'] * tag['fs'] * 1e-3)

        for peak_index in peak_indices:
            start_index = peak_index + int(tag['fs'] * tag['param_stim']['Duration_pre'])
            output_pulse[start_index: start_index + pulse_duration_samples] = 1

    else:  # Normal pulse train
        period = 1 / tag['param_stim']['Freq'] 
        pulse_duration = tag['param_stim']['Duration_pulse']
        duty_cycle = pulse_duration / period  # Percentage of time the pulse is high
        num_pulses = int(tag['param_stim']['Duration'] * tag['param_stim']['Freq'])

        output_pulse = np.zeros(int(tag['fs'] * tag['param_stim']['Duration']) +
                                int(tag['fs'] * (tag['param_stim']['Duration_pre'] + 
                                              tag['param_stim']['Duration_post'])))

        for i in range(num_pulses):
            start_index = int(i * period * tag['fs']) + int(tag['fs'] * tag['param_stim']['Duration_pre'])
            end_index = start_index + int(pulse_duration * tag['fs'])
            output_pulse[start_index:end_index] = 1 

    return output_pulse * 5, None  # Adjust amplitude as needed 


def pulse_piezo(tag, stim_length):
    pre_stim = np.zeros((int(tag['fs'] * tag['param_stim']['Piezo_Delay']), 1))
    stim_duration = int(0.5 * tag['fs'])
    post_stim = np.zeros((stim_length - pre_stim.size - stim_duration, 1)) 
    output_pulse = np.concatenate([pre_stim, np.ones((stim_duration, 1)), post_stim])

    all_times = np.where(output_stims[0] > 0)[0] 
    pulses_on = int(len(all_times) * tag['param_stim']['Piezo_Chance'])
    pulse_randomize = np.concatenate([np.ones(pulses_on), np.zeros(len(all_times) - pulses_on)])
    pulse_randomize[rand_index(len(all_times))] = pulse_randomize  

    output_stim = np.zeros_like(output_stims[0])

    for i in range(len(pulse_randomize)):
        s_start = all_times[i]
        s_end = s_start + output_pulse.size
        output_stim[s_start:s_end] += output_pulse * pulse_randomize[i] 

    return output_stim * 10 


def pulse_relay(tag, input_stim):
    relay_delay = 0.05 
    start_padding = np.pad(input_stim[:-int(relay_delay*tag['fs'])], (int(relay_delay*tag['fs']), 0), 'constant')
    end_padding = np.pad(input_stim[int(relay_delay*tag['fs']):], (0, int(relay_delay*tag['fs'])), 'constant')
    return start_padding + input_stim + end_padding 

def pulse_trigger(tag, output_stim):
    duration_samples = int(tag['Duration'] * tag['fs'])
    output_pulse = np.concatenate((np.ones(duration_samples), np.zeros_like(output_stim[duration_samples:])))
    return output_pulse 