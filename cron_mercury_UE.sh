#!/bin/bash
###CRON lancer projet automatiquement
PATH_SCRIPT_DIR=/illumina/Pipeline_Production/Vador-v2/
PATH_SCRIPT_SKYWALKER=/illumina/Pipeline_Production/skywalker-v2/
source $PATH_SCRIPT_DIR/Parametres_vador.txt


# Env
PATH=/home/sbsuser/google-cloud-sdk/bin:/home/sge/bin:/home/sge/bin/lx-amd64:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/sge/bin/lx-amd64:/home/sbsuser/bin:/illumina/software/Pigz/:/illumina/software/:/illumina/software/Centos7Libs/:/illumina/software/Centos7Libs/bin/:/illumina/software/Centos7Libs/lib/:/illumina/software/Centos7Libs/include/:/illumina/software/Circos/bin/:/illumina/software/Bedops/bin:/illumina/software/fastx/bin:/illumina/software/sratoolkit.2.4.5-2-ubuntu64/bin/:/illumina/software/MACS-1.4.2/bin/:/illumina/software/WigToBigWig/:/illumina/software/Htslib/bin/:/illumina/software/Htslib/:/illumina/software/Homer/bin/:/illumina/software/Ghostscript/bin:/illumina/software/Weblogo:/illumina/software/Bcftools/bin:/illumina/software/Bcl2fastq/bin/:/illumina/software/bedtools2/bin:/illumina/software/Bowtie1/:/illumina/software/Bowtie2/:/illumina/software/Bwa/:/illumina/software/CoNIFER/:/illumina/software/Cufflinks:/illumina/software/VEP:/illumina/software/FastQC/:/illumina/software/Fastx/bin:/illumina/software/GATK:/illumina/software/Lncrscan/bin:/illumina/software/10X/longranger-2.2.2/:/illumina/software/10X/cellranger-6.0.0/:/illumina/software/10X/supernova-2.1.1/:/illumina/software/Manta/bin/:/illumina/software/Picard/:/illumina/software/Pindel:/illumina/software/Platypus/bin:/illumina/software/Primer3/src:/illumina/software/Prinseq/:/illumina/software/Plink:/illumina/software/Samtools/:/illumina/software/Tabix:/illumina/software/Tophat:/illumina/software/Vcftools/bin/:/illumina/software/SNAP/:/illumina/software/MACS2/bin/:/illumina/software/bs3/:/illumina/software/R-3.6.1/bin/:/illumina/software/Miniconda2/envs/MyPython3Env/bin/:/illumina/software/Miniconda2/envs/MyPython27Env/bin:/illumina/software/Miniconda2/envs/skywalker-v2/bin/:/illumina/software/BlatSuite/:/illumina/software/Seqtk/:/illumina/software/Sambamba/:/illumina/users/sguibert/Sambamba/:/illumina/software/Blastn/:/illumina/software/Trim_galore/:/illumina/software/BamReadcount/:/illumina/software/Dos2unix/:/illumina/software/Nano/bin/:/illumina/software/Repeatseq/bamtools/bin/:/illumina/software/Htop/bin:/illumina/software/Rsync/:/illumina/software/Repeatseq:/illumina/software/Git/bin/:/illumina/software/Pandoc-1.19.2.2/:/illumina/software/STAR/bin/Linux_x86_64/:/illumina/software/Gmap/util/:/illumina/software/Gmap/bin/:/illumina/software/sublime_text_3/:/illumina/software/phantomjs-2.1.1-linux-x86_64/bin/:/illumina/software/firefox/:/illumina/software/sdust/sdust-0.1/sdust:/illumina/software/GATK-4/gatk-4.beta.6/:/illumina/software/cgmaptools:/illumina/users/sguibert/Boost/lib:/illumina/users/sguibert/Boost/include:/illumina/users/sguibert/Boost/include/boost/:/illumina/users/sguibert/GSL/lib/:/illumina/users/sguibert/GSL/include:/illumina/software/shellcheck-stable.linux.x86_64/:/illumina/software/Csh/:/illumina/users/sguibert/rstudio-1.1.463/bin/

source /home/sbsuser/.bashrc
source /illumina/scripts/secrets_api.txt  
#faire une requete curl qui récupére les projets en statut 1 (attendre la route de Aurélie)
###recuperer les projet avec un statut 1

######recuperer le code d'authentification
authentification="$(curl -s -X POST \
  https://api-mercury.integragen.com/token \
  -H 'accept: application/json' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'postman-token: 52df101f-9802-b075-1346-8216998514d9' \
  -d "grant_type=password&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&username=$USERNAME&password=$PASSWORD")"


#récupérer le password
echo "Start Mercury API session"
password=$(echo "${authentification}" | grep -o '"access_token": *"[^"]*' | sed 's/"access_token": *"//')
echo "${password}"

#récupérer les informations du projet
Informations=$(curl -s -X POST \
  'https://api-mercury.integragen.com/api/analyzes/search' \
  -H 'accept: application/json' \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer '${password} \
  -H 'cache-control: no-cache'  \
  -H 'postman-token: c928afd2-81ba-e435-67ed-7302c586992a' \
  -d '{ 
    "skip": 0, 
    "take": 100, 
    "search": "", 
    "sortBy": [ 
        { 
            "id": "resultDate", 
            "desc": true 
        } 
    ], 
    "filters": { 
        "licence":1 , 
        "startDate": null, 
        "endDate": null, 
        "status":1 
    } 
    }') 
    
#récupérer les projets à lancer  avec le statut 1: fastq uploaded
echo $Informations
PROJECTS=`echo $Informations |jq '.analyzes[] | select(.status == 1 and .analyzes.captureKit != "OncoDEEP_kit") | .patient.nip ' | uniq | sort` 
#on retire les " si besoin
PROJECTS=$(echo "${PROJECTS}" | sed 's/"//g')
echo $PROJECTS
if [[ "$PROJECTS" != "" ]]; then
    echo "  All theses projects were got from Mercury: $PROJECTS"
    kits=""
    #ROJECTS="T1006 T1021"
    for project in $PROJECTS
    do
        echo $project
        ###s'occuper du bed du client
        #creation du projet onsite
        mkdir -p ${PATH_PROJECT_DIR}/${project}/BED

        #pour chaque projet récupérer les analyses à lancer qui sont en statut1
        NAME_ANALYSIS_LIST=`echo ${Informations} | jq '.analyzes[] | select(.patient.nip == "'${project}'") | .familyName '`
        NAME_ANALYSIS_LIST=$(echo "${NAME_ANALYSIS_LIST}" | sed 's/"//g')

        PATIENT_ID=$project
        echo $NAME_ANALYSIS_LIST
        for NAME_ANALYSIS in $NAME_ANALYSIS_LIST
        do
            #Récupréation id analysis : 
            id_analyse=`echo ${Informations} | jq '.analyzes[] | select(.familyName == "'$NAME_ANALYSIS'") | .id '`
            id_analyse=$(echo "${id_analyse}" | sed 's/"//g')

            echo $id_analyse
            #updaté leur statut en 2 pour ne pas les récupérer au procahin tour de cron
            #récupérer bed + BILANSAMPLE
            #~/gsutil/gsutil cp gs://skywalker-v2-rawdata/${project}/BILAN_SAMPLES_*_${NAME_ANALYSIS}.txt ${PATH_PROJECT_DIR}/${project}/
            gsutil cp gs://skywalker-v2-rawdata/${project}/BILAN_SAMPLES_*_${NAME_ANALYSIS}.txt ${PATH_PROJECT_DIR}/${project}/

            if [ ! -f ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES.txt ] ; then
                head -1 ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES_*_${NAME_ANALYSIS}.txt > ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES.txt
            fi
            cat ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES_*_${NAME_ANALYSIS}.txt | grep -v STATUT_SAMPLE >> ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES.txt
            mv ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES_*_${NAME_ANALYSIS}.txt ${PATH_PROJECT_DIR}/${project}/BED/

            python3 $PATH_SCRIPT_DIR/4.3.MERCURY/Update_status_analysis_Mercury_V2.py $project $NAME_ANALYSIS 2 --id_analysis $id_analyse


        done


        #check si kit existe dans bioinfstory et si non on l'insère
        colkit=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | head -1 | tr "\t" "\n" | grep -n KIT | cut -f1 -d ":"`
        KIT=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | cut -f$colkit | grep -v KIT | sort | uniq | sed 's/\.bed//g'`#

        colgenome=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | head -1 | tr "\t" "\n" | grep -n -w GENOME | cut -f1 -d ":"`
        genome=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | cut -f$colgenome | grep -v GENOME | sort | uniq`

        colgenome_kit=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | head -1 | tr "\t" "\n" | grep -n -w GENOME_bed | cut -f1 -d ":"`
        genome_kit=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | cut -f$colgenome_kit | grep -v GENOME_bed | sort | uniq`

        coluser=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | head -1 | tr "\t" "\n" | grep -n USER | cut -f1 -d ":"`
        provider=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | cut -f$coluser | grep -v USER | sort | uniq | sed "s/integragen//g" | sed "s/,//g"`
    
    
    


        ##Inserer le kit de capture au besoin, s il n existe pas
        if ! echo "$kits" | grep -q -w $KIT 
        then  
            if gsutil ls gs://skywalker-v2-rawdata/${PATIENT_ID}/BED/${KIT}.bed 
                then
                echo "bash $PATH_SCRIPT_DIR/UTILITIES/create_kit_files.sh ${project} $KIT $genome_kit $provider MERCURY X ${PATH_SCRIPT_DIR}"
                kits=$( echo "$kits $KIT" )
            else 
                echo "pas le bed du kit sur gs://skywalker-v2-rawdata/${PATIENT_ID}/BED/" 
            fi
       
        fi

        bash $PATH_SCRIPT_DIR/1.2.Implementation_Project/LaunchInmplementation_CLOUD_Ext.sh $project $PATH_SCRIPT_DIR UE $PATH_SCRIPT_SKYWALKER
   
    
    done
  echo "All Projects processed."
else
  echo "No projects got from Mercury"
fi

