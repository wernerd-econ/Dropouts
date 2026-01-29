import os
import pandas as pd
import gc
import psutil

#directory = "../output"
directory = "/Users/wernerd/Desktop/Daniel Werner/CleanCohorts"

dfs = []
i = 0
id_offset = 0 
hh_offset = 0
viv_offset = 0

for filename in os.listdir(directory):
    if filename.endswith('.dta'):
        i += 1
        file_path = os.path.join(directory, filename)
        print(f"Reading file {i}: {filename}")
        
        df = pd.read_stata(file_path)
        
        # Add offsets to make IDs unique across cohorts
        if 'id' in df.columns:
            df['id'] = df['id'] + id_offset
        if 'id_hog' in df.columns:
            df['id_hog'] = df['id_hog'] + hh_offset
        if 'id_viv' in df.columns:
            df['id_viv'] = df['id_viv'] + viv_offset
        
        dfs.append(df)
        
        # Update offsets for next cohort
        if 'id' in df.columns:
            id_offset = df['id'].max() + 1
        if 'id_hog' in df.columns:
            hh_offset = df['id_hog'].max() + 1
        if 'id_viv' in df.columns:
            viv_offset = df['id_viv'].max() + 1
        
        # Check memory after each load
        process = psutil.Process()
        mem = process.memory_info().rss / 1e9
        print(f"Memory used so far: {mem:.2f} GB")
        print(f"ID offset now at: {id_offset}, HH offset: {hh_offset}, VIV offset: {viv_offset}")
        
        gc.collect()

print("All cohorts loaded. Concatenating...")

# Do the concat just once — much more efficient
all_data = pd.concat(dfs, ignore_index=True)
del dfs
gc.collect()

# Verify uniqueness
print("\nVerifying ID uniqueness...")
print(f"Unique IDs: {all_data['id'].nunique()}")
print(f"Total observations: {len(all_data)}")
print(f"Max observations per ID: {all_data.groupby('id').size().max()}")

print("\nSaving to disk...")
for col in all_data.select_dtypes(include=['object']).columns:
    try:
        all_data[col] = pd.to_numeric(all_data[col], errors='coerce')
    except:
        all_data[col] = all_data[col].astype(str)

all_data.to_stata(os.path.expanduser("../output/ENOE_panel.dta"), write_index=False)
print("Done!")