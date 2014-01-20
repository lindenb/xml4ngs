.PHONY:  all
SAMDIR=/commun/data/packages/samtools-0.1.19
BWA=/commun/data/packages/bwa-0.7.4/bwa

all: data/Makefile
	(cd data; make all) 

data/Makefile : data/reference.fa
	##(cd ..; ant dist/transformngsproject.jar )
	(cd data;  java -jar ../../dist/transformngsproject.jar -c ../../config/master.xml project.xml  ../../velocity/project2make.vm > Makefile)
	

data/reference.fa :
	mkdir -p data && \
	${SAMDIR}/samtools faidx "/commun/data/pubdb/broadinstitute.org/bundle/1.5/b37/human_g1k_v37.fasta" '17:7555097-7560856' > $@ && \
	${SAMDIR}/samtools faidx $@ && \
	${BWA} index $@
	${SAMDIR}/misc/wgsim -N 100000 $@  data/Sample1.F.fq  data/Sample1.R.fq > /dev/null && \
	${SAMDIR}/misc/wgsim -N 100000 $@  data/Sample1b.F.fq  data/Sample1b.R.fq > /dev/null && \
	${SAMDIR}/misc/wgsim -N 100000 $@  data/Sample2.F.fq  data/Sample2.R.fq > /dev/null  && \
	gzip --force --best  data/Sample1.F.fq  data/Sample1.R.fq  data/Sample2.F.fq  data/Sample2.R.fq data/Sample1b.F.fq  data/Sample1b.R.fq && \
	echo "<project>" > data/project.xml && \
	echo "<sample name='Sample1'><sequences><pair lane='1'><fastq index='1' path='Sample1.F.fq.gz'/><fastq index='2' path='Sample1.F.fq.gz'/></pair><pair lane='2'><fastq index='1' path='Sample1b.F.fq.gz'/><fastq index='2' path='Sample1b.F.fq.gz'/></pair></sequences></sample>" >> data/project.xml && \
	echo "<sample name='Sample2'><sequences><pair lane='1'><fastq index='1' path='Sample2.F.fq.gz'/><fastq index='2' path='Sample2.F.fq.gz'/></pair></sequences></sample>" >> data/project.xml && \
	echo "</project>" >> data/project.xml 
	
clean:
	rm -f data/reference.fa
	
