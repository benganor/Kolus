import pandas as pd
import datetime  

def tag2xls(tag, explog_xls):
    animal_name = os.path.basename(os.path.normpath(tag.folder))
    date = datetime.datetime.now().strftime('%y_%m_%d')

    if tag.enablestim:
        xl_data = {
            "Block": tag.Block,
            "Power": tag.param_stim.Power, 
            "Type": tag.param_stim.Type,
            "Duration": tag.param_stim.Duration, 
            "Duration Pulse": tag.param_stim.Duration_pulse,
            "Frequency": tag.param_stim.Freq, 
            "Chance": tag.param_stim.Chance, 
            "Count": tag.param_stim.Count, 
            "Experiment": tag.Experiment,
            "Date": date, 
            "Recording Duration": tag.Duration,
            "Notes": " ".join(tag.Notes) 
        }
    else:
        xl_data = {
            "Block": tag.Block,
            "Experiment": tag.Experiment,
            "Date": date,
            "Recording Duration": tag.Duration,
            "Notes": " ".join(tag.Notes)
        }

    df = pd.DataFrame(xl_data, index=[0])  # Create DataFrame with a single row

    with pd.ExcelWriter(explog_xls, engine='openpyxl', mode='a', if_sheet_exists='overlay') as writer:  
        df.to_excel(writer, sheet_name=animal_name, startrow=tag.Block - 1, index=False, header=False)
