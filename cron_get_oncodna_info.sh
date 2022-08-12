#!/bin/bash

PATH_SCRIPT_DIR=/illumina/Pipeline_Production/Vador-v2/
PATH_SCRIPT_SKYWALKER=/illumina/Pipeline_Production/skywalker-v2/
source $PATH_SCRIPT_DIR/Parametres_vador.txt

# recuperer dans le fichier
public_key=`cat /illumina/users/sblanchard/integragen-apicall.json | jq '.private_key_id' | sed "s/\"//g" `
private_key=`cat /illumina/users/sblanchard/integragen-apicall.json | jq '.private_key' | sed "s/\"//g"`

payload='{
  "iss": "integragen-apicall@mercury-kdm.iam.gserviceaccount.com",
  "aud": "https://oauth2.googleapis.com/token",
  "target_audience": "https://mercury-kdm-i25ia67qqa-ew.a.run.app"
}'
payload=$(
    echo "${payload}" | jq --arg time_str "$(date +%s)" \
    '
    ($time_str | tonumber) as $time_num
    | .iat=$time_num
    | .exp=($time_num + 3600)
    '
)

start=`echo $payload | jq '.iat'`
end=`echo $payload | jq '.exp'`
val=$(/illumina/software/Miniconda2/envs/MyPython3Env/bin/python3 ${PATH_SCRIPT_DIR}/Authentification_kdm_preprod.py "$public_key" "$private_key" "$start" "$end" 2>&1 | cut -f 2 -d "'")

password_tmp="$(curl --location --request POST 'https://oauth2.googleapis.com/token' \
--form 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer' \
--form 'assertion='${val})"

password=`echo $password_tmp | jq '.id_token' | sed "s/\"//g"`

Informations="$(curl -X GET \
  https://mercury-kdm-i25ia67qqa-ew.a.run.app/analyses \
  -H 'accept: application/json' \
  -H 'cache-control: no-cache' \
  -H 'authorization: Bearer '${password} \
  -H 'postman-token: c928afd2-81ba-e435-67ed-7302c586992a')"

# a remettre quand l'authentification est en place

# recupération des id des analyses avec le Status STARTED
 Analyse_To_Start=`echo $Informations |  jq '. [] | select (.status == "STARTED") | .id' | sed "s/\"//g"`

 for id in ${Analyse_To_Start} ; do
    mkdir -p ${PATH_PROJECT_DIR}/${id}/Rawdata/
    mkdir -p ${PATH_PROJECT_DIR}/${id}/BED/
    echo "Une nouvelle analyse pour OncoDNA est en cours : ${id}" | mail -s "OncoKDM Running" melanie.letexier@integragen.com steven.blanchard@integragen.com
    Information_id="$(curl -X GET \
      https://mercury-kdm-i25ia67qqa-ew.a.run.app/analyse/${id} \
      -H 'accept: application/json' \
      -H 'cache-control: no-cache' \
      -H 'authorization: Bearer '${password} \
      -H 'postman-token: c928afd2-81ba-e435-67ed-7302c586992a')"
      # a remettre quand l'authentification est en place
      ##-H 'authorization: Bearer '${password} \

    kit=`echo $Information_id |  jq '.kit.name' | sed "s/^\"//g" | sed "s/\"$/_KDM/g"`
    kit_file=`echo $Information_id |  jq '.kit.file' | sed "s/\"//g"`
    machine_tmp=`echo $Information_id |  jq '.kit.type' | sed "s/\"//g"`
    if [[ "${kit}" == *"ODDXv7"* ]] || [[ "${kit}" == *"ODDX@7"* ]] ; then
        kit="ODDXv7_report"
    fi
    if [ "${machine_tmp}" == "PCR" ] ; then
        machine="MiSeq"
    else
        machine="NovaSeq"
    fi
    gsutil cp gs://mercury-kdm-bedfiles/${kit_file} ${PATH_PROJECT_DIR}/${id}/BED/${kit}.bed

    gender=`echo $Information_id |  jq '.gender' | sed "s/\"//g"`
    genome=`echo $Information_id |  jq '.genome' | sed "s/\"//g"`
    genome_kit=`echo $Information_id |  jq '.kit.genome' | sed "s/\"//g"`
    constit_name=`echo $Information_id | jq '.samples[] | select (.type == "CONSTIT") | .name' | sed "s/\"//g"`
    tumor_name=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_DNA") | .name' | sed "s/\"//g"`
    rna_name=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_RNA") | .name' | sed "s/\"//g"`
    constit_pct_tum=`echo $Information_id | jq '.samples[] | select (.type == "CONSTIT") | .pct_tum' | sed "s/\"//g"`
    tumor_pct_tum=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_DNA") | .pct_tum' | sed "s/\"//g"`
    rna_pct_tum=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_RNA2") | .pct_tum' | sed "s/\"//g"`

    if [ -z "$constit_name" ] && [ -z "$rna_name" ] && [ ! -z "$tumor_name" ]  ; then
      analysis_name="PON_${tumor_name}"
      tumor_name_R1=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_DNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R1" | sort`
      tumor_name_R2=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_DNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R2" | sort`
      mkdir -p ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/
      gsutil cat ${tumor_name_R1} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/${tumor_name}_R1.fastq.gz
      gsutil cat ${tumor_name_R2} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/${tumor_name}_R2.fastq.gz

    elif [ -z "$constit_name" ] && [ ! -z "$rna_name" ] && [ ! -z "$tumor_name" ] ; then
      analysis_name="PON_${tumor_name}_${rna_name}"
      tumor_name_R1=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_DNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R1" | sort`
      tumor_name_R2=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_DNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R2" | sort`
      mkdir -p ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/
      gsutil cat ${tumor_name_R1} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/${tumor_name}_R1.fastq.gz
      gsutil cat ${tumor_name_R2} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/${tumor_name}_R2.fastq.gz
      rna_name_R1=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_RNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R1" | sort`
      rna_name_R2=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_RNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R2" | sort`
      mkdir -p ${PATH_PROJECT_DIR}/${id}/Rawdata/${rna_name}
      gsutil cat ${rna_name_R1} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${rna_name}/${rna_name}_R1.fastq.gz
      gsutil cat ${rna_name_R2} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${rna_name}/${rna_name}_R2.fastq.gz

    elif [ ! -z "$constit_name" ] && [ -z "$rna_name" ] && [ ! -z "$tumor_name" ] ; then
      analysis_name="${constit_name}_${tumor_name}"
      constit_name_R1=`echo $Information_id | jq '.samples[] | select (.type == "CONSTIT") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R1" | sort`
      constit_name_R2=`echo $Information_id | jq '.samples[] | select (.type == "CONSTIT") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R2" | sort`
      mkdir -p ${PATH_PROJECT_DIR}/${id}/Rawdata/${constit_name}
      gsutil cat ${constit_name_R1} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${constit_name}/${constit_name}_R1.fastq.gz
      gsutil cat ${constit_name_R2} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${constit_name}/${constit_name}_R2.fastq.gz
      tumor_name_R1=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_DNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R1" | sort`
      tumor_name_R2=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_DNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R2" | sort`
      mkdir -p ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/
      gsutil cat ${tumor_name_R1} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/${tumor_name}_R1.fastq.gz
      gsutil cat ${tumor_name_R2} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/${tumor_name}_R2.fastq.gz

    elif [ ! -z "$constit_name" ] && [ ! -z "$rna_name" ] && [ ! -z "$tumor_name" ] ; then
      analysis_name="${constit_name}_${tumor_name}_${rna_name}"
      constit_name_R1=`echo $Information_id | jq '.samples[] | select (.type == "CONSTIT") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R1" | sort`
      constit_name_R2=`echo $Information_id | jq '.samples[] | select (.type == "CONSTIT") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R2" | sort`
      mkdir -p ${PATH_PROJECT_DIR}/${id}/Rawdata/${constit_name}
      gsutil cat ${constit_name_R1} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${constit_name}/${constit_name}_R1.fastq.gz
      gsutil cat ${constit_name_R2} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${constit_name}/${constit_name}_R2.fastq.gz
      tumor_name_R1=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_DNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R1" | sort`
      tumor_name_R2=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_DNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R2" | sort`
      mkdir -p ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/
      gsutil cat ${tumor_name_R1} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/${tumor_name}_R1.fastq.gz
      gsutil cat ${tumor_name_R2} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${tumor_name}/${tumor_name}_R2.fastq.gz
      rna_name_R1=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_RNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R1" | sort`
      rna_name_R2=`echo $Information_id | jq '.samples[] | select (.type == "TUMOR_RNA") |.files[]' | sed "s/\"$//" | sed "s/^\"/gs:\/\/mercury-kdm-rawdata\//" | grep "_R2" | sort`
      mkdir -p ${PATH_PROJECT_DIR}/${id}/Rawdata/${rna_name}
      gsutil cat ${rna_name_R1} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${rna_name}/${rna_name}_R1.fastq.gz
      gsutil cat ${rna_name_R2} > ${PATH_PROJECT_DIR}/${id}/Rawdata/${rna_name}/${rna_name}_R2.fastq.gz

    else
        continue
    fi

    cp ${PATH_SCRIPT_DIR}/Modele_BILAN_Sample.txt ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt
    colSTATUT=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "STATUT_SAMPLE" | cut -f1 -d":"`
    colPATIENT=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "PATIENT_ID" | cut -f1 -d":"`
    colNAME_ID=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "NAME_ID" | cut -f1 -d":"`
    colANALYSE=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "NAME_ANALYSIS" | cut -f1 -d":"`
    colPATHOLOGY=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "PATHOLOGY" | cut -f1 -d":"`
    colGENDER=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "GENDER" | cut -f1 -d":"`
    colPCT_TUM=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "PCT_TUM" | cut -f1 -d":"`
    colkit=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "KIT" | cut -f1 -d":"`
    colUSER=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "USER" | cut -f1 -d":"`
    colTYPE=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "TYPE" | cut -f1 -d":"`
    colGENOME=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "GENOME" | cut -f1 -d":"`
    colFC=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "Num_FC" | cut -f1 -d":"`
    coltype_nuc=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -n "type_nuc" | cut -f1 -d":"`
    colCenter=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -w -n "Center" | cut -f1 -d":"`
    colMachine=`cat ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt | head -1 | tr '\t' '\n' | grep -w -n "MACHINE" | cut -f1 -d":"`

    if [ ! -z "$constit_name" ] ; then
        cp ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES2.txt
        echo "${constit_name}" >> ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES2.txt
        awk -F"\t" -v colPATIENT=$colPATIENT -v id=$id -v gender=$gender -v colGENDER=$colGENDER -v type="0" -v type_nuc="DNA" -v colNAME_ID=$colNAME_ID -v name=$constit_name -v constit_pct_tum=$constit_pct_tum -v colPCT_TUM=$colPCT_TUM -v colSTATUT=$colSTATUT -v colkit=$colkit -v kit=$kit -v analysis_name=$analysis_name -v colANALYSE=$colANALYSE -v colTYPE=$colTYPE -v coltype_nuc=$coltype_nuc -v genome="hg38" -v colGENOME=$colGENOME -v colFC=$colFC -v FC="X" -v colCenter=$colCenter -v colMachine=$colMachine -v machine=$machine '$1==name{$1="" ; $colUSER="OncoDNA" ; $colPATIENT=id; $colGENDER=gender ; $colSTATUT="In_Progress" ; $colNAME_ID=name ; $colkit=kit ; $colANALYSE=analysis_name ; $colTYPE=type ; $coltype_nuc=type_nuc ; $colGENOME=genome ; $colFC=FC ; $colCenter="OncoDNA" ; $colMachine=machine ; OFS="\t" ; print $0}' ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES2.txt >> ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt
    fi
    if [ ! -z "$tumor_name" ] ; then
        cp ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES2.txt
        echo "${tumor_name}" >> ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES2.txt
        awk -F"\t" -v colPATIENT=$colPATIENT -v id=$id -v gender=$gender -v colGENDER=$colGENDER -v type="1" -v type_nuc="DNA" -v colNAME_ID=$colNAME_ID -v name=$tumor_name -v constit_pct_tum=$constit_pct_tum -v colPCT_TUM=$colPCT_TUM -v colSTATUT=$colSTATUT -v colkit=$colkit -v kit=$kit -v analysis_name=$analysis_name -v colANALYSE=$colANALYSE -v colTYPE=$colTYPE -v coltype_nuc=$coltype_nuc -v genome="hg38" -v colGENOME=$colGENOME -v colFC=$colFC -v FC="X" -v colCenter=$colCenter -v colMachine=$colMachine -v machine=$machine '$1==name{$1="" ; $colUSER="OncoDNA" ; $colPATIENT=id; $colGENDER=gender ; $colSTATUT="In_Progress" ; $colNAME_ID=name ; $colkit=kit ; $colANALYSE=analysis_name ; $colTYPE=type ; $coltype_nuc=type_nuc ; $colGENOME=genome ; $colFC=FC ; $colCenter="OncoDNA" ; $colMachine=machine ; OFS="\t" ; print $0}' ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES2.txt >> ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt
    fi
    if [ ! -z "$rna_name" ] ; then
        cp ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES2.txt
        echo "${rna_name}" >> ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES2.txt
        awk -F"\t" -v colPATIENT=$colPATIENT -v id=$id -v gender=$gender -v colGENDER=$colGENDER -v type="2" -v type_nuc="RNA" -v colNAME_ID=$colNAME_ID -v name=$rna_name -v constit_pct_tum=$constit_pct_tum -v colPCT_TUM=$colPCT_TUM -v colSTATUT=$colSTATUT -v colkit=$colkit -v kit=$kit -v analysis_name=$analysis_name -v colANALYSE=$colANALYSE -v colTYPE=$colTYPE -v coltype_nuc=$coltype_nuc -v genome="hg38" -v colGENOME=$colGENOME -v colFC=$colFC -v FC="X" -v colCenter=$colCenter -v colMachine=$colMachine -v machine=$machine '$1==name{$1="" ; $colUSER="OncoDNA" ; $colPATIENT=id; $colGENDER=gender ; $colSTATUT="In_Progress" ; $colNAME_ID=name ; $colkit=kit ; $colANALYSE=analysis_name ; $colTYPE=type ; $coltype_nuc=type_nuc ; $colGENOME=genome ; $colFC=FC ; $colCenter="OncoDNA" ; $colMachine=machine ; OFS="\t" ; print $0}' ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES2.txt >> ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES.txt
    fi
    rm -f ${PATH_PROJECT_DIR}/${id}/BILAN_SAMPLES2.txt
    ##Inserer le kit de capture au besoin, s il n existe pas
    ##bash $PATH_SCRIPT_DIR/UTILITIES/create_kit_files.sh  ${id} $kit $genome_kit OncoDNA MERCURY X ${PATH_SCRIPT_DIR} 2 2

    public_key=`cat /illumina/users/sblanchard/integragen-apicall.json | jq '.private_key_id' | sed "s/\"//g" `
    private_key=`cat /illumina/users/sblanchard/integragen-apicall.json | jq '.private_key' | sed "s/\"//g"`

    payload='{
    "iss": "integragen-apicall@mercury-kdm.iam.gserviceaccount.com",
    "aud": "https://oauth2.googleapis.com/token",
    "target_audience": "https://mercury-kdm-i25ia67qqa-ew.a.run.app"
    }'
    payload=$(
    echo "${payload}" | jq --arg time_str "$(date +%s)" \
    '
    ($time_str | tonumber) as $time_num
    | .iat=$time_num
    | .exp=($time_num + 3600)
    '
    )

    start=`echo $payload | jq '.iat'`
    end=`echo $payload | jq '.exp'`
    val=$(condaPython3 ${PATH_SCRIPT_DIR}/Authentification_kdm_preprod.py "$public_key" "$private_key" "$start" "$end" 2>&1 | cut -f 2 -d "'")

    password_tmp="$(curl --location --request POST 'https://oauth2.googleapis.com/token' \
    --form 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer' \
    --form 'assertion='${val})"

    password=`echo $password_tmp | jq '.id_token' | sed "s/\"//g"`

    version_prod=`mysql -u bioinf_story -p'Mm9o7n%3' -h 35.189.196.194 bioinf_story -N -e "SELECT version FROM version_pipeline WHERE MERCURY=\"1\" and name=\"skywalker\""`

    taille=`mysql -u bioinf_story -p'Mm9o7n%3' -h 35.189.196.194 bioinf_story -N -e "SELECT size_kit_provider FROM kit WHERE name=\"${kit}\""`

    curl -X --location --request PUT https://mercury-kdm-i25ia67qqa-ew.a.run.app/analyse/${id} \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --header 'authorization: Bearer '${password} \
    --data-urlencode 'status=IN PROGRESS' \
    --data-urlencode 'kit_size='${taille} \
    --data-urlencode 'pipeline_version='${version_prod}

    bash $PATH_SCRIPT_DIR/1.2.Implementation_Project/LaunchInmplementation_KDM.sh $id $PATH_SCRIPT_DIR $PATH_SCRIPT_SKYWALKER



done
