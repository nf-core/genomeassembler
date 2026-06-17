# nf-core/genomeassembler: Citations

## [nf-core](https://pubmed.ncbi.nlm.nih.gov/32055031/)

> Ewels PA, Peltzer A, Fillinger S, Patel H, Alneberg J, Wilm A, Garcia MU, Di Tommaso P, Nahnsen S. The nf-core framework for community-curated bioinformatics pipelines. Nat Biotechnol. 2020 Mar;38(3):276-278. doi: 10.1038/s41587-020-0439-x. PubMed PMID: 32055031.

## [Nextflow](https://pubmed.ncbi.nlm.nih.gov/28398311/)

> Di Tommaso P, Chatzou M, Floden EW, Barja PP, Palumbo E, Notredame C. Nextflow enables reproducible computational workflows. Nat Biotechnol. 2017 Apr 11;35(4):316-319. doi: 10.1038/nbt.3820. PubMed PMID: 28398311.

## Pipeline tools

### Preprocessing

- [lima](https://github.com/pacificbiosciences/barcoding/)

- [nanoq](https://github.com/esteinig/nanoq)

  > Steinig and Coin (2022). Nanoq: ultra-fast quality control for nanopore reads. Journal of Open Source Software, 7(69), 2991, https://doi.org/10.21105/joss.02991

- [porechop](https://github.com/rrwick/Porechop)

  > Wick RR, Judd LM, Gorrie CL, Holt KE. Completing bacterial genome assemblies with multiplex MinION sequencing. Microb Genom. 2017;3(10):e000132. Published 2017 Sep 14. doi:10.1099/mgen.0.000132

- [TrimGalore](https://github.com/FelixKrueger/TrimGalore)

  > Felix Krueger, Frankie James, Phil Ewels, Ebrahim Afyounian, Michael Weinstein, Benjamin Schuster-Boeckler, Gert Hulselmans, & sclamons. (2023). FelixKrueger/TrimGalore. Zenodo. https://doi.org/10.5281/zenodo.7598955

### Assembly

- [hifiasm](https://github.com/chhylp123/hifiasm)

  > Cheng, H., Concepcion, G.T., Feng, X., Zhang, H., Li H. (2021) Haplotype-resolved de novo assembly using phased assembly graphs with hifiasm. Nat Methods, 18:170-175. https://doi.org/10.1038/s41592-020-01056-5

  > Cheng, H., Jarvis, E.D., Fedrigo, O., Koepfli, K.P., Urban, L., Gemmell, N.J., Li, H. (2022) Haplotype-resolved assembly of diploid genomes without parental data. Nature Biotechnology, 40:1332–1335. https://doi.org/10.1038/s41587-022-01261-x

  > Cheng, H., Asri, M., Lucas, J., Koren, S., Li, H. (2024) Scalable telomere-to-telomere assembly for diploid and polyploid genomes with double graph. Nat Methods, 21:967-970. https://doi.org/10.1038/s41592-024-02269-8

- [flye](https://github.com/mikolmogorov/Flye)

  > Mikhail Kolmogorov, Derek M. Bickhart, Bahar Behsaz, Alexey Gurevich, Mikhail Rayko, Sung Bong Shin, Kristen Kuhn, Jeffrey Yuan, Evgeny Polevikov, Timothy P. L. Smith and Pavel A. Pevzner "metaFlye: scalable long-read metagenome assembly using repeat graphs", Nature Methods, 2020 doi:10.1038/s41592-020-00971-x

  > Mikhail Kolmogorov, Jeffrey Yuan, Yu Lin and Pavel Pevzner, "Assembly of Long Error-Prone Reads Using Repeat Graphs", Nature Biotechnology, 2019 doi:10.1038/s41587-019-0072-8

  > Yu Lin, Jeffrey Yuan, Mikhail Kolmogorov, Max W Shen, Mark Chaisson and Pavel Pevzner, "Assembly of Long Error-Prone Reads Using de Bruijn Graphs", PNAS, 2016 doi:10.1073/pnas.1604560113

### Polishing

- [pilon](https://github.com/broadinstitute/pilon)

  > Bruce J. Walker, Thomas Abeel, Terrance Shea, Margaret Priest, Amr Abouelliel, Sharadha Sakthikumar, Christina A. Cuomo, Qiandong Zeng, Jennifer Wortman, Sarah K. Young, Ashlee M. Earl (2014) Pilon: An Integrated Tool for Comprehensive Microbial Variant Detection and Genome Assembly Improvement. PLoS ONE 9(11): e112963. doi:10.1371/journal.pone.0112963

- [medaka](https://github.com/nanoporetech/medaka)

### Scaffolding

- [LINKS](https://github.com/bcgsc/LINKS)

  > Warren RL, Yang C, Vandervalk BP, Behsaz B, Lagman A, Jones SJ, Birol I (2015) LINKS: Scalable, alignment-free scaffolding of draft genomes with long reads. Gigascience. 2015 Aug 4;4:35. doi: 10.1186/s13742-015-0076-3. eCollection 2015

- [longstitch](https://github.com/bcgsc/longstitch)

  > Coombe L, Li JX, Lo T, Wong J, Nikolic V, Warren RL and Birol I. LongStitch: high-quality genome assembly correction and scaffolding using long reads. BMC Bioinformatics 22, 534 (2021). https://doi.org/10.1186/s12859-021-04451-7

- [RagTag](https://github.com/malonge/RagTag)

  > Alonge, Michael, et al. "Automated assembly scaffolding elevates a new tomato system for high-throughput genome editing." Genome Biology (2022). https://doi.org/10.1186/s13059-022-02823-7

### Annotation liftover

- [liftoff](https://github.com/agshumate/Liftoff)

  > Shumate, Alaina, and Steven L. Salzberg. 2020. “Liftoff: Accurate Mapping of Gene Annotations.” Bioinformatics , December. https://doi.org/10.1093/bioinformatics/btaa1016

### Quality control

- [BUSCO](https://busco.ezlab.org/)

  > Mosè Manni, Matthew R Berkeley, Mathieu Seppey, Felipe A Simão, Evgeny M Zdobnov, BUSCO Update: Novel and Streamlined Workflows along with Broader and Deeper Phylogenetic Coverage for Scoring of Eukaryotic, Prokaryotic, and Viral Genomes. Molecular Biology and Evolution, Volume 38, Issue 10, October 2021, Pages 4647–4654

- [genomescope2](https://github.com/tbenavi1/genomescope2.0)

  > Ranallo-Benavidez, T.R., Jaron, K.S. & Schatz, M.C. GenomeScope 2.0 and Smudgeplot for reference-free profiling of polyploid genomes. Nature Communications 11, 1432 (2020). https://doi.org/10.1038/s41467-020-14998-3

  > Vurture, GW, Sedlazeck, FJ, Nattestad, M, Underwood, CJ, Fang, H, Gurtowski, J, Schatz, MC (2017) Bioinformatics doi: https://doi.org/10.1093/bioinformatics/btx153

- [jellyfish](https://github.com/gmarcais/Jellyfish)

  > Guillaume Marcais and Carl Kingsford, A fast, lock-free approach for efficient parallel counting of occurrences of k-mers. Bioinformatics (2011) 27(6): 764-770 doi:10.1093/bioinformatics/btr011

- [meryl](https://github.com/marbl/meryl) and [merqury](https://github.com/marbl/merqury)

  > Rhie, A., Walenz, B.P., Koren, S. et al. Merqury: reference-free quality, completeness, and phasing assessment for genome assemblies. Genome Biol 21, 245 (2020). https://doi.org/10.1186/s13059-020-02134-9

- [QUAST](https://github.com/ablab/quast)

  > Alexey Gurevich, Vladislav Saveliev, Nikolay Vyahhi and Glenn Tesler, QUAST: quality assessment tool for genome assemblies, Bioinformatics (2013) 29 (8): 1072-1075. doi: 10.1093/bioinformatics/btt086

### Mapping

- [minimap2](https://github.com/lh3/minimap2)

> Li, H. (2018). Minimap2: pairwise alignment for nucleotide sequences. Bioinformatics, 34:3094-3100. doi:10.1093/bioinformatics/bty191

> Li, H. (2021). New strategies to improve minimap2 alignment accuracy. Bioinformatics, 37:4572-4574. doi:10.1093/bioinformatics/btab705>

- [samtools](https://github.com/samtools/samtools)

> Petr Danecek, James K Bonfield, Jennifer Liddle, John Marshall, Valeriu Ohan, Martin O Pollard, Andrew Whitwham, Thomas Keane, Shane A McCarthy, Robert M Davies, Heng Li (2021) Twelve years of SAMtools and BCFtools. GigaScience, Volume 10, Issue 2, February 2021, giab008, https://doi.org/10.1093/gigascience/giab008

## Software packaging/containerisation tools

- [Anaconda](https://anaconda.com)

  > Anaconda Software Distribution. Computer software. Vers. 2-2.4.0. Anaconda, Nov. 2016. Web.

- [Bioconda](https://pubmed.ncbi.nlm.nih.gov/29967506/)

  > Grüning B, Dale R, Sjödin A, Chapman BA, Rowe J, Tomkins-Tinch CH, Valieris R, Köster J; Bioconda Team. Bioconda: sustainable and comprehensive software distribution for the life sciences. Nat Methods. 2018 Jul;15(7):475-476. doi: 10.1038/s41592-018-0046-7. PubMed PMID: 29967506.

- [BioContainers](https://pubmed.ncbi.nlm.nih.gov/28379341/)

  > da Veiga Leprevost F, Grüning B, Aflitos SA, Röst HL, Uszkoreit J, Barsnes H, Vaudel M, Moreno P, Gatto L, Weber J, Bai M, Jimenez RC, Sachsenberg T, Pfeuffer J, Alvarez RV, Griss J, Nesvizhskii AI, Perez-Riverol Y. BioContainers: an open-source and community-driven framework for software standardization. Bioinformatics. 2017 Aug 15;33(16):2580-2582. doi: 10.1093/bioinformatics/btx192. PubMed PMID: 28379341; PubMed Central PMCID: PMC5870671.

- [Docker](https://dl.acm.org/doi/10.5555/2600239.2600241)

  > Merkel, D. (2014). Docker: lightweight linux containers for consistent development and deployment. Linux Journal, 2014(239), 2. doi: 10.5555/2600239.2600241.

- [Singularity](https://pubmed.ncbi.nlm.nih.gov/28494014/)

  > Kurtzer GM, Sochat V, Bauer MW. Singularity: Scientific containers for mobility of compute. PLoS One. 2017 May 11;12(5):e0177459. doi: 10.1371/journal.pone.0177459. eCollection 2017. PubMed PMID: 28494014; PubMed Central PMCID: PMC5426675.

- [charliecloud](https://hpc.github.io/charliecloud/)

  > Reid Priedhorsky and Tim Randles. “Charliecloud: Unprivileged containers for user-defined software stacks in HPC”, 2017. In Proc. Supercomputing. DOI: 10.1145/3126908.3126925.
