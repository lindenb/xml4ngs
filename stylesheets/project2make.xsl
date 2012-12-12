<?xml version='1.0'  encoding="UTF-8" ?>

<xsl:stylesheet
	xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
	version='1.0'
	>


<xsl:output method="text" encoding="UTF-8"/>
<xsl:param name="limit"/>
<xsl:param name="fragmentsize">600</xsl:param>
<xsl:param name="bwathreads">1</xsl:param>


<xsl:template match="/">
<xsl:if test="number(project/properties/property[@key='simulation.reads'])&gt;0">
<xsl:message terminate="no">[WARNING] FASTQs will be generated using samtools/wgsim if they don't exist.</xsl:message>
</xsl:if>
#
# Makefile for NGS
#
# WWW: https://github.com/lindenb/xml4ngs
#
<xsl:apply-templates select="project"/>

#
# END
#
</xsl:template>

<xsl:template match="project">
<xsl:text>

#
# tools.mk define the path to the application
# config.mk are user-specific values
#
include tools.mk  config.mk

#
#
OUTDIR?=Output

#
# Color for Makefile
# ref: http://jamesdolan.blogspot.fr/2009/10/color-coding-makefile-output.html
#
NO_COLOR=\x1b[0m
OK_COLOR=\x1b[32;01m
ERROR_COLOR=\x1b[31;01m
WARN_COLOR=\x1b[33;01m
#
# fix PATH (tophat needs this)
#
export PATH:=$(PATH):${BOWTIE2.dir}:${samtools.dir}
#
#
# path to GHOSTVIEW
GHOSTVIEW ?= gs

TABIX.bgzip?=${TABIX}/bgzip
TABIX.tabix?=${TABIX}/tabix

#
#reference genome
#
REF?=$(OUTDIR)/Reference/human_g1k_v37.fasta
#
# file that will be used to lock the SQL-related resources
#
LOCKFILE=$(OUTDIR)/</xsl:text><xsl:value-of select="concat('_tmp.',generate-id(.),'.lock')"/>
XMLSTATS=$(OUTDIR)/pipeline.stats.xml
HSQLSTATS=$(OUTDIR)/hsqldb.stats
INDEXED_REFERENCE=$(foreach S,.amb .ann .bwt .pac .sa .fai,$(addsuffix $S,$(REF))) $(addsuffix	.dict,$(basename $(REF)))
#
#genome indexed with bowtie
#
BOWTIE_INDEXED_REFERENCE=$(foreach S,.1.bt2 .2.bt2 .3.bt2 .4.bt2 .rev.1.bt2 .rev.2.bt2, $(addsuffix $S,$(basename  $(REF))) )

SAMPLES=<xsl:for-each select="sample"><xsl:value-of select="concat(' ',@name)"/></xsl:for-each>
capture.bed?=<xsl:choose>
	<xsl:when test="properties/property[@key='capture.bed.path']"><xsl:value-of select="normalize-space(properties/property[@key='capture.bed.path'])"/></xsl:when>
	<xsl:otherwise>$(OUTDIR)/ensembl.exons.bed</xsl:otherwise>
</xsl:choose>

#
# exons reference for tophat
#
exons.gtf?=<xsl:choose>
	<xsl:when test="properties/property[@key='exons.gtf.path']"><xsl:value-of select="normalize-space(properties/property[@key='exons.gtf.path'])"/></xsl:when>
	<xsl:otherwise>$(OUTDIR)/Reference/Homo_sapiens.GRCh37.69.gtf</xsl:otherwise>
</xsl:choose>


#build for snpEff
SNPEFFBUILD?=<xsl:choose>
	<xsl:when test="properties/property[@key='snpEff.build']"><xsl:value-of select="normalize-space(properties/property[@key='snpEff.build'])"/></xsl:when>
	<xsl:otherwise>hg19</xsl:otherwise>
</xsl:choose>

#
# known sites for the GATK
#
known.sites?=<xsl:choose>
        <xsl:when test="properties/property[@key='known.sites']"><xsl:value-of select="normalize-space(properties/property[@key='known.sites'])"/></xsl:when>
        <xsl:otherwise>$(OUTDIR)/Reference/dbsnp.vcf.gz</xsl:otherwise>
</xsl:choose>


#
# TARGETS AS LISTS
#

########################################################################################################
#
# PHONY TARGETS
#
#
.PHONY: all fastx all_predictions \
	indexed_reference bams bams_realigned  bams_sorted \
	bams_merged bams_unsorted bams_recalibrated \
	bams_markdup \
	coverage toptarget \
	all_fastqs \
	hsqldb_statistics

########################################################################################################
#
# MACRO DEFINITIONS
#
#
ifndef DELETEFILE
DELETEFILE=echo 
endif

define bai_files
    $(foreach B,$(filter %.bam,$(1)),  $(addsuffix .bai,$B) )
endef


define indexed_bam
    $(1) $(call bai_files, $(1))
endef


define notempty
    test -s $(1) || (echo "$(1) is empty" &amp;&amp; rm -f $(1) &amp;&amp; exit -1) 
endef


define timebegindb
	lockfile $(LOCKFILE)
	$(JAVA) -jar ${HSQLDB.sqltool} --autoCommit --inlineRc=url=jdbc:hsqldb:file:$(HSQLSTATS) --sql "create table if not exists begindb(file varchar(255) not null,category varchar(50) not null,w TIMESTAMP,CONSTRAINT K1 UNIQUE (file,category)); delete from begindb where file='$(1)' and category='$(2)'; insert into begindb(file,category,w) values ('$(1)','$(2)',NOW);"
	rm -f $(LOCKFILE)
endef

define timeenddb
	lockfile $(LOCKFILE)
	$(JAVA) -jar ${HSQLDB.sqltool} --autoCommit --inlineRc=url=jdbc:hsqldb:file:$(HSQLSTATS) --sql "create table if not exists enddb(file varchar(255) not null,category varchar(50) not null,w TIMESTAMP,CONSTRAINT K2 UNIQUE (file,category)); delete from enddb where file='$(1)' and category='$(2)'; insert into enddb(file,category,w) values ('$(1)','$(2)',NOW);"
	rm -f $(LOCKFILE)
endef


define sizedb
	stat -c "%s" $(1) | while read L; do lockfile $(LOCKFILE); $(JAVA) -jar ${HSQLDB.sqltool} --autoCommit --inlineRc=url=jdbc:hsqldb:file:$(HSQLSTATS) --sql "create table if not exists sizedb(file varchar(255) not null,size int); delete from sizedb where file='$(1)'; insert into sizedb(file,size) values('$(1)','$$L');" ; rm -f $(LOCKFILE);done
endef




define delete_and_touch
<xsl:choose>
<xsl:when test="properties/property[@key='delete.temporary.files']='yes'">echo "[WARNING] delete $(1)"; rm -f $(1); touch $(1); sleep 2</xsl:when>
<xsl:otherwise><!-- ignore --></xsl:otherwise>
</xsl:choose>
endef

########################################################################################################
#
# PATTERN RULES DEFINITIONS
#
#
%.amb %.ann %.bwt %.pac %.sa : %.fasta
	$(BWA) index -a bwtsw $&lt; 

%.fasta.fai : %.fasta
	$(SAMTOOLS) faidx $&lt;

%.dict: %.fasta
	 $(JAVA) -jar $(PICARD)/CreateSequenceDictionary.jar \
		R=$&lt; \
		O=$@ \
		GENOME_ASSEMBLY=$(basename $(notdir $&lt;)) \
		TRUNCATE_NAMES_AT_WHITESPACE=true


#
# treat all files as SECONDARY
#
.SECONDARY :

<xsl:text>

toptarget:
	echo "This is the top target. Please select a specific target"

all: all_predictions fastx hsqldb_statistics

indexed_reference: $(INDEXED_REFERENCE)




#coverage.tsv : $(capture.bed)  $(foreach S,$(SAMPLES),$(OUTDIR)/$(S)$(BAMSUFFIX).bam )
#	${VARKIT}/beddepth $(foreach S,$(SAMPLES),-f $(OUTDIR)/$(S)$(BAMSUFFIX).bam ) &lt; $&lt; &gt; $@



#bams:bams$(BAMSUFFIX)
bams_realigned:</xsl:text><xsl:for-each select="sample"><xsl:apply-templates select="." mode="realigned"/></xsl:for-each><xsl:text>
bams_markdup: </xsl:text><xsl:for-each select="sample"><xsl:apply-templates select="." mode="markdup"/></xsl:for-each><xsl:text>
bams_merged: </xsl:text><xsl:for-each select="sample"><xsl:apply-templates select="." mode="merged"/></xsl:for-each><xsl:text>
bams_recalibrated: </xsl:text><xsl:for-each select="sample"><xsl:apply-templates select="." mode="recal"/></xsl:for-each><xsl:text>
bams_unsorted: </xsl:text><xsl:for-each select="sample/sequences/pair"><xsl:apply-templates select="." mode="unsorted"/></xsl:for-each><xsl:text>
bams_sorted: </xsl:text><xsl:for-each select="sample/sequences/pair"><xsl:apply-templates select="." mode="sorted"/></xsl:for-each><xsl:text>
coverage: </xsl:text><xsl:for-each select="sample"><xsl:apply-templates select="." mode="coverage"/></xsl:for-each>

all_fastqs: <xsl:for-each select="sample/sequences/pair/fastq"><xsl:apply-templates select="." mode="fastq"/><xsl:text> </xsl:text></xsl:for-each>




########################################################################################################
#
# PREDICTIONS
#
#
all_predictions: \
	$(OUTDIR)/variations.samtools.vep.tsv.gz \
	$(OUTDIR)/variations.samtools.snpEff.vcf.gz \
	$(OUTDIR)/variations.gatk.snpEff.vcf.gz


#
# prediction samtools with Variation Ensembl Prediction API
#
$(OUTDIR)/variations.samtools.vep.tsv.gz: $(OUTDIR)/variations.samtools.vcf.gz
	$(VEP.bin) $(VEP.args) $(VEP.cache) --fasta $(REF) --format vcf --force_overwrite -i $&lt; -o $(basename $@)
	$(call notempty,$(basename $@))
	${TABIX.bgzip} -f $(basename $@)
	$(call notempty,$@)


#
# annotate samtools vcf with snpEff
#
$(OUTDIR)/variations.samtools.snpEff.vcf.gz: $(OUTDIR)/variations.samtools.vcf.gz
	$(call timebegindb,$@,mpileupsnpeff)
	gunzip -c  $&lt; |\
	egrep -v '^GL' |\
	$(JAVA) -jar $(SNPEFF)/snpEff.jar eff -i vcf -o vcf -c $(SNPEFF)/snpEff.config  $(SNPEFFBUILD) |\
	$(SNPEFF)/scripts/vcfEffOnePerLine.pl |\
	${TABIX.bgzip} -c  &gt; $@
	${TABIX.tabix} -p vcf $@ 
	$(call timeenddb,$@,mpileupsnpeff)
	$(call sizedb,$@)
	$(call notempty,$@)
#
# annotate GATK vcf with snpEff
#
$(OUTDIR)/variations.gatk.snpEff.vcf.gz: $(OUTDIR)/variations.gatk.vcf.gz
	$(call timebegindb,$@,gatksnpeff)
	gunzip -c  $&lt; |\
	egrep -v '^GL' |\
	$(JAVA) -jar $(SNPEFF)/snpEff.jar eff -i vcf -o vcf -c $(SNPEFF)/snpEff.config  $(SNPEFFBUILD) |\
	$(SNPEFF)/scripts/vcfEffOnePerLine.pl |\
	${TABIX.bgzip} -c  &gt; $@
	${TABIX.tabix} -p vcf $@ 
	$(call timeenddb,$@,gatksnpeff)
	$(call sizedb,$@)
	$(call notempty,$@)

########################################################################################################
#
# ALLELES CALLING
#
#


#
# Allele calling with samtools
#
$(OUTDIR)/variations.samtools.vcf.gz: $(call indexed_bam,<xsl:for-each select="sample"><xsl:apply-templates select="." mode="recal"/></xsl:for-each>)
	$(call timebegindb,$@,mpileup)
	$(SAMTOOLS) mpileup -uD -q 30 -f $(REF) $(filter %.bam,$^) |\
	$(BCFTOOLS) view -vcg - |\
	${TABIX.bgzip} -c &gt; $@
	${TABIX.tabix} -p vcf $@ 
	$(call timeenddb,$@,mpileup)
	$(call sizedb,$@)
	$(call notempty,$@)


#
# Allele calling with GATK
#
$(OUTDIR)/variations.gatk.vcf.gz: $(call indexed_bam,<xsl:for-each select="sample"><xsl:apply-templates select="." mode="recal"/></xsl:for-each>) $(known.sites)
	$(call timebegindb,$@,UnifiedGenotyper)
	$(JAVA) $(GATK.jvm) -jar $(GATK.jar) $(GATK.flags) \
		-R $(REF) \
		-T UnifiedGenotyper \
		-glm BOTH \
		-S SILENT \
		$(foreach B,$(filter %.bam,$^), -I $B ) \
		--dbsnp $(known.sites) \
		-o $(basename $@)
	${TABIX.bgzip} -f $(basename $@)
	$(call timeendb,$@,UnifiedGenotyper)
	$(call sizedb,$@)
	$(call notempty,$@)


###################################################################################################################################################
#
# Capture
#

$(OUTDIR)/ensembl.exons.bed:
	$(call timebegindb,$@,$@)
	curl  -d 'query=<![CDATA[<?xml version="1.0" encoding="UTF-8"?><Query virtualSchemaName="default" formatter="TSV" header="0" uniqueRows="0" count="" datasetConfigVersion="0.6" ><Dataset name="]]><xsl:choose>
		<xsl:when test="properties/property[@key='ensembl.dataset.name']"><xsl:value-of select="properties/property[@key='ensembl.dataset.name']"/></xsl:when>
		<xsl:otherwise>hsapiens_gene_ensembl</xsl:otherwise>
		</xsl:choose><![CDATA[" interface="default" ><Attribute name="chromosome_name" /><Attribute name="exon_chrom_start" /><Attribute name="exon_chrom_end" /></Dataset></Query>]]>' "http://www.biomart.org/biomart/martservice/result" |\
	grep -v '_' |grep -v 'GL' |grep -v 'MT' |\
	uniq | sort -t '	' -k1,1 -k2,2n -k3,3n | uniq &gt; $@
	$(call timeendb,$@,$@)
	$(call sizedb,$@)
	$(call notempty,$@)

###################################################################################################################################################
#
# EXONS GTF for tophat
#
$(OUTDIR)/Reference/Homo_sapiens.GRCh37.69.gtf:
	$(call timebegindb,$@,$@)
	mkdir -p $(dir $@)
	curl -o $@.gz "ftp://ftp.ensembl.org/pub/current_gtf/homo_sapiens/$(basename $@).gz"
	$(call notempty,$@.gz)
	gunzip $@.gz
	$(call timeendb,$@,$@)
	$(call sizedb,$@)
	$(call notempty,$@)


#
# extends the bed by 500 by default
#
ifndef extend.bed
extend.bed=500
endif


#
# an extended version of the capture, will be used for recalibration
#
$(OUTDIR)/capture500.bed: $(capture.bed)
	cut -d '	' -f1,2,3 $&lt; |\
	awk -F '	'  -v x=$(extend.bed) '{S=int($$2)-int(x); if(S&lt;0) S=0; printf("%s\t%d\t%d\n",$$1,S,int($$3)+int(x));}' |\
	sort -t '	' -k1,1 -k2,2n -k3,3n |\
	$(BEDTOOLS)/mergeBed -d $(extend.bed) -i - &gt; $@
	$(call notempty,$@)


########################################################################################################
# 
# BEGIN SAMPLES
#
########################################################################################################
<xsl:for-each select="sample">

########################################################################################################
# 
# BEGIN SAMPLE <xsl:value-of select="@name"/>
#
########################################################################################################


#
# Depth of coverage with GATK
#
<xsl:apply-templates select="." mode="coverage"/>: $(call indexed_bam,<xsl:apply-templates select="." mode="recal"/>) $(capture.bed)
	$(call timebegindb,$@,coverage)
	$(JAVA) $(GATK.jvm) -jar $(GATK.jar) $(GATK.flags) \
		-R $(REF) \
		-T DepthOfCoverage \
		-L $(filter %.bed,$^) \
		-S SILENT \
		-omitBaseOutput \
		--summaryCoverageThreshold 5 \
		-I $(filter %.bam,$^) \
		-o $@
	$(call timeendb,$@,coverage)




<xsl:call-template name="make.bai">
 <xsl:with-param name="bam">
  <xsl:apply-templates select="." mode="realigned"/>
 </xsl:with-param>
</xsl:call-template>

<xsl:call-template name="make.bai">
 <xsl:with-param name="bam">
  <xsl:apply-templates select="." mode="markdup"/>
 </xsl:with-param>
</xsl:call-template>

<xsl:if test="count(sequences/pair)&gt;1">
<xsl:call-template name="make.bai">
 <xsl:with-param name="bam">
  <xsl:apply-templates select="." mode="merged"/>
 </xsl:with-param>
</xsl:call-template>
</xsl:if>

<xsl:call-template name="make.bai">
 <xsl:with-param name="bam">
  <xsl:apply-templates select="." mode="recal"/>
 </xsl:with-param>
</xsl:call-template>


#
#
# Recalibrate alignments for Sample &quot;<xsl:value-of select="@name"/>&quot;
#
#
LIST_BAM_RECAL+=<xsl:apply-templates select="." mode="recal"/><xsl:text>
</xsl:text>
<xsl:apply-templates select="." mode="recal"/> : $(call indexed_bam,<xsl:apply-templates select="." mode="markdup"/>) $(OUTDIR)/capture500.bed $(known.sites)
	$(call timebegindb,$@_countCovariates,covariates)
	$(JAVA) $(GATK.jvm) -jar $(GATK.jar) $(GATK.flags) \
		-T BaseRecalibrator \
		-R $(REF) \
		-I $(filter %.bam,$^) \
		-l INFO \
		-o $@.recal_data.grp \
		-knownSites $(known.sites) \
		-L $(filter %.bed,$^) \
		-cov ReadGroupCovariate \
		-cov QualityScoreCovariate \
		-cov CycleCovariate \
		-cov ContextCovariate
	$(call timeenddb,$@_countCovariates,covariates)
	$(call timebegindb,$@_tableRecalibaration,recalibration)
	$(JAVA) $(GATK.jvm) -jar $(GATK.jar) $(GATK.flags) \
		-T PrintReads \
		--disable_bam_indexing \
		-R $(REF) \
		-BQSR $@.recal_data.grp \
		-I $(filter %.bam,$^) \
		-o $@ \
		-l INFO
	$(call timeenddb,$@_tableRecalibaration,recalibration)
	$(call sizedb,$@)
	rm -f $@.recal_data.grp
	$(call notempty,$@)
	$(call delete_and_touch,$(filter %.bam,$^) )
	$(call delete_and_touch,$(filter %.bai,$^) )
	touch $@


#
#
# Mark duplicates for Sample: <xsl:value-of select="@name"/>
#
LIST_BAM_MARKDUP+=<xsl:apply-templates select="." mode="markdup"/><xsl:text>
</xsl:text>
<xsl:apply-templates select="." mode="markdup"/> : $(call indexed_bam,<xsl:apply-templates select="." mode="realigned"/>)
	$(call timebegindb,$@_markdup,markdup)
	$(JAVA) $(PICARD.jvm) -jar $(PICARD)/MarkDuplicates.jar \
		TMP_DIR=$(OUTDIR) \
		INPUT=$(filter %.bam,$^) \
		O=$@ \
		MAX_FILE_HANDLES=400 \
		M=$@.metrics \
		AS=true \
		VALIDATION_STRINGENCY=SILENT
	$(call timeenddb,$@_markdup,markdup)
	#$(call timebegindb,$@_fixmate,fixmate)
	#$(JAVA) $(PICARD.jvm) -jar $(PICARD)/FixMateInformation.jar  TMP_DIR=$(OUTDIR) INPUT=$@  VALIDATION_STRINGENCY=SILENT
	#$(call timendedb,$@_fixmate,fixmate)
	#$(SAMTOOLS) index $@
	#$(call timebegindb,$@_validate,validate)
	#$(JAVA) $(PICARD.jvm) -jar $(PICARD)/ValidateSamFile.jar TMP_DIR=$(OUTDIR) VALIDATE_INDEX=true I=$@  CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT IGNORE_WARNINGS=true
	#$(call timeenddb,$@_validate,validate)
	$(DELETEFILE) $&lt; $@.metrics 
	$(call sizedb,$@)
	$(call notempty,$@)
	$(call delete_and_touch,$(filter %.bam,$^) )
	$(call delete_and_touch,$(filter %.bai,$^) )
	touch $@


#
#
# IndelRealignments for Sample &quot;<xsl:value-of select="@name"/>&quot;
#
#
LIST_BAM_REALIGN+=<xsl:apply-templates select="." mode="realigned"/><xsl:text>
</xsl:text>
<xsl:apply-templates select="." mode="realigned"/>: $(call indexed_bam,<xsl:apply-templates select="." mode="merged"/>) $(OUTDIR)/capture500.bed $(known.sites)
		$(call timebegindb,$@_targetcreator,targetcreator)
		$(JAVA) $(GATK.jvm) -jar $(GATK.jar) $(GATK.flags) \
			-T RealignerTargetCreator \
  			-R $(REF) \
			-L $(filter %.bed,$^) \
  			-I $(filter %.bam,$^) \
			-S SILENT \
  			-o $(addsuffix .intervals, $(filter %.bam,$^) ) \
			--known $(known.sites)
		$(call timeenddb,$@_targetcreator,targetcreator)
		$(call timebegindb,$@_indelrealigner,indelrealign)
		$(JAVA) $(GATK.jvm) -jar  $(GATK.jar) $(GATK.flags) \
  			-T IndelRealigner \
  			-R $(REF) \
  			-I $(filter %.bam,$^) \
			-S SILENT \
  			-o $@ \
  			-targetIntervals $(addsuffix .intervals, $(filter %.bam,$^) ) \
			--knownAlleles $(known.sites)
		$(call timeenddb,$@_indelrealigner,indelrealign)
		$(call sizedb,$@)
		$(call notempty,$@)
		rm -f $(addsuffix .intervals, $(filter %.bam,$^) )
		$(call delete_and_touch,$(filter %.bam,$^)  )
		$(call delete_and_touch,$(filter %.bam.bai,$^)  )
		touch $@



<xsl:if test="count(sequences/pair)&gt;1">
#
#
# Merge all Bams for Sample &quot;<xsl:value-of select="@name"/>&quot;
#
#
LIST_BAM_MERGED+=<xsl:apply-templates select="." mode="merged"/><xsl:text>
</xsl:text>
<xsl:apply-templates select="." mode="merged"/> : <xsl:for-each select="sequences/pair"><xsl:apply-templates select="." mode="sorted"/></xsl:for-each>
	$(call timebegindb,$@,merge)
	$(JAVA) -jar $(PICARD)/MergeSamFiles.jar O=$@ AS=true \
		VALIDATION_STRINGENCY=SILENT COMMENT="Merged from $^" \
		$(foreach B,$^, I=$(B) )
	$(DELETEFILE) $^
	$(call timeenddb,$@,merge)
	$(call sizedb,$@)
	$(call notempty,$@)
	$(call delete_and_touch,$^)
	touch $@
	
</xsl:if>

###############################################################
#
# BEGIN: LOOP OVER EACH PAIR OF FASTQ
#
<xsl:for-each select="sequences/pair">

<xsl:call-template name="make.bai">
 <xsl:with-param name="bam">
  <xsl:apply-templates select="." mode="sorted"/>
 </xsl:with-param>
</xsl:call-template>


#
#
# Sort BAM for &quot;<xsl:value-of select="@name"/>&quot;
# default memory sort size for samtools sort is 500,000,000
#
LIST_BAM_SORTED+=<xsl:apply-templates select="." mode="sorted"/><xsl:text>
</xsl:text>
<xsl:apply-templates select="." mode="sorted"/> : <xsl:apply-templates select="." mode="unsorted"/>
	$(call timebegindb,$@,sort)
	$(SAMTOOLS) sort $&lt; $(basename $@)
	$(DELETEFILE) $&lt;
	$(call timeenddb,$@,sort)
	$(call sizedb,$@)
	$(call notempty,$@)
	$(call delete_and_touch,$&lt;)
	touch $@

#
# Call BWA sampe
#
#
LIST_BAM_UNSORTED+=<xsl:apply-templates select="." mode="unsorted"/><xsl:text>
</xsl:text>
<xsl:apply-templates select="." mode="unsorted"/> : <xsl:apply-templates select="fastq[@index='1']" mode="fastq"/>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="fastq[@index='2']" mode="fastq"/>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="fastq[@index='1']" mode="sai"/>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="fastq[@index='2']" mode="sai"/>
	$(call timebegindb,$@,bwasampe)
	$(BWA) sampe -a <xsl:apply-templates select="." mode="fragmentSize"/> ${REF} \
		-r "@RG	ID:<xsl:value-of select="generate-id(.)"/>	LB:<xsl:value-of select="../../@name"/>	SM:<xsl:value-of select="../../@name"/>	PL:ILLUMINA	PU:<xsl:value-of select="@lane"/>" \
		<xsl:apply-templates select="fastq[@index='1']" mode="sai"/> \
		<xsl:apply-templates select="fastq[@index='2']" mode="sai"/> \
		<xsl:apply-templates select="fastq[@index='1']" mode="fastq"/> \
		<xsl:apply-templates select="fastq[@index='2']" mode="fastq"/> |\
	$(SAMTOOLS) view -S -b -o $@ -T ${REF} -
	$(DELETEFILE) <xsl:apply-templates select="fastq" mode="sai"/> <xsl:for-each select="fastq">
		<xsl:if test="number($limit)&gt;0 or substring(@path, string-length(@path)- 3)='.bz2'">
			<xsl:text> </xsl:text>
			<xsl:apply-templates select="." mode="fastq"/>
		</xsl:if>
	</xsl:for-each> 
	$(call timeenddb,$@,bwasampe)
	$(call sizedb,$@)
	$(call notempty,$@)
	$(call delete_and_touch,$(filter %.sai,$^))
	touch $@


<!-- if the simulation.reads is set and greater than 0, the two fastqs will be created -->
<xsl:if test="number(/project/properties/property[@key='simulation.reads'])&gt;0">
<xsl:variable name="twofastqs">
<xsl:apply-templates select="fastq[@index='1']" mode="fastq"/>
<xsl:text> </xsl:text>
<xsl:apply-templates select="fastq[@index='2']" mode="fastq"/>
</xsl:variable>
#
# It is a simulation mode : generate the FASTQ with samtools
#
<xsl:value-of select="$twofastqs"/>:
	mkdir -p <xsl:apply-templates select="../.." mode="dir"/>
	$(warning  simulation.reads is set : CREATING TWO FASTQ FILES)
	$(call timebegindb,$@,wgsim)
	${samtools.dir}/misc/wgsim -N <xsl:value-of select="number(/project/properties/property[@key='simulation.reads'])"/> $(REF) $(basename <xsl:value-of select="$twofastqs"/>) |\
		${TABIX.bgzip} &gt; <xsl:apply-templates select="../.." mode="dir"/>/wgsim<xsl:value-of select="generate-id(.)"/>.vcf.gz
	gzip -f --best  $(basename <xsl:value-of select="$twofastqs"/>) 
	$(call timeenddb,$@,wgsim)
	$(call sizedb,$@)

</xsl:if>

#
# tophat: Align the RNA-seq reads to the genome for sample '<xsl:value-of select="../../@name"/>'
#
<xsl:apply-templates select="." mode="tophat.dir"/>: <xsl:apply-templates select="fastq[@index='1']" mode="fastq"/> \
	<xsl:apply-templates select="fastq[@index='2']" mode="fastq"/> \
	$(REF) $(exons.gtf)
	mkdir -p $@
	$(call timebegindb,$@,tophat)
	${TOPHAT.dir}/tophat2 -G $(exons.gtf) -o $@ \
		$(REF) \
		<xsl:apply-templates select="fastq[@index='1']" mode="fastq"/> \
		<xsl:apply-templates select="fastq[@index='2']" mode="fastq"/> 
	$(call timeenddb,$@,tophat)

##
## BEGIN : loop over the fastqs
##
<xsl:for-each select="fastq">
<xsl:text>

</xsl:text>

<xsl:choose>
<xsl:when test="substring(@path, string-length(@path)- 3)='.bz2'">

#need to convert from bz2 to gz
<xsl:apply-templates select="." mode="fastq"/>:<xsl:value-of select="@path"/>
	mkdir -p <xsl:apply-templates select="." mode="dir"/>
	bunzip -c $&lt; | <xsl:if test="number($limit)&gt;0"> head -n <xsl:value-of select="number($limit)*4"/> |</xsl:if> gzip --best &gt; $@

</xsl:when>

<xsl:when test="number($limit)&gt;0">
<xsl:apply-templates select="." mode="fastq"/>:<xsl:value-of select="@path"/><xsl:text> </xsl:text><xsl:apply-templates select="." mode="dir"/>
	gunzip -c $&lt; | head  -n <xsl:value-of select="number($limit)*4"/> | gzip --best &gt; $@	
</xsl:when>

</xsl:choose>


<xsl:apply-templates select="." mode="sai"/>:<xsl:apply-templates select="." mode="fastq"/> $(INDEXED_REFERENCE)
	mkdir -p $(dir $@)
	$(call timebegindb,$@,sai)
	$(call sizedb,$&lt;)
	$(BWA) aln $(BWA.aln.options) -f $@ ${REF} $&lt;
	$(call timeenddb,$@,sai)
	$(call sizedb,$@)
	$(call notempty,$@)


<xsl:if test="substring(@path, string-length(@path)- 2)='.gz'">
#
# tophat needs uncompressed fastq 
#
<xsl:apply-templates select="." mode="fastq-unzipped"/>: <xsl:apply-templates select="." mode="fastq"/>
	mkdir -p $(dir $@)
	$(call timebegindb,$@,gunzipfastq)
	gunzip -c $&lt; &gt; > $@
	$(call timeenddb,$@,gunzipfastq)
	$(call sizedb,$@)
	$(call notempty,$@)

</xsl:if>


</xsl:for-each>
##
## END : loop over the fastq
##

###############################################################
#
# END: LOOP OVER EACH PAIR OF FASTQ
#

</xsl:for-each>
########################################################################################################
# 
# END SAMPLE <xsl:value-of select="@name"/>
#
########################################################################################################
</xsl:for-each>
########################################################################################################
# 
# END SAMPLES
#
########################################################################################################


<xsl:apply-templates select="." mode="fastx"/>

#####################################################################################
#
# statistics from HSQLDB
#
hsqldb_statistics: $(OUTDIR)/durations.stats.txt $(OUTDIR)/filesize.stats.txt

$(OUTDIR)/durations.stats.txt:
	lockfile $(LOCKFILE)
	-$(JAVA) -jar ${HSQLDB.sqltool}--autoCommit --inlineRc=url=jdbc:hsqldb:file:$(HSQLSTATS) \
		--sql "select B.category$(foreach T,SECOND MINUTE HOUR DAY, ,AVG(TIMESTAMPDIFF(SQL_TSI_${T},B.W,E.W)) as duration_${T}) from begindb as B ,enddb as E where B.file=E.file group by B.category;" > $@
	rm -f $(LOCKFILE)

$(OUTDIR)/filesize.stats.txt:
	lockfile $(LOCKFILE)
	-$(JAVA) -jar ${HSQLDB.sqltool}--autoCommit --inlineRc=url=jdbc:hsqldb:file:$(HSQLSTATS) \
		--sql "select B.category,count(*) as N, AVG(L.size) as AVG_FILESIZE from begindb as B ,sizedb as L where B.file=L.file group by B.category;" > $@
	rm -f $(LOCKFILE)


#####################################################################################
#
# REFERENCE
#
$(OUTDIR)/Reference/human_g1k_v37.fasta:
	mkdir -p $(dir $@)	
	curl -o $(addsuffix .gz,$@) "ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/$@.gz"
	$(call notempty,$(addsuffix .gz,$@))
	gunzip $(addsuffix .gz,$@)
	$(call notempty,$@)


#
# index reference with bowtie
#
${REF.bowtie}:$(REF)
	${BOWTIE2.dir}/bowtie2-build  -f -c $(REF) $(basename $(REF))
	${BOWTIE2.dir}/bowtie2-inspect -s $(basename $(REF))

#
# download ncbi dbsnp as VCF
#
$(OUTDIR)/Reference/dbsnp.vcf.gz : $(OUTDIR)/Reference/dbsnp.vcf.gz.tbi
	mkdir -p $(dir $@)
	curl  -o $@ "ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-All.vcf.gz"
	$(call notempty,$@)

$(OUTDIR)/Reference/dbsnp.vcf.gz.tbi :
	mkdir -p $(dir $@)
	curl  -o $@ "ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-All.vcf.gz.tbi"
	$(call notempty,$@)



</xsl:template>


<xsl:template match="fastq" mode="dir">
	<xsl:apply-templates select="../../.." mode="dir"/>
</xsl:template>

<xsl:template match="fastq" mode="fastq">
<xsl:choose>
 <xsl:when test="number($limit)&gt;0 or substring(@path, string-length(@path)- 3)='.bz2'">
	<xsl:variable name="p"><xsl:apply-templates select=".." mode="pairname"/></xsl:variable>
	<xsl:text>$(OUTDIR)/</xsl:text><xsl:value-of select="concat(../../../@name,'/$(TMPREFIX)',$p,'_',@index,'.fastq.gz ')"/>
 </xsl:when>
 <xsl:otherwise>
	<xsl:value-of select="@path"/>
 </xsl:otherwise>
</xsl:choose>
</xsl:template>



<xsl:template match="fastq" mode="sai">
<xsl:variable name="p"><xsl:apply-templates select=".." mode="pairname"/></xsl:variable>
<xsl:text>$(OUTDIR)/</xsl:text><xsl:value-of select="concat(../../../@name,'/$(TMPREFIX)',$p,'_',@index,'.sai ')"/>
</xsl:template>

<xsl:template match="pair" mode="fragmentSize">
<xsl:choose>
  <xsl:when test="@fragmentSize"><xsl:value-of select="@fragmentSize"/></xsl:when>
  <xsl:when test="/project/fragmentSize"><xsl:value-of select="/project/fragmentSize"/></xsl:when>
  <xsl:otherwise>500</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:template match="pair" mode="sorted">
<xsl:variable name="p"><xsl:apply-templates select="." mode="pairname"/></xsl:variable>
<xsl:text>$(OUTDIR)/</xsl:text><xsl:value-of select="concat(../../@name,'/$(TMPREFIX)',$p,'_sorted.bam ')"/>
</xsl:template>

<xsl:template match="pair" mode="tophat.dir">
<xsl:variable name="p"><xsl:apply-templates select="." mode="pairname"/></xsl:variable>
<xsl:text>$(OUTDIR)/</xsl:text><xsl:value-of select="concat(../../@name,'/$(TMPREFIX)',$p,'_thout ')"/>
</xsl:template>


<xsl:template match="sample" mode="merged">
<xsl:choose>
<xsl:when test="count(sequences/pair)&gt;1">
	<xsl:apply-templates select="." mode="dir"/>
	<xsl:value-of select="concat('/$(TMPREFIX)',@name,'_merged.bam ')"/>
</xsl:when>
<xsl:otherwise>
	<xsl:apply-templates select="sequences/pair[1]" mode="sorted"/>
</xsl:otherwise>
</xsl:choose>
</xsl:template>


<xsl:template match="pair" mode="unsorted">
<xsl:variable name="p"><xsl:apply-templates select="." mode="pairname"/></xsl:variable>
<xsl:apply-templates select="../.." mode="dir"/>
<xsl:value-of select="concat('/$(TMPREFIX)',$p,'_unsorted.bam ')"/>
</xsl:template>

<xsl:template match="fastq" mode="gz">
<xsl:variable name="p"><xsl:apply-templates select=".." mode="pairname"/></xsl:variable>
<xsl:apply-templates select="../.." mode="dir"/>
<xsl:value-of select="concat('/$(TMPREFIX)',$p,'_',@index,'.fastq.gz')"/>
</xsl:template>


<xsl:template match="pair" mode="pairname">
<xsl:value-of select="concat(../../@name,'_pair',(1+count(preceding-sibling::pair)))"/>
</xsl:template>


<xsl:template match="sample" mode="coverage">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_coverage ')"/>
</xsl:template>


<xsl:template match="sample" mode="sorted">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_sorted.bam ')"/>
</xsl:template>

<xsl:template match="sample" mode="markdup">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_markdup.bam ')"/>
</xsl:template>

<xsl:template match="sample" mode="recal">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_recal.bam ')"/>
</xsl:template>

<xsl:template match="sample" mode="realigned">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_realigned.bam ')"/>
</xsl:template>

<xsl:template match="sample" mode="dir">
<xsl:text>$(OUTDIR)/</xsl:text>
<xsl:value-of select="@name"/>
</xsl:template>

<xsl:template name="make.bai">
<xsl:param name="bam"/>
<xsl:text>
#
# create BAM index for </xsl:text>
<xsl:value-of select="$bam"/>
<xsl:text>
#
</xsl:text>
<xsl:value-of select="concat(normalize-space($bam),'.bai')"/> <xsl:text>: </xsl:text><xsl:value-of select="$bam"/><xsl:text>
	$(call timebegindb,$@,bai)
	$(SAMTOOLS) index $&lt;
	$(call timeenddb,$@,bai)
	$(call sizedb,$@)
	$(call notempty,$@)
	

</xsl:text>
</xsl:template>

<!-- ======================================================================================================
     
   	FASTX
     
     ====================================================================================================== -->

<xsl:template match="project" mode="fastx">
#
# merge all the FASTX reports in one PDF
#
fastx: $(OUTDIR)/FASTX/fastx.report.pdf
$(OUTDIR)/FASTX/fastx.report.pdf: <xsl:for-each select="sample">
	<xsl:text> \
	</xsl:text>
	<xsl:apply-templates select="." mode="fastx.qual.and.nuc"/>
</xsl:for-each><xsl:for-each select="lane">
	<xsl:text> \
	</xsl:text>
	<xsl:apply-templates select="." mode="fastx.qual.and.nuc"/>
</xsl:for-each>
	mkdir -p $(dir $@)
	${GHOSTVIEW} -dNOPAUSE -q -sDEVICE=pdfwrite -sOUTPUTFILE=$@ -dBATCH $^
<xsl:text>
</xsl:text>

<xsl:apply-templates select="sample" mode="fastx"/>
<xsl:apply-templates select="lanes/lane" mode="fastx"/>
</xsl:template>

<xsl:template match="sample" mode="fastx">
<xsl:variable name="stat">
<xsl:apply-templates select="." mode="fastx.output.dir"/>
<xsl:value-of select="concat('/',@name,'.stats.tsv')"/>
</xsl:variable>
#
# Compute postscript files for FASTX for sample &quot;<xsl:value-of select="@name"/>&quot;
# 
#
<xsl:apply-templates select="." mode="fastx.qual.and.nuc"/>  : <xsl:for-each select="sequences/pair/fastq">
	<xsl:text> \
	</xsl:text>
	<xsl:value-of select="@path"/>
</xsl:for-each>
	mkdir -p $(dir $@)
	gunzip -c $^ |\
	$(FASTX.dir)/bin/fastx_quality_stats &gt; <xsl:value-of select="$stat"/>
	$(FASTX.dir)/bin/fastq_quality_boxplot_graph.sh -p  -i <xsl:value-of select="$stat"/> -t "QUAL <xsl:value-of select="@name"/>" -o <xsl:apply-templates select="." mode="fastx.qual"/>
	$(FASTX.dir)/bin/fastx_nucleotide_distribution_graph.sh -p -i <xsl:value-of select="$stat"/> -t "NUCLEOTIDE-DIST <xsl:value-of select="@name"/>" -o <xsl:apply-templates select="." mode="fastx.nuc"/>
	rm -f <xsl:value-of select="$stat"/>
</xsl:template>


<xsl:template match="sample" mode="fastx.qual.and.nuc">
<xsl:apply-templates select="." mode="fastx.qual"/>
<xsl:text> </xsl:text>
<xsl:apply-templates select="." mode="fastx.nuc"/>
</xsl:template>

<xsl:template match="sample" mode="fastx.qual">
<xsl:apply-templates select="." mode="fastx.output.dir"/>
<xsl:value-of select="concat('/',@name,'.fastx.qualchart.ps')"/>
</xsl:template>

<xsl:template match="sample" mode="fastx.nuc">
<xsl:apply-templates select="." mode="fastx.output.dir"/>
<xsl:value-of select="concat('/',@name,'.fastx.nuclchart.ps')"/>
</xsl:template>

<xsl:template match="sample" mode="fastx.output.dir">
<xsl:apply-templates select="." mode="dir"/>
</xsl:template>


<xsl:template match="lane" mode="fastx">
<xsl:variable name="laneid" select="./text()"/>
<xsl:variable name="stat">
<xsl:apply-templates select="." mode="fastx.output.dir"/>
<xsl:value-of select="concat('/L',$laneid,'.stats.tsv')"/>
</xsl:variable>
#
# Compute postscript files for FASTX for Lane &quot;<xsl:value-of select="$laneid"/>&quot;
# 
#
<xsl:apply-templates select="." mode="fastx.qual.and.nuc"/>  : <xsl:for-each select="../../sample/sequences/pair[@lane=$laneid]/fastq">
	<xsl:text> \
	</xsl:text>
	<xsl:value-of select="@path"/>
</xsl:for-each>
	mkdir -p $(dir $@)
	gunzip -c $^ |\
	$(FASTX.dir)/bin/fastx_quality_stats -Q33  &gt; <xsl:value-of select="$stat"/>
	$(FASTX.dir)/bin/ffastq_quality_boxplot_graph.sh -p  -i <xsl:value-of select="$stat"/> -t "QUAL Lane <xsl:value-of select="$laneid"/>" -o <xsl:apply-templates select="." mode="fastx.qual"/>
	$(FASTX.dir)/bin/fastx_nucleotide_distribution_graph.sh -p -i <xsl:value-of select="$stat"/> -t "NUCLEOTIDE-DIST Lane <xsl:value-of select="$laneid"/>" -o <xsl:apply-templates select="." mode="fastx.nuc"/>
	rm -f <xsl:value-of select="$stat"/>
</xsl:template>


<xsl:template match="lane" mode="fastx.qual.and.nuc">
<xsl:apply-templates select="." mode="fastx.qual"/>
<xsl:text> </xsl:text>
<xsl:apply-templates select="." mode="fastx.nuc"/>
</xsl:template>

<xsl:template match="lane" mode="fastx.qual">
<xsl:apply-templates select="." mode="fastx.output.dir"/>
<xsl:value-of select="concat('/L',.,'.fastx.qualchart.ps')"/>
</xsl:template>

<xsl:template match="lane" mode="fastx.nuc">
<xsl:apply-templates select="." mode="fastx.output.dir"/>
<xsl:value-of select="concat('/L',.,'.fastx.nuclchart.ps')"/>
</xsl:template>

<xsl:template match="lane" mode="fastx.output.dir">
<xsl:apply-templates select="." mode="dir"/>
</xsl:template>


	



</xsl:stylesheet>
