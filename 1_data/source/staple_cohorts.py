# import os
# import pandas as pd
# import gc

# # Directory where your .dta files are located
#     # Once again, in final version switch to ../output but for now keep local 
# directory = "/Users/wernerd/Desktop/Daniel Werner/Cohorts"

# # Initialize an empty DataFrame to store all the data
# all_data = pd.DataFrame()

# # Loop through all files in the directory
# i=0
# for filename in os.listdir(directory):
#     if filename.endswith('.dta'):
#         # Build the full file path
#         i+=1
#         print(f"found {i}")
#         file_path = os.path.join(directory, filename)
        
#         # Read the .dta file
#         df = pd.read_stata(file_path)
#         print(f"read {i}")
        
#         # Append the data to the all_data DataFrame
#         all_data = pd.concat([all_data, df], ignore_index=True)

#         del df

#         gc.collect()

#         print(f"Done with {i}")

# # Save the concatenated DataFrame to a CSV file
# print("DONE WITH ALL THE COHORTS...")
# print("Moving on to saving panel data ---->") 

# desktop_path = os.path.expanduser("~/Desktop/combined_data.dta")
# all_data.to_stata("combined_data.dta", write_index=False)

# print("All .dta files have been stacked and saved as combined_data.dta")

import os
import pandas as pd
import gc
import psutil

directory = "/Users/wernerd/Desktop/Daniel Werner/CleanCohorts"
dfs = []
i = 0

for filename in os.listdir(directory):
    if filename.endswith('.dta'):
        i += 1
        file_path = os.path.join(directory, filename)
        print(f"Reading file {i}: {filename}")
        
        df = pd.read_stata(file_path)
        dfs.append(df)
        
        # Check memory after each load
        process = psutil.Process()
        mem = process.memory_info().rss / 1e9
        print(f"Memory used so far: {mem:.2f} GB")
        
        gc.collect()

print("All cohorts loaded. Concatenating...")

# Do the concat just once — much more efficient
all_data = pd.concat(dfs, ignore_index=True)
del dfs
gc.collect()

print("Saving to disk...")
all_data.to_stata(os.path.expanduser("~/Desktop/combined_data.dta"), write_index=False)
print("Done!")