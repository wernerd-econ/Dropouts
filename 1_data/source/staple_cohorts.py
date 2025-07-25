import os
import pandas as pd
import gc

# Directory where your .dta files are located
    # Once again, in final version switch to ../output but for now keep local 
directory = "/Users/wernerd/Desktop/Daniel Werner/Cohorts"

# Initialize an empty DataFrame to store all the data
all_data = pd.DataFrame()

# Loop through all files in the directory
i=0
for filename in os.listdir(directory):
    if filename.endswith('.dta'):
        # Build the full file path
        i+=1
        print(f"found {i}")
        file_path = os.path.join(directory, filename)
        
        # Read the .dta file
        df = pd.read_stata(file_path)
        print(f"read {i}")
        
        # Append the data to the all_data DataFrame
        all_data = pd.concat([all_data, df], ignore_index=True)

        del df

        gc.collect()

        print(f"Done with {i}")

# Save the concatenated DataFrame to a CSV file
print("DONE WITH ALL THE COHORTS...")
print("Moving on to saving panel data ---->") 

print("Converting object columns to string type...")
for col in all_data.select_dtypes(include="object").columns:
    all_data[col] = all_data[col].astype("string")

print("Converting dataframe to parquet...")
desktop_path = os.path.expanduser("~/Desktop/combined_data.parquet")
all_data.to_parquet(desktop_path, index=False)

print("All .dta files have been stacked and saved as combined_data.parquet")
