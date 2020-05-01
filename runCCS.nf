#!/usr/bin/env nextflow

/*
 * Defines the pipeline inputs parameters (giving a default value for each for them)
 * Each of the following parameters can be specified as command line options
 */

//REQUIRED --outDir "s3://ccstest/subDir/" --subreads "s3://ccstest/subDir/*.{bam,bam.pbi}"

//# Steps of cloud setup and operation:
//# Create cloud
// nextflow cloud create -c 2 cloud9
//# SSH into master node (nextflow will provide the command line below, often have to wait 5 min before it will let you in):
// ssh -i "/Users/deansanders/.ssh/id_rsa" ec2-user@ec2-52-15-199-21.us-east-2.compute.amazonaws.com
//# Pull docker image
// docker pull sandmansdownfall/ccs3:latest
//# Mount EFS
// sudo mount -t efs fs-d064a4a8:/ /mnt/efs
// #join your cluster
// nextflow node -bg -cluster.join path:/mnt/efs
// nextflow node -bg -cluster.join ip:172.31.11.91,172.31.6.74,172.31.12.120
// #run nextflow command from home 
// ~/nextflow run -bg runCCS.nf -with-docker sandmansdownfall/ccs3:latest --outDir "s3://ccstest/subDir/" --subreads "s3://ccstest/subDir/*.{bam,bam.pbi}"
Channel
    .fromFilePairs( params.subreads ) 
    .set { subreads_ch }

process processCCS {
    container 'sandmansdownfall/ccs3:latest'
    publishDir path: params.outDir, mode: 'copy', overwrite: true

    input:
    set baseName, file(bampbi) from subreads_ch
    //file inputBam from subreads_ch.flatMap()
    
    output:
    set file('*.log'),file('*.ccs.bam'),file('*.ccs.report.txt') into publishDir 
    
    script:
    bam=bampbi[0]
    pbi=bampbi[1]
    """
    echo "bam is: ${bam} and pbi is: ${pbi}"

    #run CCS command
    #ccs version 4.2.0
    /home/miniconda/bin/ccs ${bam} ${baseName}.ccs.bam --log-level INFO --log-file ${baseName}.log --report-file ${baseName}.ccs.report.txt
    """

}
