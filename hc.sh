#!/bin/bash -login

### define resources needed:
### walltime - how long you expect the job to run
#PBS -l walltime=04:00:00

### nodes:ppn - how many nodes & cores per node (ppn) that you require
#PBS -l nodes=1:ppn=4

### mem: amount of memory that the job will need
#PBS -l mem=10gb

### you can give your job a name for easier identification
#PBS -N HC

#PBS -j oe
#PBS -t 0

MAXJOBID=49

### load necessary modules, e.g.
module load singularity

JOBSCRIPT=/mnt/home/jgallant/gatk4_bp_workflow/hc.sh

n=${PBS_ARRAYID}
zp_n=`printf "%04d\n" $n`

cd $PBS_O_WORKDIR
bn=`basename ${input_file}`
outd=${bn}_dir/shard-${n}/

mkdir -p ${outd}

singularity exec /mnt/home/jgallant/jasongallant-gatk_singularity-master.simg /gatk/gatk --java-options -Xms8000m \
  HaplotypeCaller \
  -R ${reference} \
  -I ${input_file} \
  -O ${outd}/${bn}.g.vcf.gz \
  -L interval-files-new/${zp_n}-scattered.intervals \
  -ip 100 \
  -contamination 0 \
  --max-alternate-alleles 3 \
  -ERC GVCF

  # Calculate next job to run
  NEXT=$(( $n + 1 ))

  #Check to see if next job is past the maximum job id
  if [ $NEXT -le $MAXJOBID ]
 then
         cd ${PBS_O_WORKDIR}
         qsub -t $NEXT -v reference=${reference},input_file=${input_file} $JOBSCRIPT
 fi

  #Check to see if this is the last job and email user
 if [ $n -eq $MAXJOBID ]
 then
         echo "." | mail -s "YOUR JOB ARRAY IS FINISHING" $USER@msu.edu
 fi

  #Print out the statistics for this job
  qstat -f $PBS_JOBID
