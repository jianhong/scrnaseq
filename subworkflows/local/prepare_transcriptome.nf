//
// Uncompress and prepare reference genome files
//

include { UNTAR as UNTAR_TRANSCRIPTOME } from '../../modules/nf-core/modules/untar/main'
include {
    GUNZIP as GUNZIP_FASTA;
    GUNZIP as GUNZIP_GTF               } from '../../modules/nf-core/modules/gunzip/main'
include { GTF_FILTER                   } from '../../modules/local/gtf_filter'
include { CELLRANGER_MKGTF             } from '../../modules/local/cellranger/mkgtf/main'
include { CELLRANGER_MKREF             } from '../../modules/local/cellranger/mkref/main'

workflow PREPARE_TRANSCRITOME {
    main:
    ch_version = Channel.empty()

    ch_transcriptome = Channel.empty()
    if (params.transcriptome) {
        if (params.transcriptome.endsWith('.tar.gz') || params.transcriptome.endsWith('.tgz')) {
            ch_transcriptome = UNTAR_TRANSCRIPTOME([[id:'transcriptome'], file("${params.transcriptome}", checkIfExists: true)] )
                                    .untar.map{it[1]}
        } else {
            ch_transcriptome = file("${params.transcriptome}", checkIfExists: true)
        }
    } else {
        /*
         * Uncompress genome fasta file if required
         */
        if (params.fasta.endsWith('.gz')) {
            GUNZIP_FASTA ( [[id:'fasta'], file("${params.fasta}", checkIfExists: true)] )
            ch_fasta = GUNZIP_FASTA.out.gunzip.map{it[1]}
        } else {
            ch_fasta = file(params.fasta)
        }

        /*
         * Uncompress genome gtf file if required
         * GTF_FILTER is used to make sure the chromosome names in gtf file
         * keep consistent with fasta.
         */
        if (params.gtf.endsWith('.gz')) {
            GUNZIP_GTF ( [[id:'gtf'], file("${params.gtf}", checkIfExists: true)] )
            ch_gtf = GTF_FILTER(GUNZIP_GTF.out.gunzip.map{it[1]}, ch_fasta).filtered
        } else {
            ch_gtf = GTF_FILTER(file(params.gtf), ch_fasta).filtered
        }
        ch_version = ch_version.mix(GTF_FILTER.out.versions)

        /*
         * mkgtf
         */
        CELLRANGER_MKGTF(ch_gtf)
        ch_version = ch_version.mix(CELLRANGER_MKGTF.out.versions)

        /*
         * mkref
         */
        ch_transcriptome = CELLRANGER_MKREF(
                                ch_fasta,
                                CELLRANGER_MKGTF.out.gtf,
                                "cellranger_transcriptome"
                            ).reference
        ch_version = ch_version.mix(CELLRANGER_MKREF.out.versions)
    }

    emit:
    transcriptome = ch_transcriptome          // channel: [ [transcriptome] ]
    versions = ch_version                     // channel: [ versions.yml ]
}
