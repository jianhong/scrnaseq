process AGAT {
    tag "$gtf"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::agat=0.8.0" : null)
    container "${ workflow.containerEngine == 'singularity' &&
                    !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sagat:0.8.0--pl5262hdfd78af_0' :
        'quay.io/biocontainers/agat:0.8.0--pl5262hdfd78af_0' }"

    input:
    path gtf
    path fasta

    output:
    path "${prefix}.gtf", emit: filtered
    path "versions.yml" , emit: versions

    script:
    prefix   = task.ext.prefix ? "${task.ext.prefix}" : "${gtf.simpleName}.fil"
    """
    agat_sq_filter_feature_from_fasta.pl \\
        --gff $gtf \\
        --fasta $fasta \\
        -o ${prefix}.gtf
    sed -i -e 's/;/; /g' ${prefix}.gtf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
