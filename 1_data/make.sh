#!/bin/bash   

# Trap to handle shell script errors 
trap 'error_handler' ERR
error_handler() {
    error_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "\n\033[0;31mWarning\033[0m: make.sh failed at ${error_time}. Check above for details." # display warning in terminal
    exit 1 # early exit with error code
}

# Set paths
# (Make sure REPO_ROOT is set to point to the root of the repository!)
MAKE_SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(cd "$MAKE_SCRIPT_DIR/../" && pwd -P)"
MODULE=$(basename "$MAKE_SCRIPT_DIR")
LOGFILE="${MAKE_SCRIPT_DIR}/output/make.log"

# Check setup
source "${REPO_ROOT}/lib/shell/check_setup.sh"

# Tell user what we're doing
echo -e "\n\nMaking module \033[35m${MODULE}\033[0m with shell ${SHELL}"

# Load settings & tools
source "${REPO_ROOT}/local_env.sh"
source "${REPO_ROOT}/lib/shell/run_shell.sh"
source "${REPO_ROOT}/lib/shell/run_R.sh"

# Clear output directory
# (Guarantees that all output is produced from a clean run of the code)
rm -rf "${MAKE_SCRIPT_DIR}/output"
mkdir -p "${MAKE_SCRIPT_DIR}/output"

# Add symlink input files to local /input/ directory
# (Make sure get_inputs.sh is updated to pull in all needed input files!)
(   cd ${MAKE_SCRIPT_DIR}
    source "${MAKE_SCRIPT_DIR}/get_inputs.sh"
)

# Run scripts
# (Do this in a subshell so we return to the original working directory
# after scripts are run)
 echo -e "\nmake.sh started at $(date '+%Y-%m-%d %H:%M:%S')"

(
cd "${MAKE_SCRIPT_DIR}/source"

YEARS=({2007..2024})
QUARTERS=(T1 T2 T3 T4)

for year in "${YEARS[@]}"; do
  for quarter in "${QUARTERS[@]}"; do
    echo -e "\nProcessing ${year} ${quarter}..."
    run_R make_quarterly_enoe.r "${LOGFILE}" "$year" "$quarter" || exit 1
    echo -e "\nFinished Processing ${year} ${quarter}..."
  done
done

for ((i=1; i<=315; i+=5)); do
  cohort_number=$(( (i-1) / 5 + 1))
  percent=$(( 100 * $cohort_number / 63 ))
  echo -e "\nProcessing cohort $cohort_number of 63 ... ($percent% done)"
  run_R make_cohorts_enoe.r "${LOGFILE}" "$i" || exit 1
  echo -e "\nFinished processing cohort $cohort_number of 63."
done
) || false

echo -e "\nmake.sh finished at $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOGFILE}"

