#!/bin/bash
###CRON lancer projet automatiquement
PATH_SCRIPT_DIR=/illumina/Pipeline_Production/Vador-v2/ ;
PATH_SCRIPT_SKYWALKER=/illumina/Pipeline_Production/skywalker-v2/ ;
source $PATH_SCRIPT_DIR/Parametres_vador.txt ;

# Env
PATH=/home/sge/bin:/home/sge/bin/lx-amd64:/home/sbsuser/.vscode-server/bin/5235c6bb189b60b01b1f49062f4ffa42384f8c91/bin/remote-cli:/home/sge/bin:/home/sge/bin/lx-amd64:/home/sbsuser/google-cloud-sdk/bin:/home/sge/bin:/home/sge/bin/lx-amd64:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/sge/bin/lx-amd64:/home/sbsuser/bin:/illumina/software/Pigz/:/illumina/software/:/illumina/software/Centos7Libs/:/illumina/software/Centos7Libs/bin/:/illumina/software/Centos7Libs/lib/:/illumina/software/Centos7Libs/include/:/illumina/software/Circos/bin/:/illumina/software/Bedops/bin:/illumina/software/fastx/bin:/illumina/software/sratoolkit.2.4.5-2-ubuntu64/bin/:/illumina/software/MACS-1.4.2/bin/:/illumina/software/WigToBigWig/:/illumina/software/Htslib/bin/:/illumina/software/Htslib/:/illumina/software/Homer/bin/:/illumina/software/Ghostscript/bin:/illumina/software/Weblogo:/illumina/software/Bcftools/bin:/illumina/software/Bcl2fastq/bin/:/illumina/software/bedtools2/bin:/illumina/software/Bowtie1/:/illumina/software/Bowtie2/:/illumina/software/Bwa/:/illumina/software/CoNIFER/:/illumina/software/Cufflinks:/illumina/software/VEP:/illumina/software/FastQC/:/illumina/software/Fastx/bin:/illumina/software/GATK:/illumina/software/Lncrscan/bin:/illumina/software/10X/longranger-2.2.2/:/illumina/software/10X/cellranger-7.0.1/:/illumina/software/10X/supernova-2.1.1/:/illumina/software/Manta/bin/:/illumina/software/Picard/:/illumina/software/Pindel:/illumina/software/Platypus/bin:/illumina/software/Primer3/src:/illumina/software/Prinseq/:/illumina/software/Plink:/illumina/software/Samtools/:/illumina/software/Tabix:/illumina/software/Tophat:/illumina/software/Vcftools/bin/:/illumina/software/SNAP/:/illumina/software/MACS2/bin/:/illumina/software/bs3/:/illumina/software/R-3.6.1/bin/:/illumina/software/Miniconda2/envs/MyPython3Env/bin/:/illumina/software/Miniconda2/envs/MyPython27Env/bin:/illumina/software/Miniconda2/envs/skywalker-v2/bin/:/illumina/software/BlatSuite/:/illumina/software/Seqtk/:/illumina/software/Sambamba/:/illumina/users/sguibert/Sambamba/:/illumina/software/Blastn/:/illumina/software/Trim_galore/:/illumina/software/BamReadcount/:/illumina/software/Dos2unix/:/illumina/software/Nano/bin/:/illumina/software/Repeatseq/bamtools/bin/:/illumina/software/Htop/bin:/illumina/software/Rsync/:/illumina/software/Repeatseq:/illumina/software/Git/bin/:/illumina/software/Pandoc-1.19.2.2/:/illumina/software/STAR/bin/Linux_x86_64/:/illumina/software/Gmap/util/:/illumina/software/Gmap/bin/:/illumina/software/sublime_text_3/:/illumina/software/phantomjs-2.1.1-linux-x86_64/bin/:/illumina/software/firefox/:/illumina/software/sdust/sdust-0.1/sdust:/illumina/software/GATK-4/gatk-4.beta.6/:/illumina/software/cgmaptools:/illumina/users/sguibert/Boost/lib:/illumina/users/sguibert/Boost/include:/illumina/users/sguibert/Boost/include/boost/:/illumina/users/sguibert/GSL/lib/:/illumina/users/sguibert/GSL/include:/illumina/software/shellcheck-stable.linux.x86_64/:/illumina/software/Csh/:/illumina/users/sguibert/rstudio-1.1.463/bin/:/home/sge/bin/lx-amd64:/home/sbsuser/bin:/illumina/software/Pigz/:/illumina/software/:/illumina/software/Centos7Libs/:/illumina/software/Centos7Libs/bin/:/illumina/software/Centos7Libs/lib/:/illumina/software/Centos7Libs/include/:/illumina/software/Circos/bin/:/illumina/software/Bedops/bin:/illumina/software/fastx/bin:/illumina/software/sratoolkit.2.4.5-2-ubuntu64/bin/:/illumina/software/MACS-1.4.2/bin/:/illumina/software/WigToBigWig/:/illumina/software/Htslib/bin/:/illumina/software/Htslib/:/illumina/software/Homer/bin/:/illumina/software/Ghostscript/bin:/illumina/software/Weblogo:/illumina/software/Bcftools/bin:/illumina/software/Bcl2fastq/bin/:/illumina/software/bedtools2/bin:/illumina/software/Bowtie1/:/illumina/software/Bowtie2/:/illumina/software/Bwa/:/illumina/software/CoNIFER/:/illumina/software/Cufflinks:/illumina/software/VEP:/illumina/software/FastQC/:/illumina/software/Fastx/bin:/illumina/software/GATK:/illumina/software/Lncrscan/bin:/illumina/software/10X/longranger-2.2.2/:/illumina/software/10X/cellranger-7.0.1/:/illumina/software/10X/supernova-2.1.1/:/illumina/software/Manta/bin/:/illumina/software/Picard/:/illumina/software/Pindel:/illumina/software/Platypus/bin:/illumina/software/Primer3/src:/illumina/software/Prinseq/:/illumina/software/Plink:/illumina/software/Samtools/:/illumina/software/Tabix:/illumina/software/Tophat:/illumina/software/Vcftools/bin/:/illumina/software/SNAP/:/illumina/software/MACS2/bin/:/illumina/software/bs3/:/illumina/software/R-3.6.1/bin/:/illumina/software/Miniconda2/envs/MyPython3Env/bin/:/illumina/software/Miniconda2/envs/MyPython27Env/bin:/illumina/software/Miniconda2/envs/skywalker-v2/bin/:/illumina/software/BlatSuite/:/illumina/software/Seqtk/:/illumina/software/Sambamba/:/illumina/users/sguibert/Sambamba/:/illumina/software/Blastn/:/illumina/software/Trim_galore/:/illumina/software/BamReadcount/:/illumina/software/Dos2unix/:/illumina/software/Nano/bin/:/illumina/software/Repeatseq/bamtools/bin/:/illumina/software/Htop/bin:/illumina/software/Rsync/:/illumina/software/Repeatseq:/illumina/software/Git/bin/:/illumina/software/Pandoc-1.19.2.2/:/illumina/software/STAR/bin/Linux_x86_64/:/illumina/software/Gmap/util/:/illumina/software/Gmap/bin/:/illumina/software/sublime_text_3/:/illumina/software/phantomjs-2.1.1-linux-x86_64/bin/:/illumina/software/firefox/:/illumina/software/sdust/sdust-0.1/sdust:/illumina/software/GATK-4/gatk-4.beta.6/:/illumina/software/cgmaptools:/illumina/users/sguibert/Boost/lib:/illumina/users/sguibert/Boost/include:/illumina/users/sguibert/Boost/include/boost/:/illumina/users/sguibert/GSL/lib/:/illumina/users/sguibert/GSL/include:/illumina/software/shellcheck-stable.linux.x86_64/:/illumina/software/Csh/:/illumina/users/sguibert/rstudio-1.1.463/bin/:/home/sge/bin/lx-amd64 ;
source /home/sbsuser/.bashrc ;

#faire une requete curl qui r??cup??re les projets en statut 1 (attendre la route de Aur??lie)
###recuperer les projet avec un statut 1
Informations=`ssh -n sbsuser@130.211.104.146 "/opt/bitnami/php/bin/php /opt/bitnami/apache2/htdocs/bin/console app:project-statut-fastq-uploaded"` ;
echo "$(date --rfc-3339=ns) |INFO| Informations = $Informations" ;

PROJECTS=$(echo "$Informations" | jq -r '.[0] | .nom') || echo "$(date --rfc-3339=ns) |ERROR| New strategy failed" ;

echo "$(date --rfc-3339=ns) |INFO| PROJECTS = $PROJECTS" ;
if [ ! -z "$PROJECTS"]; then 
    echo "$(date --rfc-3339=ns) |INFO| All theses projects were got from Sirius: $PROJECTS" ;
    for project in "${PROJECTS[0]}" ;
    do
        echo "$(date --rfc-3339=ns) |INFO| Working on $project ..." ;
        ###s'occuper du bed du client
        #creation du projet onsite
        echo "$(date --rfc-3339=ns) |INFO| Workdir creation" ;
        mkdir -p ${PATH_PROJECT_DIR}/${project}/BED || echo "$(date --rfc-3339=ns) |ERROR| Workdir creation failed" ;

        #pour chaque projet r??cup??rer les analyses ?? lancer qui sont en statut1
        #updat?? leur statut en 2 pour ne pas les r??cup??rer au procahin tour de cron
        #r??cup??rer bed + BILANSAMPLE
        #~/gsutil/gsutil cp gs://skywalker-v2-rawdata/${project}/BILAN_SAMPLES_*_${NAME_ANALYSIS}.txt ${PATH_PROJECT_DIR}/${project}/
        echo "$(date --rfc-3339=ns) |INFO| Fetching BILAN_SAMPLES from skywalker-v2-rawdata" ;
        gsutil cp gs://skywalker-v2-rawdata/${project}/BILAN_SAMPLES_${project}.txt ${PATH_PROJECT_DIR}/${project}/ || echo "$(date --rfc-3339=ns) |ERROR| Bilan fetch fail" ;
        echo "$(date --rfc-3339=ns) |INFO| Fetched BILAN_SAMPLES from skywalker-v2-rawdata" ;

        if [ ! -f ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES.txt ] ; then
            head -1 ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES_${project}.txt > ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES.txt ;
        fi
        cat ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES_${project}.txt | grep -v STATUT_SAMPLE >> ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES.txt ;
        mv ${PATH_PROJECT_DIR}/${project}/BILAN_SAMPLES_${project}.txt ${PATH_PROJECT_DIR}/${project}/BED/ ;

        #check si kit existe dans bioinfstory et si non on l'ins??re
        colkit=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | head -1 | tr "\t" "\n" | grep -n KIT | cut -f1 -d ":"` ;
        KIT=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | cut -f$colkit | grep -v KIT | sort | uniq | sed 's/\.bed//g'` ;

        colgenome=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | head -1 | tr "\t" "\n" | grep -n GENOME_bed | cut -f1 -d ":"` ;
        genome=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | cut -f$colgenome | grep -v GENOME_bed | sort | uniq` ;

        coluser=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | head -1 | tr "\t" "\n" | grep -n USER | cut -f1 -d ":"` ;
        provider=`cat ${PATH_PROJECT_DIR}/$project/BILAN_SAMPLES.txt | cut -f$coluser | grep -v USER | sort | uniq | sed "s/integragen//g" | sed "s/,//g"` ;

        echo "$(date --rfc-3339=ns) |INFO| colkit = $colkit ; KIT = $KIT ; colgenome = $colgenome ; coluser = $coluser ; provider = $provider" ;

        # cr??er le kit hg38 si besoin et surtout copie le nouveau kit dans le bucket
        echo "$(date --rfc-3339=ns) |INFO| Begin create_kit_files.sh" ;
        bash $PATH_SCRIPT_DIR/UTILITIES/create_kit_files.sh  ${project} $KIT $genome $provider SIRIUS X ${PATH_SCRIPT_DIR} || echo "$(date --rfc-3339=ns) |ERROR| create_kit_files.sh fail" ;
        echo "$(date --rfc-3339=ns) |INFO| End create_kit_files.sh" ;

        ##updater le statut de l'analyse en 2 poru dire analyse In Progress
        echo "$(date --rfc-3339=ns) |INFO| Begin Status Update to 2" ;
        ssh -n sbsuser@130.211.104.146 "/opt/bitnami/php/bin/php /opt/bitnami/apache2/htdocs/bin/console app:update-statut-projet '${project}' '2'" || echo "$(date --rfc-3339=ns) |ERROR| Status 2 Fail" ;
        echo "$(date --rfc-3339=ns) |INFO| End Status Update to 2" ;
        ##updater le nom du comercial pour le projet en question
        echo "$(date --rfc-3339=ns) |INFO| Begin Commercial name update" ;
        ssh -n sbsuser@130.211.104.146 "/opt/bitnami/php/bin/php /opt/bitnami/apache2/htdocs/bin/console app:update-email-commercial '${project}' 'jeanmarc.robitaille@integragen.com'" || echo "$(date --rfc-3339=ns) |ERROR| Commercial name fail" ;
        echo "$(date --rfc-3339=ns) |INFO| End Commercial name update" ;

        #####Faire le lien entre eris3 et le pwd pour que le lien du Reporting existe
        #php bin/console app:update-password-reporting ${project} motDePasseReporting fromPipeline
        echo "$(date --rfc-3339=ns) |INFO| Begin LaunchInmplementation_CLOUD_Ext.sh" ;
        bash $PATH_SCRIPT_DIR/1.2.Implementation_Project/LaunchInmplementation_CLOUD_Ext.sh $project $PATH_SCRIPT_DIR UE $PATH_SCRIPT_SKYWALKER || echo "$(date --rfc-3339=ns) |ERROR| LaunchImplementation_CLOUD_Ext.sh fail" ;
        echo "$(date --rfc-3339=ns) |INFO| End LaunchInmplementation_CLOUD_Ext.sh" ;
    done
    echo "$(date --rfc-3339=ns) |INFO| All Projects processed." ;
else
    echo "$(date --rfc-3339=ns) |INFO| No projects got from Sirius" ;
fi
