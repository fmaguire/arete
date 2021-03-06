// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process BLAST {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:meta.id + "/annotation/" + getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? 'bioconda::blast=2.10.1' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container 'https://depot.galaxyproject.org/singularity/blast:2.10.1--pl526he19e7b1_3'
    } else {
        container 'quay.io/biocontainers/blast:2.10.1--pl526he19e7b1_3'
    }

    input:
    tuple val(meta), path(fasta)
    path db
    val blast_type
    val label

    output:
    tuple val(meta), path('*.blastn.txt'), emit: txt
    path '*.version.txt'                 , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    $blast_type \\
        -num_threads $task.cpus \\
        -db $db \\
        -query $fasta \\
        $options.args \\
        -out ${prefix}.blastn.txt
    echo \$(blastn -version 2>&1) | sed 's/^.*blastn: //; s/ .*\$//' > ${software}.version.txt
    """
}
