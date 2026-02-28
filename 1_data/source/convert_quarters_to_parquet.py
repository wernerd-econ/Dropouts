"""
Convert .dta quarters to .parquet for failed cohorts
"""
import pandas as pd
import sys
import os

def main():
    # Read failed cohorts file
    failed_file = "../output/failed_cohorts.txt"
    
    if not os.path.exists(failed_file):
        print("No failed cohorts found. Skipping conversion.")
        return
    
    with open(failed_file, 'r') as f:
        failed_cohorts = [line.strip().split(',') for line in f]
    
    # Map of cohorts: each line is [cohort_number, starting_i]
    cohort_list = [
        "2007_T1.dta", "2007_T2.dta", "2007_T3.dta", "2007_T4.dta", "2008_T1.dta",
    "2007_T2.dta", "2007_T3.dta", "2007_T4.dta", "2008_T1.dta", "2008_T2.dta",
    "2007_T3.dta", "2007_T4.dta", "2008_T1.dta", "2008_T2.dta", "2008_T3.dta",
    "2007_T4.dta", "2008_T1.dta", "2008_T2.dta", "2008_T3.dta", "2008_T4.dta",
    "2008_T1.dta", "2008_T2.dta", "2008_T3.dta", "2008_T4.dta", "2009_T1.dta",
    "2008_T2.dta", "2008_T3.dta", "2008_T4.dta", "2009_T1.dta", "2009_T2.dta",
    "2008_T3.dta", "2008_T4.dta", "2009_T1.dta", "2009_T2.dta", "2009_T3.dta",
    "2008_T4.dta", "2009_T1.dta", "2009_T2.dta", "2009_T3.dta", "2009_T4.dta",
    "2009_T1.dta", "2009_T2.dta", "2009_T3.dta", "2009_T4.dta", "2010_T1.dta",
    "2009_T2.dta", "2009_T3.dta", "2009_T4.dta", "2010_T1.dta", "2010_T2.dta",
    "2009_T3.dta", "2009_T4.dta", "2010_T1.dta", "2010_T2.dta", "2010_T3.dta",
    "2009_T4.dta", "2010_T1.dta", "2010_T2.dta", "2010_T3.dta", "2010_T4.dta",
    "2010_T1.dta", "2010_T2.dta", "2010_T3.dta", "2010_T4.dta", "2011_T1.dta",
    "2010_T2.dta", "2010_T3.dta", "2010_T4.dta", "2011_T1.dta", "2011_T2.dta",
    "2010_T3.dta", "2010_T4.dta", "2011_T1.dta", "2011_T2.dta", "2011_T3.dta",
    "2010_T4.dta", "2011_T1.dta", "2011_T2.dta", "2011_T3.dta", "2011_T4.dta",
    "2011_T1.dta", "2011_T2.dta", "2011_T3.dta", "2011_T4.dta", "2012_T1.dta",
    "2011_T2.dta", "2011_T3.dta", "2011_T4.dta", "2012_T1.dta", "2012_T2.dta",
    "2011_T3.dta", "2011_T4.dta", "2012_T1.dta", "2012_T2.dta", "2012_T3.dta",
    "2011_T4.dta", "2012_T1.dta", "2012_T2.dta", "2012_T3.dta", "2012_T4.dta",
    "2012_T1.dta", "2012_T2.dta", "2012_T3.dta", "2012_T4.dta", "2013_T1.dta",
    "2012_T2.dta", "2012_T3.dta", "2012_T4.dta", "2013_T1.dta", "2013_T2.dta",
    "2012_T3.dta", "2012_T4.dta", "2013_T1.dta", "2013_T2.dta", "2013_T3.dta",
    "2012_T4.dta", "2013_T1.dta", "2013_T2.dta", "2013_T3.dta", "2013_T4.dta",
    "2013_T1.dta", "2013_T2.dta", "2013_T3.dta", "2013_T4.dta", "2014_T1.dta",
    "2013_T2.dta", "2013_T3.dta", "2013_T4.dta", "2014_T1.dta", "2014_T2.dta",
    "2013_T3.dta", "2013_T4.dta", "2014_T1.dta", "2014_T2.dta", "2014_T3.dta",
    "2013_T4.dta", "2014_T1.dta", "2014_T2.dta", "2014_T3.dta", "2014_T4.dta",
    "2014_T1.dta", "2014_T2.dta", "2014_T3.dta", "2014_T4.dta", "2015_T1.dta",
    "2014_T2.dta", "2014_T3.dta", "2014_T4.dta", "2015_T1.dta", "2015_T2.dta",
    "2014_T3.dta", "2014_T4.dta", "2015_T1.dta", "2015_T2.dta", "2015_T3.dta",
    "2014_T4.dta", "2015_T1.dta", "2015_T2.dta", "2015_T3.dta", "2015_T4.dta",
    "2015_T1.dta", "2015_T2.dta", "2015_T3.dta", "2015_T4.dta", "2016_T1.dta",
    "2015_T2.dta", "2015_T3.dta", "2015_T4.dta", "2016_T1.dta", "2016_T2.dta",
    "2015_T3.dta", "2015_T4.dta", "2016_T1.dta", "2016_T2.dta", "2016_T3.dta",
    "2015_T4.dta", "2016_T1.dta", "2016_T2.dta", "2016_T3.dta", "2016_T4.dta",
    "2016_T1.dta", "2016_T2.dta", "2016_T3.dta", "2016_T4.dta", "2017_T1.dta",
    "2016_T2.dta", "2016_T3.dta", "2016_T4.dta", "2017_T1.dta", "2017_T2.dta",
    "2016_T3.dta", "2016_T4.dta", "2017_T1.dta", "2017_T2.dta", "2017_T3.dta",
    "2016_T4.dta", "2017_T1.dta", "2017_T2.dta", "2017_T3.dta", "2017_T4.dta",
    "2017_T1.dta", "2017_T2.dta", "2017_T3.dta", "2017_T4.dta", "2018_T1.dta",
    "2017_T2.dta", "2017_T3.dta", "2017_T4.dta", "2018_T1.dta", "2018_T2.dta",
    "2017_T3.dta", "2017_T4.dta", "2018_T1.dta", "2018_T2.dta", "2018_T3.dta",
    "2017_T4.dta", "2018_T1.dta", "2018_T2.dta", "2018_T3.dta", "2018_T4.dta",
    "2018_T1.dta", "2018_T2.dta", "2018_T3.dta", "2018_T4.dta", "2019_T1.dta",
    "2018_T2.dta", "2018_T3.dta", "2018_T4.dta", "2019_T1.dta", "2019_T2.dta",
    "2018_T3.dta", "2018_T4.dta", "2019_T1.dta", "2019_T2.dta", "2019_T3.dta",
    "2018_T4.dta", "2019_T1.dta", "2019_T2.dta", "2019_T3.dta", "2019_T4.dta",
    "2019_T1.dta", "2019_T2.dta", "2019_T3.dta", "2019_T4.dta", "2020_T1.dta",
    "2020_T3.dta", "2020_T4.dta", "2021_T1.dta", "2021_T2.dta", "2021_T3.dta",
    "2020_T4.dta", "2021_T1.dta", "2021_T2.dta", "2021_T3.dta", "2021_T4.dta",
    "2021_T1.dta", "2021_T2.dta", "2021_T3.dta", "2021_T4.dta", "2022_T1.dta",
    "2021_T2.dta", "2021_T3.dta", "2021_T4.dta", "2022_T1.dta", "2022_T2.dta",
    "2021_T3.dta", "2021_T4.dta", "2022_T1.dta", "2022_T2.dta", "2022_T3.dta",
    "2021_T4.dta", "2022_T1.dta", "2022_T2.dta", "2022_T3.dta", "2022_T4.dta",
    "2022_T1.dta", "2022_T2.dta", "2022_T3.dta", "2022_T4.dta", "2023_T1.dta",
    "2022_T2.dta", "2022_T3.dta", "2022_T4.dta", "2023_T1.dta", "2023_T2.dta",
    "2022_T3.dta", "2022_T4.dta", "2023_T1.dta", "2023_T2.dta", "2023_T3.dta",
    "2022_T4.dta", "2023_T1.dta", "2023_T2.dta", "2023_T3.dta", "2023_T4.dta",
    "2023_T1.dta", "2023_T2.dta", "2023_T3.dta", "2023_T4.dta", "2024_T1.dta",
    "2023_T2.dta", "2023_T3.dta", "2023_T4.dta", "2024_T1.dta", "2024_T2.dta",
    "2023_T3.dta", "2023_T4.dta", "2024_T1.dta", "2024_T2.dta", "2024_T3.dta",
    "2023_T4.dta", "2024_T1.dta", "2024_T2.dta", "2024_T3.dta", "2024_T4.dta"
    ]
    
    download_path = "../output"
    
    print(f"\nConverting quarters to parquet for {len(failed_cohorts)} failed cohorts...")
    
    for cohort_num, start_i in failed_cohorts:
        i = int(start_i)
        cohort_number = int(cohort_num)
        
        print(f"\nConverting files for cohort {cohort_number} (quarters {i} to {i+4})...")
        
        # Convert the 5 quarters for this cohort
        for offset in range(5):
            quarter_file = cohort_list[i - 1 + offset]  # -1 for 0-indexing
            quarter_name = quarter_file.replace('.dta', '')
            
            input_path = f"{download_path}/{quarter_file}"
            output_path = f"{download_path}/{quarter_name}.parquet"
            
            # Skip if already converted
            if os.path.exists(output_path):
                print(f"  {quarter_name}.parquet already exists, skipping...")
                continue
            
            print(f"  Converting {quarter_name}...")
            df = pd.read_stata(input_path, convert_categoricals=False)
            df.to_parquet(output_path, engine="pyarrow")
            print(f"  ✓ Saved {quarter_name}.parquet")
    
    print("\nConversion complete!")

if __name__ == "__main__":
    main()