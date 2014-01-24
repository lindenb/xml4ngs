.PHONY:  all fastqs compile test1
SAMDIR=/commun/data/packages/samtools-0.1.19
BWA=/commun/data/packages/bwa-0.7.4/bwa
FASTQS=  	 data/fastq/Sample1_ACAGTG_L001_R1_001.fastq.gz \
		 data/fastq/Sample1_ACAGTG_L001_R2_001.fastq.gz \
		 data/fastq/Sample1_ACAGTG_L001_R1_002.fastq.gz \
		 data/fastq/Sample1_ACAGTG_L001_R2_002.fastq.gz \
		 data/fastq/Sample1_ACAGTG_L002_R1_002.fastq.gz \
		 data/fastq/Sample1_ACAGTG_L002_R2_002.fastq.gz \
		 data/fastq/Sample2_ACAGTG_L003_R1_001.fastq.gz \
		 data/fastq/Sample2_ACAGTG_L003_R2_001.fastq.gz
NREADS=10000
SHELL=/bin/bash

all: test3 test2 test1

test1: ${FASTQS} data/capture.bed compile
	java -jar ../dist/ilmn2project.jar -f settings01.xml ${PWD}/data/fastq | xmllint --format - > data/project.xml
	(cd data;  java -jar ../../dist/transformngsproject.jar -c ../../config/master.xml project.xml  ../../velocity/project2make.vm > Makefile)
	(cd data; make all) 

test2: ${FASTQS} data/capture.bed compile
	java -jar ../dist/ilmn2project.jar -f settings02.xml ${PWD}/data/fastq | xmllint --format - > data/project.xml
	(cd data;  java -jar ../../dist/transformngsproject.jar -c ../../config/master.xml project.xml  ../../velocity/project2make.vm > Makefile)
	(cd data; make all) 

test3: ${FASTQS} data/capture.bed compile
	java -jar ../dist/ilmn2project.jar -f settings03.xml ${PWD}/data/fastq | xmllint --format - > data/project.xml
	(cd data;  java -jar ../../dist/transformngsproject.jar -c ../../config/master.xml project.xml  ../../velocity/project2make.vm > Makefile)
	(cd data; make all) 

compile:
	(cd ..; ant dist/ilmn2project.jar dist/transformngsproject.jar )
	
fastqs : ${FASTQS}

${FASTQS}: data/reference.fa
	mkdir -p data/fastq && \
	${SAMDIR}/misc/wgsim -N ${NREADS} $<  data/fastq/Sample1_ACAGTG_L001_R1_001.fastq data/fastq/Sample1_ACAGTG_L001_R2_001.fastq > /dev/null && \
	${SAMDIR}/misc/wgsim -N ${NREADS} $<  data/fastq/Sample1_ACAGTG_L001_R1_002.fastq data/fastq/Sample1_ACAGTG_L001_R2_002.fastq > /dev/null && \
	${SAMDIR}/misc/wgsim -N ${NREADS} $<  data/fastq/Sample1_ACAGTG_L002_R1_002.fastq data/fastq/Sample1_ACAGTG_L002_R2_002.fastq > /dev/null && \
	${SAMDIR}/misc/wgsim -N ${NREADS} $<  data/fastq/Sample2_ACAGTG_L003_R1_001.fastq data/fastq/Sample2_ACAGTG_L003_R2_001.fastq > /dev/null  && \
	gzip --force --best  data/fastq/*.fastq


data/reference.fa :
	mkdir -p data && \
	${SAMDIR}/samtools faidx "/commun/data/pubdb/broadinstitute.org/bundle/1.5/b37/human_g1k_v37.fasta" '17:7555097-7560856' > $@ && \
	${SAMDIR}/samtools faidx $@ && \
	${BWA} index $@

data/capture.bed:
	mkdir -p data && \
	echo "17	7555097	7560856" > $@
	echo "1	7555097	7560856" >> $@

clean:
	rm -rf data/reference.fa align1 align2 align3
	
