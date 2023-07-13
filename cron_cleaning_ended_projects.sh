#!/bin/bash
# start each Sunday 05:00 pm (Fr, 17h00) to avoid all flowcell demultiplexes
# master7 can't see buffer!

PATH_SCRIPT_DIR="/illumina/Utilities/cleaning_tools/"

source /home/sbsuser/.bashrc
source ${PATH_SCRIPT_DIR}/clean_Project_functions.sh
get_current_settings

# Sequenced in Evry's lab
## ARCHIVE, post Orbit 'Delayed'
echo "$(date --rfc-3339=ns) |BENE_INFO| Begin ARCHIVE clean_Projects_category.sh"
bash ${PATH_SCRIPT_DIR}/clean_Projects_category.sh ARCHIVE
echo "$(date --rfc-3339=ns) |BENE_INFO| End ARCHIVE clean_Projects_category.sh"

## CLINIQ, Oscar samples
echo "$(date --rfc-3339=ns) |BENE_INFO| CLINIC retrieval from Project_Finis"
for protocol in $(echo $sortedprotos | tr "," "\t"); do
    # retrieve Orbit Direct cleaned folders
    bash ${PATH_SCRIPT_DIR}/move_keywordprojects_into_destination.sh ^${protocol} /illumina/Projects/Project_Finis_CLINIQ/ /illumina/Projects/Project_Finis/
done
echo "$(date --rfc-3339=ns) |BENE_INFO| Begin CLINIQ clean_Projects_category.sh"
bash ${PATH_SCRIPT_DIR}/clean_Projects_category.sh CLINIQ
echo "$(date --rfc-3339=ns) |BENE_INFO| End CLINIQ clean_Projects_category.sh"

# Fastq given by clients: EXTernal Projects
echo "$(date --rfc-3339=ns) |BENE_INFO| Begin EXTernal clean_Projects_category.sh"
bash ${PATH_SCRIPT_DIR}/clean_Projects_category.sh EXT
echo "$(date --rfc-3339=ns) |BENE_INFO| End EXTernal clean_Projects_category.sh"


# Launch buffer transfers once everything is done as master7 can't see it, one after another : to limit parallel tasks
# let's do it simple: specify absolute paths and use set names
echo "$(date --rfc-3339=ns) |BENE_INFO| Begin ARCHIVE_transfer.sh"
myscript="/illumina/Projects/ARCHIVE/Logs/clean_Projects_category_ARCHIVE_transfer.sh"
myfolder="$(dirname $myscript)/"
qsub -cwd -v PATH -v LD_LIBRARY_PATH -N "Transfer_ARCHIVE" -q all.q -pe make 1 -e ${myfolder} -o ${myfolder} ${myscript}
echo "$(date --rfc-3339=ns) |BENE_INFO| End ARCHIVE_transfer.sh"

echo "$(date --rfc-3339=ns) |BENE_INFO| Begin CLINIQ_transfer.sh"
myscript="/illumina/Projects/Project_Finis_CLINIQ/Logs/clean_Projects_category_CLINIQ_transfer.sh"
myfolder="$(dirname $myscript)/"
qsub -cwd -v PATH -v LD_LIBRARY_PATH -N "Transfer_CLINIQ" -hold_jid "Transfer_ARCHIVE" -q all.q -pe make 1 -e ${myfolder} -o ${myfolder} ${myscript}
echo "$(date --rfc-3339=ns) |BENE_INFO| End CLINIQ_transfer.sh"

echo "$(date --rfc-3339=ns) |BENE_INFO| Begin EXT_transfer.sh"
myscript="/illumina/Projects/Project_Finis_EXT/Logs/clean_Projects_category_EXT_transfer.sh"
myfolder="$(dirname $myscript)/"
qsub -cwd -v PATH -v LD_LIBRARY_PATH -N "Transfer_EXT" -hold_jid "Transfer_CLINIQ" -q all.q -pe make 1 -e ${myfolder} -o ${myfolder} ${myscript}
echo "$(date --rfc-3339=ns) |BENE_INFO| End EXT_transfer.sh"
