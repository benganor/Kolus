import pandas as pd
import numpy as np
import os

def bin2hdf5(tag):
    # ... (Binary file reading and DataFrame creation as before) ... 

    # Split into channels based on rates (as before) ...

    # Partial data handling (Adapt if needed)

    # Save individual channels as HDF5 files
    for channel_name in df.columns:
        data = df[channel_name].to_numpy()
        file_name = os.path.splitext(tag['file_dat'])[0] + f'_{channel_name}.h5'
        df[channel_name].to_hdf(file_name, key=channel_name)

    # Save 'tag' separately as HDF5 
    tag_df = pd.DataFrame.from_dict(tag, orient='index').T  # Convert to DataFrame
    tag_df.to_hdf(tag['file_mat'], key='tag')
