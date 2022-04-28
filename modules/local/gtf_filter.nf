process GTF_FILTER {
    tag "$gtf"
    label 'process_low'

    conda (params.enable_conda ? "conda-forge::coreutils=8.31" : null)
    container "${ workflow.containerEngine == 'singularity' &&
                    !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/coreutils:8.31--h14c3975_0' :
        'quay.io/biocontainers/coreutils:8.31--h14c3975_0' }"

    input:
    path gtf
    path fasta

    output:
    path "${prefix}.gtf", emit: filtered
    path "versions.yml" , emit: versions

    script:
    prefix   = task.ext.prefix ? "${task.ext.prefix}" : "${gtf.simpleName}.fil"
    """
    chroms=(\$(grep '>' genome.fa | sed -e 's/^>\\s*//'))
    function join_by { local IFS="\$1"; shift; echo "\$*"; }
    pattern=\$(join_by '|' \${chroms[@]})
    grep -E "^(\$pattern)\\s" genes.gtf > ${prefix}.gtf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        grep: \$(echo \$(grep --version 2>&1) | sed 's/[^0-9.]//g')
    END_VERSIONS
    """
}
