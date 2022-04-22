process CELLRANGER_COUNT {
    tag "$meta.gem"
    label 'process_high'

    if (params.enable_conda) {
        exit 1, "Conda environments cannot be used when using the Cell Ranger tool. Please use docker or singularity containers."
    }
    container "nfcore/cellranger:6.1.2"

    input:
    tuple val(meta), path(reads)
    path  reference

    output:
    path("sample-${meta.gem}/outs/*"), emit: outs
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    cellranger \\
        count \\
        --id='sample-${meta.gem}' \\
        --fastqs=$reads \\
        --transcriptome=$reference \\
        --sample=$meta.samples \\
        --localcores=$task.cpus \\
        --localmem=${task.memory.toGiga()} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellranger: \$(echo \$( cellranger --version 2>&1) | sed 's/^.*[^0-9]\\([0-9]*\\.[0-9]*\\.[0-9]*\\).*\$/\\1/' )
    END_VERSIONS
    """

    stub:
    """
    mkdir -p "sample-${meta.gem}/outs/"
    touch sample-${meta.gem}/outs/fake_file.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellranger: \$(echo \$( cellranger --version 2>&1) | sed 's/^.*[^0-9]\\([0-9]*\\.[0-9]*\\.[0-9]*\\).*\$/\\1/' )
    END_VERSIONS
    """
}
