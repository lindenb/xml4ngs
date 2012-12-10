# author
#    Pierre lindenbaum
# motivation:
#    fichier central pour 'Make'
#    indique les path vers les executables utilise en NGS
# date
#    2012-10-31
#
packages.dir=/commun/data/packages
JAVA=/usr/bin/java
GATK.jar=$(packages.dir)/GenomeAnalysisTK-2.1-13-g1706365/GenomeAnalysisTK.jar
GATK.jvm= -Xmx5g
GATK.flags=
gatk.bundle=/commun/data/pubdb/broadinstitute.org/bundle/1.5/b37
REF=$(gatk.bundle)/human_g1k_v37.fasta
samtools.dir=$(packages.dir)/samtools-0.1.18
SAMTOOLS=$(samtools.dir)/samtools 
BCFTOOLS=$(samtools.dir)/bcftools/bcftools
PICARD=$(packages.dir)/picard-tools-1.79
PICARD.jvm= -Xmx5g 
BEDTOOLS=$(packages.dir)/BEDTools-Version-2.16.2/bin
BWA=$(packages.dir)/bwa-0.6.2/bwa
VCFDBSNP=$(gatk.bundle)/dbsnp_135.b37.vcf.gz
SNPEFF=$(packages.dir)/snpEff_3_1
TABIX=$(packages.dir)/tabix-0.2.6
SQLITE3=sqlite3
VARKIT=$(packages.dir)/variationtoolkit
VEP.dir=$(packages.dir)/variant_effect_predictor
VEP.bin=$(VEP.dir)/variant_effect_predictor.pl
VEP.args=
VEP.cache=  --cache --dir /commun/data/pubdb/ensembl/vep/cache --write_cache
FASTX.dir=${packages.dir}/fastx_toolkit-0.0.13.2
HSQLDB.dir=${packages.dir}/hsqldb-2.2.9/hsqldb
HSQLDB.sqltool=${HSQLDB.dir}/lib/sqltool.jar
BOWTIE.dir=${packages.dir}/bowtie-0.12.8
BOWTIE2.dir=${packages.dir}/bowtie2-2.0.2
CUFFLINKS.dir=${packages.dir}/cufflinks-2.0.2.Linux_x86_64
TOPHAT.dir=${packages.dir}/tophat-2.0.6.Linux_x86_64
