<!--[![GitHub Actions CI Status](https://github.com/fmaguire/arete/workflows/nf-core%20CI/badge.svg)](https://github.com/fmaguire/arete/actions?query=workflow%3A%22nf-core+CI%22)-->
<!--[![GitHub Actions Linting Status](https://github.com/fmaguire/arete/workflows/nf-core%20linting/badge.svg)](https://github.com/fmaguire/arete/actions?query=workflow%3A%22nf-core+linting%22)-->
<!--[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)-->

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.03.0--edge-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)


![aretelogo](docs/images/arete_logo.png)

## Introduction

<!-- TODO nf-core: Write a 1-2 sentence summary of what data the pipeline is for and what it does -->
**ARETE** is a bioinformatics best-practice analysis pipeline for AMR/VF LGT-focused bacterial genomics workflow.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker / Singularity containers (although only conda and docker (sans mob-suite) have been tested so far) making installation trivial and results highly reproducible.
Like other workflow languages it provides [useful features](https://www.nextflow.io/docs/latest/getstarted.html#modify-and-resume) like `-resume` to only rerun tasks that haven't already been completed (e.g., allowing editing of inputs/tasks and recovery from crashes without a full re-run).
The [nf-core](https://nf-cor.re) project provided overall project template, pre-written software modules, and generally best practice recommendations.

<!-- TODO nf-core: Add full-sized test dataset and amend the paragraph below if applicable -->
On release, automated continuous integration tests run the pipeline on a full-sized dataset on the AWS cloud infrastructure. This ensures that the pipeline runs on AWS, has sensible resource allocation defaults set to run on real-world datasets, and permits the persistent storage of results to benchmark between pipeline releases and other analysis sources.

## Pipeline summary

<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

Read processing:
1. Raw Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Read Trimming ([`fastp`](https://github.com/OpenGene/fastp))
3. Trimmed Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
4. Taxonomic Profiling ([`kraken2`](http://ccb.jhu.edu/software/kraken2/))

Assembly:
1. Unicycler ([`unicycler`](https://github.com/rrwick/Unicycler))
2. QUAST QC ([`quast`](http://quast.sourceforge.net/))

Annotation:
1. Prokka ([`prokka`](https://github.com/tseemann/prokka))
2. AMR ([`RGI`](https://github.com/arpcard/rgi) and [`PATHRACER`](http://cab.spbu.ru/software/pathracer))
3. VF ([`abricate`](https://github.com/tseemann/abricate))
4. Metal Resistance ([`abricate`](https://github.com/tseemann/abricate))
5. Plasmids ([`mob_suite`](https://github.com/phac-nml/mob-suite))
6. CAZY query using DIAMOND ([`diamond`](https://github.com/bbuchfink/diamond))

Phylogeny:
1. snippy ([`snippy`](https://github.com/tseemann/snippy))
2. iqtree ([`iqtree`](http://www.iqtree.org/))

### Not Implemented

When a developer takes over this workflow the following issues are main out-standing
development requirements.

- Conda profile and docker profiles have been tested (docker is better if possible due to conda fragility). Singularity has not been (just auto-populated from nf-core usegalaxy paths mostly) so is unlikely to work. That said running docker containers in singularity should work but again has not been tested.
Currently mob-suite is the limiting factor in containerisation as it has occasional failures to install in conda and can't be run in a read-only container right now (see [1](https://github.com/phac-nml/mob-suite/issues/38), [2](https://github.com/phac-nml/mob-suite/issues/82)). If you have issues running the workflow as it currently is, use `-profile docker` and just comment out mob-suite [here](https://github.com/fmaguire/arete/blob/master/workflows/pipeline.nf#L164).

- Nf-core linting fixes done and added to github actions CI.

- Minimal test set added and added to github actions CI.

- Additional developed modules added to nf-core module repo.

- Possible switch to roary for pangenome phylogeny

- Consider updating to newer SPAdes as unicycler is dependent on an older version (and newer spades can integrate plasmidspades runs on the same assembly graph).

- Some processes download databases for convenience and "as needed" but given that some run environments don't have external internet access this will fail so these dependencies may need off-loaded to a `get_dbs.sh` script or a more elegant solution!

- Currently if user doesn't have `sendmail` configured, the workflow will throw an error on completion or failure when trying to send an email to the user, this needs handled more gracefully.

- All inputs for the multiQC report should be being fed to multiQC but it doesn't seem to be incorporating all of them in the report (e.g., QUAST/kraken2). This needs explored and fixed.

- User request to add optional reference gbk to refine prokka annotations.

- User request to add --metagenome mode.

- They largely weren't done due to being web or galaxy only tools or haven't been
conda/containerised obviously yet (CRISPRCaSFinder should be relatively easy).

1. Prophage identification (e.g., PHASTER)
2. Genomic Island Detection (e.g., IslandCompare)
3. ICE identification (e.g., ICEFinder)
4. Gain-loss Mapping (e.g., GLOOME)
5. Summary of results in various heatmaps etc

## Quick Start

1. Install [`nextflow`](https://nf-co.re/usage/installation)

2. Install [`Docker`](https://www.docker.com), [`Conda`](https://conda.io/miniconda.html), and ensure you have a working `curl` installed (should be present on almost all systems).
Note: this workflow should also support [`Docker`] [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) execution for full pipeline reproducibility. Ideally future development will minimise reliance on `conda`(see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles)). Configure `mail` on your system to send an email on workflow success/failure (without this you will get a small error at the end `Failed to invoke workflow.onComplete event handler` but this doesn't mean the workflow didn't finish successfully).

3. **NOT IMPLEMENTED SKIP TO 4** Download the pipeline and test it on a minimal dataset with a single command:

    ```bash
    nextflow run fmaguire/arete -profile test,<docker/conda>
    ```

    * Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.
    * If you are using `singularity` then the pipeline will auto-detect this and attempt to download the Singularity images directly as opposed to performing a conversion from Docker images. If you are persistently observing issues downloading Singularity images directly due to timeout or network issues then please use the `--singularity_pull_docker_container` parameter to pull and convert the Docker image instead.

3. Start running your own analysis (ideally using `-profile docker` for stability)!

    ```bash
    nextflow run fmaguire/arete -profile conda --input_sample_table samplesheet.csv --reference_genome efaecium_DO.fasta --outgroup_genome test/E_hirae_ATCC9790_GCF_000271405.2_ASM27140v2_genomic.fna 
    ```
`samplesheet.csv` must be formatted `sample,fastq_1,fastq_2`

If you have issues running the workflow with `-profile conda` due to mob-suite, use `-profile docker` and just comment out mob-suite [here](https://github.com/fmaguire/arete/blob/master/workflows/pipeline.nf#L164).  

**Note**: If you get this error at the end ```Failed to invoke `workflow.onComplete` event handler``` it isn't a problem, it just means you don't have an sendmail   configured and it can't send an email report saying it finished correctly i.e., its not that the workflow failed.

See [usage docs](https://github.com/fmaguire/arete/usage) for all of the available options when running the pipeline.

## Documentation

The ARETE pipeline comes with documentation about the pipeline: [usage](https://github.com/fmaguire/arete/usage) and [output](https://github.com/fmaguire/arete/output).

## Credits

ARETE was written by Finlay Maguire.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#arete` channel](https://nfcore.slack.com/channels/arete) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use  nf-core/arete for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
