<?xml version='1.0'  encoding="UTF-8" ?>

<xsl:stylesheet
	xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
        xmlns:date="http://exslt.org/dates-and-times" 
        xmlns:str="http://exslt.org/strings"
        extension-element-prefixes="date str" 
	version='1.0'
	>


<xsl:output method="text" encoding="UTF-8"/>
<xsl:param name="limit"/>
<xsl:param name="fragmentsize">600</xsl:param>
<xsl:param name="bwathreads">1</xsl:param>


<xsl:variable name="set_curl_proxy">
<xsl:choose>
	<xsl:when test="/project/properties/property[@key='http.proxy.host']"> --proxy <xsl:value-of select="concat(/project/properties/property[@key='http.proxy.host'],':',/project/properties/property[@key='http.proxy.port'])"/> </xsl:when>
	<xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
</xsl:choose>
</xsl:variable>

<xsl:variable name="set_jvm_proxy">
<xsl:choose>
	<xsl:when test="/project/properties/property[@key='http.proxy.host']"> -Dhttp.proxyHost=<xsl:value-of select="/project/properties/property[@key='http.proxy.host']"/> -Dhttp.proxyPort=<xsl:value-of select="/project/properties/property[@key='http.proxy.port']"/> </xsl:when>
	<xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
</xsl:choose>
</xsl:variable>


<xsl:template match="/">
<xsl:if test="number(project/properties/property[@key='simulation.reads'])&gt;0">
<xsl:message terminate="no">[WARNING] FASTQs will be generated using samtools/wgsim if they don't exist.</xsl:message>
</xsl:if>
#
# Makefile for NGS
#
# WWW: https://github.com/lindenb/xml4ngs
#
# Date : <xsl:value-of select="date:date-time()"/>
#



<xsl:apply-templates select="project"/>

#
# END
#
</xsl:template>

<xsl:template match="project">
<xsl:text>
#
# this is the name of the current Makefile
# should be always here,  before' include'
# will be used for 'git'
#
makefile.name := $(lastword $(MAKEFILE_LIST))

#
# tools.mk define the path to the application
# config.mk are user-specific values
#
include tools.mk  <!-- config.mk -->

#######################################
#
# PROPERTIES defined in the project.xml 
#
#
</xsl:text>
<xsl:for-each select="properties/property">
<xsl:text># </xsl:text>
<xsl:value-of select="@key"/>
<xsl:text>	&quot;</xsl:text>
<xsl:value-of select="normalize-space(.)"/>
<xsl:text>&quot;
</xsl:text>
</xsl:for-each>

<xsl:choose>
<xsl:when test="not(/project/properties/property[@key='output.directory'])">
<xsl:message terminate="no">[WARNING] 'output.directory' undefined in project.</xsl:message>
<xsl:text>
#
#OUTPUT DIRECTORY
#
OUTDIR?=Output
</xsl:text>
</xsl:when>
<xsl:otherwise>
<xsl:text>
#
# outputdir was set in project properties
#
OUTDIR=</xsl:text>
<xsl:value-of select="/project/properties/property[@key='output.directory']"/>
<xsl:text>
</xsl:text>
</xsl:otherwise>
</xsl:choose>

#
# LIST_OF_PHONY_TARGET
#
LIST_PHONY_TARGET=


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
export PATH:=$(PATH):${BOWTIE2.dir}:${samtools.dir}:${CUFFLINKS.dir}:${R.dir}/bin:/usr/bin

###
# FIX LOCALE (http://unix.stackexchange.com/questions/61985)
#
export LC_ALL:=C


#
#
# path to GHOSTVIEW
GHOSTVIEW ?= gs



TABIX.bgzip?=${TABIX}/bgzip
TABIX.tabix?=${TABIX}/tabix


<xsl:choose>
<xsl:when test="not(/project/properties/property[@key='genome.reference.path'])">
<xsl:message terminate="no">[WARNING] 'genome.reference.path' undefined in project.</xsl:message>
<xsl:text>
#
#reference genome
#
REF?=$(OUTDIR)/Reference/human_g1k_v37.fasta
</xsl:text>
</xsl:when>
<xsl:otherwise>
<xsl:text>
#
# reference genome was set in project properties
#
REF=</xsl:text>
<xsl:value-of select="/project/properties/property[@key='genome.reference.path']"/>
<xsl:text>
</xsl:text>
</xsl:otherwise>

</xsl:choose>

<!-- ========= min mapping quality ======================================================= -->
<xsl:choose>
<xsl:when test="not(/project/properties/property[@key='min.mapping.quality'])">
<xsl:message terminate="no">[WARNING] 'min.mapping.quality' undefined in project, will use: 30</xsl:message>
<xsl:text>
#
# min mapping quality
#
MIN_MAPPING_QUALITY=30
</xsl:text>
</xsl:when>
<xsl:otherwise>
<xsl:text>
#
# min mapping quality
#
MIN_MAPPING_QUALITY=</xsl:text>
<xsl:value-of select="/project/properties/property[@key='min.mapping.quality']"/>
<xsl:text>
</xsl:text>
</xsl:otherwise>

</xsl:choose>
<!-- ================================================================================= -->

#
# file that will be used to lock the SQL-related resources
#
LOCKFILE=$(OUTDIR)/<xsl:value-of select="concat('_tmp.',generate-id(.),'.lock')"/>
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
        <xsl:when test="properties/property[@key='known.sites']">
        	<xsl:value-of select="normalize-space(properties/property[@key='known.sites'])"/>
        </xsl:when>
        <xsl:otherwise>
        	<xsl:message terminate="no">[WARNING] property 'known.sites' undefined.</xsl:message>
        	<xsl:text>$(OUTDIR)/Reference/dbsnp.vcf.gz</xsl:text>
        </xsl:otherwise>
</xsl:choose>


#
# TARGETS AS LISTS
#

########################################################################################################
#
# PHONY TARGETS
#
#
.PHONY: all toptarget ${LIST_PHONY_TARGET} 

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

define create_symbolic_link
	cp -f $(1) $(2)
endef

define notempty
    test -s $(1) || (echo "$(1) is empty" &amp;&amp; rm -f $(1) &amp;&amp; exit -1) 
endef

define check_no_sge
	if  [ "${JOB_ID}" != "" ]; then echo "This process shouldn't be run with SGE. Please invoke the regular make." ; exit -1;  fi
endef



CREATE_HSQLDB_DATABASE=create table if not exists begindb(file varchar(255) not null,category varchar(255) not null,w TIMESTAMP,CONSTRAINT K1 UNIQUE (file,category));create table if not exists enddb(file varchar(255) not null,category varchar(255) not null,w TIMESTAMP,CONSTRAINT K2 UNIQUE (file,category));create table if not exists sizedb(file varchar(255) not null,size BIGINT,CONSTRAINT K3 UNIQUE (file));

define timebegindb
	lockfile $(LOCKFILE)
	$(JAVA) -jar ${HSQLDB.sqltool} --autoCommit --inlineRc=url=jdbc:hsqldb:file:$(HSQLSTATS) --sql "$(CREATE_HSQLDB_DATABASE) delete from begindb where file='$(1)' and category='$(2)'; insert into begindb(file,category,w) values ('$(1)','$(2)',NOW);"
	rm -f $(LOCKFILE)
endef

define timeenddb
	lockfile $(LOCKFILE)
	$(JAVA) -jar ${HSQLDB.sqltool} --autoCommit --inlineRc=url=jdbc:hsqldb:file:$(HSQLSTATS) --sql "$(CREATE_HSQLDB_DATABASE) delete from enddb where file='$(1)' and category='$(2)'; insert into enddb(file,category,w) values ('$(1)','$(2)',NOW);"
	rm -f $(LOCKFILE)
endef


define sizedb
	stat -c "%s" $(1) | while read L; do lockfile $(LOCKFILE); $(JAVA) -jar ${HSQLDB.sqltool} --autoCommit --inlineRc=url=jdbc:hsqldb:file:$(HSQLSTATS) --sql "$(CREATE_HSQLDB_DATABASE) delete from sizedb where file='$(1)'; insert into sizedb(file,size) values('$(1)','$$L');" ; rm -f $(LOCKFILE);done
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
<xsl:for-each select="str:tokenize('.fasta .fa', ' ')" >

#index with bwa
%.amb %.ann %.bwt %.pac %.sa : %<xsl:value-of select="."/>
	$(BWA) index -a bwtsw $&lt; 

#index with samtools
%<xsl:value-of select="."/>.fai : %<xsl:value-of select="."/>
	$(SAMTOOLS) faidx $&lt;

#picard dictionnary
%.dict: %<xsl:value-of select="."/>
	 $(JAVA) -jar $(PICARD)/CreateSequenceDictionary.jar \
		R=$&lt; \
		O=$@ \
		GENOME_ASSEMBLY=$(basename $(notdir $&lt;)) \
		TRUNCATE_NAMES_AT_WHITESPACE=true
</xsl:for-each>

#
# treat all files as SECONDARY
#
.SECONDARY :



toptarget:
	@echo "This is the top target. Please select a specific target"
	@echo "e.g: ${LIST_PHONY_TARGET} "

all: ${LIST_PHONY_TARGET} all_predictions fastx hsqldb_statistics <xsl:if test="properties/property[@key='is.rnaseq']='yes'"> all_tophat</xsl:if>

indexed_reference: $(INDEXED_REFERENCE)







LIST_PHONY_TARGET+= bams_realigned 
bams_realigned:<xsl:for-each select="sample"><xsl:apply-templates select="." mode="realigned"/></xsl:for-each>
LIST_PHONY_TARGET+= bams_markdup 
bams_markdup: <xsl:for-each select="sample"><xsl:apply-templates select="." mode="markdup"/></xsl:for-each>
LIST_PHONY_TARGET+= bams_merged 
bams_merged: <xsl:for-each select="sample"><xsl:apply-templates select="." mode="merged"/></xsl:for-each>
LIST_PHONY_TARGET+= bams_recalibrated 
bams_recalibrated: <xsl:for-each select="sample"><xsl:apply-templates select="." mode="recal"/></xsl:for-each>
LIST_PHONY_TARGET+= bams_unsorted 
bams_unsorted: <xsl:for-each select="sample/sequences/pair"><xsl:apply-templates select="." mode="unsorted"/></xsl:for-each>
LIST_PHONY_TARGET+= bams_sorted 
bams_sorted: <xsl:for-each select="sample/sequences/pair"><xsl:apply-templates select="." mode="sorted"/></xsl:for-each>
LIST_PHONY_TARGET+= coverage
coverage:$(OUTDIR)/mean_coverage01.pdf
$(OUTDIR)/mean_coverage01.pdf: $(addsuffix .sample_summary, <xsl:for-each select="sample"><xsl:apply-templates select="." mode="coverage"/></xsl:for-each>)
	echo "sample	mean-coverage" &gt; $(patsubst %.pdf,%.tsv,$@)
	cat $^ | sort | grep -v -E  '^(Total|sample_id)'  |\
		cut -d '	' -f1,3 &gt;&gt; $(patsubst %.pdf,%.tsv,$@)
	echo 'pdf("$@",paper="A4r"); T&lt;-read.table("$(patsubst %.pdf,%.tsv,$@)",header=T,sep="\t",row.names=1); barplot(as.matrix(t(T)),legend=colnames(T),beside=TRUE,col=rainbow(7),las=2,cex.names=0.8); dev.off()' |\
	${R.exe} --no-save
	
	
LIST_PHONY_TARGET+= all_fastqs
all_fastqs: <xsl:for-each select="sample/sequences/pair/fastq"><xsl:apply-templates select="." mode="preprocessed.fastq"/><xsl:text> </xsl:text></xsl:for-each>
	




<!--
#
# Join samtools VEP to diseases database (jensenlab.org)
# 
$(OUTDIR)/variations.samtools.vep.diseases.tsv.gz: $(OUTDIR)/variations.samtools.vep.vcf.gz
	mkdir -p $(dir $@)
	curl "http://download.jensenlab.org/human_disease_textmining_full.tsv" | sort -t '	' -k1,1 > $(OUTDIR)/human_disease_textmining_full_01.tsv
	curl "http://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/ensGtp.txt.gz" | gunzip -c | awk -F '	' '($$3!="")' | sort -t '	' -k3,3 > $(OUTDIR)/ensGtp_01.txt
	(echo "Ensembl.Protein	GeneSymbol	disease.ontology.id	disease.ontology.label	jensenlab.zscore	jensenlab.confidence	Gene	Transcript" ; join -t '	' -1 1 -2 3 $(OUTDIR)/human_disease_textmining_full_01.tsv $(OUTDIR)/ensGtp_01.txt )| sort -t '	' -k7,7 > $(OUTDIR)/jeter_01.join
	gunzip -c $&lt; | sort -t '	' -k4,4 | join -t '	' -1 4 -2 7 - $(OUTDIR)/jeter_01.join | gzip \-\-best > $@ 
	rm -f $(OUTDIR)/human_disease_textmining_full_01.tsv $(OUTDIR)/ensGtp_01.txt $(OUTDIR)/jeter_01.join
-->





########################################################################################################
#
# ALLELES CALLING
#
#
<xsl:variable name="call.with.samtools.mpileup">	$(call timebegindb,$@,mpileup)
	$(SAMTOOLS) mpileup <xsl:if test="/project/properties/property[@key='is.haloplex']='yes'"> -A  -d 8000 </xsl:if> -uD \
		-q $(MIN_MAPPING_QUALITY) \
		<xsl:if test="/project/properties/property[@key='allele.calling.in.capture']='yes'"> -l $(OUTDIR)/capture500.bed </xsl:if> \
		-f $(REF) $(filter %.bam,$^) |\
	$(BCFTOOLS) view -vcg - |\
	${TABIX.bgzip} -c &gt; $@
	${TABIX.tabix} -f -p vcf $@ 
	@$(call timeenddb,$@,mpileup)
	@$(call sizedb,$@)
	$(call notempty,$@)

</xsl:variable>


<xsl:variable name="call.with.gatk">		$(call timebegindb,$@,UnifiedGenotyper)
	$(JAVA) $(GATK.jvm) -jar $(GATK.jar) $(GATK.flags) \
		-R $(REF) \
		-T UnifiedGenotyper \
		-glm BOTH \
		-S SILENT \
		<xsl:choose>
		  <xsl:when test="/project/properties/property[@key='gatk.unified.genotyper.options']">
		  	<xsl:value-of select="/project/properties/property[@key='gatk.unified.genotyper.options']"/>
		  </xsl:when>
		  <xsl:otherwise>
		  	<!-- no option   -->
		  </xsl:otherwise>
		</xsl:choose> \
		<xsl:if test="/project/properties/property[@key='allele.calling.in.capture']='yes'"> -L $(OUTDIR)/capture500.bed </xsl:if> \
		<xsl:if test="/project/properties/property[@key='is.haloplex']='yes'"> --downsample_to_coverage  8000 </xsl:if> \
		$(foreach B,$(filter %.bam,$^), -I $B ) \
		--dbsnp:vcfinput,VCF $(known.sites) \
		-o $(basename $@)
	${TABIX.bgzip} -f $(basename $@)
	@$(call timeendb,$@,UnifiedGenotyper)
	@$(call sizedb,$@)
	$(call notempty,$@)

</xsl:variable>




<xsl:choose>
<xsl:when test="/project/properties/property[@key='one.vcf.per.sample']='yes'">
LIST_PHONY_TARGET+= all_predictions
all_predictions: \
	variations.samtools \
	variations.gatk \
	variations.samtools.snpeff \
	variations.gatk.snpeff \
	variations.samtools.vep \
	variations.gatk.vep


LIST_PHONY_TARGET+= variations.samtools 
variations.samtools: <xsl:for-each select="sample"><xsl:apply-templates select="." mode="vcf.samtools.gz"/></xsl:for-each>
LIST_PHONY_TARGET+= variations.gatk 
variations.gatk: <xsl:for-each select="sample"><xsl:apply-templates select="." mode="vcf.gatk.gz"/></xsl:for-each>
LIST_PHONY_TARGET+= variations.samtools.snpeff 
variations.samtools.snpeff: <xsl:for-each select="sample"><xsl:apply-templates select="." mode="vcf.samtools.snpeff.gz"/></xsl:for-each>
LIST_PHONY_TARGET+= variations.gatk.snpeff  
variations.gatk.snpeff: <xsl:for-each select="sample"><xsl:apply-templates select="." mode="vcf.gatk.snpeff.gz"/></xsl:for-each>
LIST_PHONY_TARGET+= variations.samtools.vep  
variations.samtools.vep: <xsl:for-each select="sample"><xsl:apply-templates select="." mode="vcf.samtools.vep.gz"/></xsl:for-each>
LIST_PHONY_TARGET+= variations.gatk.vep  
variations.gatk.vep: <xsl:for-each select="sample"><xsl:apply-templates select="." mode="vcf.gatk.vep.gz"/></xsl:for-each>


<xsl:for-each select="sample">


#
# prediction samtools with Variation Ensembl Prediction API for  sample <xsl:value-of select="@name"/>
#
<xsl:call-template name="ANNOTATE_WITH_VEP">
	<xsl:with-param name="target"><xsl:apply-templates select="." mode="vcf.samtools.vep.gz"/></xsl:with-param>
	<xsl:with-param name="dependencies"><xsl:apply-templates select="." mode="vcf.samtools.gz"/></xsl:with-param>
	<xsl:with-param name="type">mpileupvep</xsl:with-param>
	<xsl:with-param name="variantfiltration"><xsl:value-of select="/project/properties/property[@key='samtools.vcf.filtration']"/><xsl:text> </xsl:text><xsl:value-of select="/project/properties/property[@key='vep.vcf.filtration']"/></xsl:with-param>
</xsl:call-template>

#
# prediction gatk with Variation Ensembl Prediction API for  sample <xsl:value-of select="@name"/>
#
<xsl:call-template name="ANNOTATE_WITH_VEP">
	<xsl:with-param name="target"><xsl:apply-templates select="." mode="vcf.gatk.vep.gz"/></xsl:with-param>
	<xsl:with-param name="dependencies"><xsl:apply-templates select="." mode="vcf.gatk.gz"/></xsl:with-param>
	<xsl:with-param name="type">gatkvep</xsl:with-param>
	<xsl:with-param name="variantfiltration"><xsl:value-of select="/project/properties/property[@key='gatk.vcf.filtration']"/><xsl:text> </xsl:text><xsl:value-of select="/project/properties/property[@key='vep.vcf.filtration']"/></xsl:with-param>
</xsl:call-template>

#
# Annotation samtools with SNPEFF for  sample <xsl:value-of select="@name"/>
#
<xsl:call-template name="ANNOTATE_WITH_SNPEFF">
	<xsl:with-param name="target"><xsl:apply-templates select="." mode="vcf.samtools.snpeff.gz"/></xsl:with-param>
	<xsl:with-param name="dependencies"><xsl:apply-templates select="." mode="vcf.samtools.gz"/></xsl:with-param>
	<xsl:with-param name="type">mpileupsnpeff</xsl:with-param>
	<xsl:with-param name="variantfiltration"><xsl:value-of select="/project/properties/property[@key='samtools.vcf.filtration']"/><xsl:text> </xsl:text><xsl:value-of select="/project/properties/property[@key='snpeff.vcf.filtration']"/></xsl:with-param>
</xsl:call-template>

#
# Annotation gatk with SNPEFF for  sample <xsl:value-of select="@name"/>
#
<xsl:call-template name="ANNOTATE_WITH_SNPEFF">
	<xsl:with-param name="target"><xsl:apply-templates select="." mode="vcf.gatk.snpeff.gz"/></xsl:with-param>
	<xsl:with-param name="dependencies"><xsl:apply-templates select="." mode="vcf.gatk.gz"/></xsl:with-param>
	<xsl:with-param name="type">gatksnpeff</xsl:with-param>
	<xsl:with-param name="variantfiltration"><xsl:value-of select="/project/properties/property[@key='gatk.vcf.filtration']"/><xsl:text> </xsl:text><xsl:value-of select="/project/properties/property[@key='snpeff.vcf.filtration']"/></xsl:with-param>
</xsl:call-template>

#
# Allele calling with samtools for sample <xsl:value-of select="@name"/>
#
<xsl:apply-templates select="." mode="vcf.samtools.gz"/>: <xsl:if test="/project/properties/property[@key='allele.calling.in.capture']='yes'"> $(OUTDIR)/capture500.bed </xsl:if>  $(call indexed_bam,<xsl:apply-templates select="." mode="recal"/>)
<xsl:value-of select="$call.with.samtools.mpileup"/>

#
# Allele calling with GATK for sample <xsl:value-of select="@name"/>
#
<xsl:apply-templates select="." mode="vcf.gatk.gz"/>: <xsl:if test="/project/properties/property[@key='allele.calling.in.capture']='yes'"> $(OUTDIR)/capture500.bed </xsl:if>  $(call indexed_bam,<xsl:apply-templates select="." mode="recal"/>) $(known.sites)
<xsl:value-of select="$call.with.gatk"/>

</xsl:for-each>
</xsl:when>
<xsl:otherwise>

LIST_PHONY_TARGET+=all_predictions 
all_predictions: \
	$(OUTDIR)/variations.samtools.vep.vcf.gz \
	$(OUTDIR)/variations.samtools.snpEff.vcf.gz \
	$(OUTDIR)/variations.gatk.vep.vcf.gz \
	$(OUTDIR)/variations.gatk.snpEff.vcf.gz 
	
#
# prediction samtools with Variation Ensembl Prediction API
#
<xsl:call-template name="ANNOTATE_WITH_VEP">
	<xsl:with-param name="target">$(OUTDIR)/variations.samtools.vep.vcf.gz</xsl:with-param>
	<xsl:with-param name="dependencies">$(OUTDIR)/variations.samtools.vcf.gz</xsl:with-param>
	<xsl:with-param name="type">samtoolsvep</xsl:with-param>
	<xsl:with-param name="variantfiltration"><xsl:value-of select="/project/properties/property[@key='samtools.vcf.filtration']"/><xsl:text> </xsl:text><xsl:value-of select="/project/properties/property[@key='vep.vcf.filtration']"/></xsl:with-param>
</xsl:call-template>

#
# prediction gatk with Variation Ensembl Prediction API
#
<xsl:call-template name="ANNOTATE_WITH_VEP">
	<xsl:with-param name="target">$(OUTDIR)/variations.gatk.vep.vcf.gz</xsl:with-param>
	<xsl:with-param name="dependencies">$(OUTDIR)/variations.gatk.vcf.gz</xsl:with-param>
	<xsl:with-param name="type">gatkvep</xsl:with-param>
	<xsl:with-param name="variantfiltration"><xsl:value-of select="/project/properties/property[@key='gatk.vcf.filtration']"/><xsl:text> </xsl:text><xsl:value-of select="/project/properties/property[@key='vep.vcf.filtration']"/></xsl:with-param>
</xsl:call-template>

#
# annotate samtools vcf with snpEff
#
<xsl:call-template name="ANNOTATE_WITH_SNPEFF">
	<xsl:with-param name="target">$(OUTDIR)/variations.samtools.snpEff.vcf.gz</xsl:with-param>
	<xsl:with-param name="dependencies">$(OUTDIR)/variations.samtools.vcf.gz</xsl:with-param>
	<xsl:with-param name="type">mpileupsnpeff</xsl:with-param>
	<xsl:with-param name="variantfiltration"><xsl:value-of select="/project/properties/property[@key='samtools.vcf.filtration']"/><xsl:text> </xsl:text><xsl:value-of select="/project/properties/property[@key='snpeff.vcf.filtration']"/></xsl:with-param>
</xsl:call-template>

#
# annotate GATK vcf with snpEff
#
<xsl:call-template name="ANNOTATE_WITH_SNPEFF">
	<xsl:with-param name="target">$(OUTDIR)/variations.gatk.snpEff.vcf.gz</xsl:with-param>
	<xsl:with-param name="dependencies">$(OUTDIR)/variations.gatk.vcf.gz</xsl:with-param>
	<xsl:with-param name="type">gatksnpeff</xsl:with-param>
	<xsl:with-param name="variantfiltration"><xsl:value-of select="/project/properties/property[@key='gatk.vcf.filtration']"/><xsl:text> </xsl:text><xsl:value-of select="/project/properties/property[@key='snpeff.vcf.filtration']"/></xsl:with-param>
</xsl:call-template>

#
# Allele calling with samtools
#
$(OUTDIR)/variations.samtools.vcf.gz: <xsl:if test="/project/properties/property[@key='allele.calling.in.capture']='yes'"> $(OUTDIR)/capture500.bed </xsl:if>  $(call indexed_bam,<xsl:for-each select="sample"><xsl:apply-templates select="." mode="recal"/></xsl:for-each>)
<xsl:value-of select="$call.with.samtools.mpileup"/>

#
# Allele calling with GATK
#
$(OUTDIR)/variations.gatk.vcf.gz: <xsl:if test="/project/properties/property[@key='allele.calling.in.capture']='yes'"> $(OUTDIR)/capture500.bed </xsl:if>  $(call indexed_bam,<xsl:for-each select="sample"><xsl:apply-templates select="." mode="recal"/></xsl:for-each>) $(known.sites)
<xsl:value-of select="$call.with.gatk"/>

</xsl:otherwise>
</xsl:choose>


###################################################################################################################################################
#
# Statistics for BAM
#
LIST_PHONY_TARGET+= bam_statistics 
bam_statistics: $(OUTDIR)/bamstats01.pdf $(OUTDIR)/bamstats03.pdf $(OUTDIR)/bamstats04.tsv beddepth coverage_distribution 


LIST_PHONY_TARGET+= beddepth
beddepth: <xsl:for-each select="sample"><xsl:apply-templates select="." mode="varkit.beddepth"/></xsl:for-each>

#
# create a PDF for bamstats01.tsv
#
$(OUTDIR)/bamstats01.pdf : $(OUTDIR)/bamstats01.tsv
	echo 'pdf("$@",paper="A4r"); T&lt;-read.delim("$&lt;",header=T,sep="\t",row.names=1);barplot(as.matrix(t(T)),beside=TRUE,col=rainbow(8),las=2,cex.names=0.8,legend=colnames(T)); dev.off()' |\
	${R.exe} --no-save

#
# count of mapped-reads	
#
$(OUTDIR)/bamstats01.tsv : <xsl:for-each select="sample"><xsl:apply-templates select="." mode="bamstats01.tsv"/> </xsl:for-each>
	cat $^ |  LC_ALL=C sort -t '	' -k1,1 | uniq > $@


#
# count of distribution of coverage
#
$(OUTDIR)/bamstats04.tsv : <xsl:for-each select="sample"><xsl:apply-templates select="." mode="bamstats04.tsv"/> </xsl:for-each>
	cat $^ |  LC_ALL=C sort -t '	' -k1,1 | uniq > $@




## coverage of distribution ###############################################################

LIST_PHONY_TARGET+= coverage_distribution

coverage_distribution:  $(OUTDIR)/all.distribution.merged.pdf \
			$(OUTDIR)/all.distribution.markdup.pdf \
			$(OUTDIR)/all.distribution.recal.pdf



$(OUTDIR)/all.distribution.merged.pdf : <xsl:for-each select="sample"><xsl:apply-templates select="." mode="coverage.distribution.merged"/></xsl:for-each>
	gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$@ $(filter %.pdf,$^)

$(OUTDIR)/all.distribution.markdup.pdf : <xsl:for-each select="sample"><xsl:apply-templates select="." mode="coverage.distribution.markdup"/></xsl:for-each>
	gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$@ $(filter %.pdf,$^)

$(OUTDIR)/all.distribution.recal.pdf : <xsl:for-each select="sample"><xsl:apply-templates select="." mode="coverage.distribution.recal"/></xsl:for-each>
	gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$@ $(filter %.pdf,$^)


#
# create a PDF for bamstats03.tsv
#
$(OUTDIR)/bamstats03.pdf : $(OUTDIR)/bamstats03.tsv
	echo 'pdf("$@",paper="A4r"); T&lt;-read.delim("$&lt;",header=T,sep="\t",row.names=1);barplot(as.matrix(t(T)),beside=TRUE,col=rainbow(7),las=2,cex.names=0.8,legend=colnames(T)); dev.off()' |\
	${R.exe} --no-save

#
# count of mapped-reads, quality per sample	
#
$(OUTDIR)/bamstats03.tsv : $(call indexed_bam,<xsl:for-each select="sample"><xsl:apply-templates select="." mode="recal"/></xsl:for-each>)  $(capture.bed) 
	@$(call timebegindb,$@,$@)
	${VARKIT}/bamstats03 -b $(capture.bed) $(filter %.bam,$^) | awk -F '/' '{print $$NF;}'  | sort  > $@
	@$(call timeendb,$@,$@)
	@$(call sizedb,$@)
	$(call notempty,$@)


###################################################################################################################################################
#
# Capture
#

$(OUTDIR)/ensembl.exons.bed:
	$(call timebegindb,$@,$@)
	curl <xsl:value-of select="$set_curl_proxy"/> -d 'query=<![CDATA[<?xml version="1.0" encoding="UTF-8"?><Query virtualSchemaName="default" formatter="TSV" header="0" uniqueRows="0" count="" datasetConfigVersion="0.6" ><Dataset name="]]><xsl:choose>
		<xsl:when test="properties/property[@key='ensembl.dataset.name']"><xsl:value-of select="properties/property[@key='ensembl.dataset.name']"/></xsl:when>
		<xsl:otherwise>hsapiens_gene_ensembl</xsl:otherwise>
		</xsl:choose><![CDATA[" interface="default" ><Attribute name="chromosome_name" /><Attribute name="exon_chrom_start" /><Attribute name="exon_chrom_end" /></Dataset></Query>]]>' "http://www.biomart.org/biomart/martservice/result" |\
	grep -v '_' |grep -v 'GL' |grep -v 'MT' |\
	awk -F '	' '(int($$2) &lt; int($$3))' |\
	uniq | LC_ALL=C sort -t '	' -k1,1 -k2,2n -k3,3n |\
	$(BEDTOOLS)/mergeBed -i - | uniq &gt; $@
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
$(addsuffix .sample_summary,<xsl:apply-templates select="." mode="coverage"/>) : $(call indexed_bam,<xsl:apply-templates select="." mode="recal"/>) $(capture.bed)
	$(call timebegindb,<xsl:apply-templates select="." mode="coverage"/>,coverage.gatk)
	$(JAVA) $(GATK.jvm) -jar $(GATK.jar) $(GATK.flags) \
		-R $(REF) \
		-T DepthOfCoverage \
		-L:capture,BED $(filter %.bed,$^) \
		-S SILENT \
		--minMappingQuality $(MIN_MAPPING_QUALITY) \
		-omitBaseOutput \
		--summaryCoverageThreshold 5 \
		-I $(filter %.bam,$^) \
		-o <xsl:apply-templates select="." mode="coverage"/>
	$(call timeendb,<xsl:apply-templates select="." mode="coverage"/>,coverage.gatk)




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
<xsl:choose>
<xsl:when  test="/project/properties/property[@key='disable.recalibration']='yes'">
<xsl:apply-templates select="." mode="recal"/> : $(call indexed_bam,<xsl:apply-templates select="." mode="markdup"/>)
	#just create a symbolic link
	$(call create_symbolic_link,$(filter %.bam,$^),$@)
	##ln -s --force $(filter %.bai,$^) $(addsuffix .bai,$@)

</xsl:when>
<xsl:otherwise>
<xsl:apply-templates select="." mode="recal"/> : $(call indexed_bam,<xsl:apply-templates select="." mode="markdup"/>) $(OUTDIR)/capture500.bed $(known.sites)
	@$(call timebegindb,$@_countCovariates,covariates)
	$(JAVA) $(GATK.jvm) -jar $(GATK.jar) $(GATK.flags) \
		-T BaseRecalibrator \
		-R $(REF) \
		-I $(filter %.bam,$^) \
		-l INFO \
		<xsl:choose>
			  <xsl:when test="/project/properties/property[@key='gatk.base.recalibrator.options']">
			  	<xsl:value-of select="/project/properties/property[@key='gatk.base.recalibrator.options']"/>
			  </xsl:when>
			  <xsl:otherwise>
			  	<!-- no option   -->
			  </xsl:otherwise>
			</xsl:choose> \
		-o $@.recal_data.grp \
		-knownSites:vcfinput,VCF $(known.sites) \
		-L $(filter %.bed,$^) \
		-cov ReadGroupCovariate \
		-cov QualityScoreCovariate \
		-cov CycleCovariate \
		-cov ContextCovariate
	@$(call timeenddb,$@_countCovariates,covariates)
	@$(call timebegindb,$@_tableRecalibaration,recalibration)
	$(JAVA) $(GATK.jvm) -jar $(GATK.jar) $(GATK.flags) \
		-T PrintReads \
		--disable_bam_indexing \
		-R $(REF) \
		-BQSR $@.recal_data.grp \
		-I $(filter %.bam,$^) \
		<xsl:choose>
		  <xsl:when test="/project/properties/property[@key='gatk.recalibration.print.reads.options']">
		  	<xsl:value-of select="/project/properties/property[@key='gatk.recalibration.print.reads.options']"/>
		  </xsl:when>
		  <xsl:otherwise>
		  	<!-- no option   -->
		  </xsl:otherwise>
		</xsl:choose> \
		-o $@ \
		-l INFO
	@$(call timeenddb,$@_tableRecalibaration,recalibration)
	@$(call sizedb,$@)
	rm -f $@.recal_data.grp
	$(call notempty,$@)
	$(call delete_and_touch,$(filter %.bam,$^) )
	$(call delete_and_touch,$(filter %.bai,$^) )
	touch $@

</xsl:otherwise>
</xsl:choose>

#
#
# Mark duplicates for Sample: <xsl:value-of select="@name"/>
#
LIST_BAM_MARKDUP+=<xsl:apply-templates select="." mode="markdup"/><xsl:text>
</xsl:text>
<xsl:apply-templates select="." mode="markdup"/> : $(call indexed_bam,<xsl:apply-templates select="." mode="realigned"/>)
<xsl:choose>
<xsl:when  test="/project/properties/property[@key='disable.mark.duplicates']='yes' or /project/properties/property[@key='is.haloplex']='yes'">
<xsl:message>[WARNING] Mark Duplicate Disabled.</xsl:message>	#just create a symbolic link
	$(call create_symbolic_link,$(filter %.bam,$^),$@)
	##ln -s --force $(filter %.bai,$^) $(addsuffix .bai,$@)
	
</xsl:when>
<xsl:when test="/project/properties/property[@key='use.samtools.rmdup']='yes'">	@$(call timebegindb,$@_markdup,markdup)
	$(SAMTOOLS) rmdup $(filter %.bam,$^) $@
	@$(call sizedb,$@)
	$(call notempty,$@)
	$(call delete_and_touch,$(filter %.bam,$^) )
	$(call delete_and_touch,$(filter %.bai,$^) )

</xsl:when>
<xsl:otherwise>	$(call timebegindb,$@_markdup,markdup)
	mkdir -p $(addsuffix tmp.rmdup,$(dir $@))
	$(JAVA) $(PICARD.jvm) -jar $(PICARD)/MarkDuplicates.jar \
		TMP_DIR=$(addsuffix tmp.rmdup,$(dir $@)) \
		INPUT=$(filter %.bam,$^) \
		O=$@ \
		MAX_FILE_HANDLES=400 \
		M=$@.metrics \
		AS=true \
		<xsl:choose>
		  <xsl:when test="/project/properties/property[@key='picard.mark.duplicates.options']">
		  	<xsl:value-of select="/project/properties/property[@key='picard.mark.duplicates.options']"/>
		  </xsl:when>
		  <xsl:otherwise>
		  	<!-- no option   -->
		  </xsl:otherwise>
		</xsl:choose> \
		VALIDATION_STRINGENCY=SILENT
	@$(call timeenddb,$@_markdup,markdup)
	@$(call sizedb,$@)
	$(call notempty,$@)
	$(call delete_and_touch,$(filter %.bam,$^) )
	$(call delete_and_touch,$(filter %.bai,$^) )
	touch $@

<!--
pas utilisé
#$(call timebegindb,$@_fixmate,fixmate)
	#$(JAVA) $(PICARD.jvm) -jar $(PICARD)/FixMateInformation.jar  TMP_DIR=$(OUTDIR) INPUT=$@  VALIDATION_STRINGENCY=SILENT
	#$(call timendedb,$@_fixmate,fixmate)
	#$(SAMTOOLS) index $@
	#$(call timebegindb,$@_validate,validate)
	#$(JAVA) $(PICARD.jvm) -jar $(PICARD)/ValidateSamFile.jar TMP_DIR=$(OUTDIR) VALIDATE_INDEX=true I=$@  CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT IGNORE_WARNINGS=true
	#$(call timeenddb,$@_validate,validate)

-->

</xsl:otherwise>
</xsl:choose>

#
#
# IndelRealignments for Sample &quot;<xsl:value-of select="@name"/>&quot;
#
#
LIST_BAM_REALIGN+=<xsl:apply-templates select="." mode="realigned"/><xsl:text>
</xsl:text>
<xsl:choose>
<xsl:when  test="/project/properties/property[@key='disable.indelrealigner']='yes'">
<xsl:apply-templates select="." mode="realigned"/> : $(call indexed_bam,<xsl:apply-templates select="." mode="merged"/>)
	#just create a symbolic link
	$(call create_symbolic_link,$(filter %.bam,$^),$@)
	##ln --force -s $(filter %.bai,$^) $(addsuffix .bai,$@)

</xsl:when>
<xsl:otherwise>
<xsl:apply-templates select="." mode="realigned"/>: $(call indexed_bam,<xsl:apply-templates select="." mode="merged"/>) $(OUTDIR)/capture500.bed
		@$(call timebegindb,$@_targetcreator,targetcreator)
		$(JAVA) $(GATK.jvm) -jar $(GATK.jar) $(GATK.flags) \
			-T RealignerTargetCreator \
  			-R $(REF) \
			-L $(filter %.bed,$^) \
  			-I $(filter %.bam,$^) \
			-S SILENT \
			<xsl:choose>
			  <xsl:when test="/project/properties/property[@key='gatk.realigner.target.creator.options']">
			  	<xsl:value-of select="/project/properties/property[@key='gatk.realigner.target.creator.options']"/>
			  </xsl:when>
			  <xsl:otherwise>
			  	<!-- no option   -->
			  </xsl:otherwise>
			</xsl:choose> \
  			-o $(addsuffix .intervals, $(filter %.bam,$^) ) \
			--known:vcfinput,VCF <xsl:choose>
			  <xsl:when test="/project/properties/property[@key='known.indels.vcf']">
			  	<xsl:value-of select="/project/properties/property[@key='known.indels.vcf']"/>
			  </xsl:when>
			  <xsl:otherwise>
			  	<xsl:message terminate="yes">known.indels.vcf undefined</xsl:message>
			  </xsl:otherwise>
			</xsl:choose>
		@$(call timeenddb,$@_targetcreator,targetcreator)
		@$(call timebegindb,$@_indelrealigner,indelrealign)
		$(JAVA) $(GATK.jvm) -jar  $(GATK.jar) $(GATK.flags) \
  			-T IndelRealigner \
  			-R $(REF) \
  			-I $(filter %.bam,$^) \
			-S SILENT \
			<xsl:choose>
			  <xsl:when test="/project/properties/property[@key='gatk.indel.realigner.options']">
			  	<xsl:value-of select="/project/properties/property[@key='gatk.indel.realigner.options']"/>
			  </xsl:when>
			  <xsl:otherwise>
			  	<!-- no option   -->
			  </xsl:otherwise>
			</xsl:choose> \
  			-o $@ \
  			-targetIntervals $(addsuffix .intervals, $(filter %.bam,$^) ) \
			--knownAlleles:vcfinput,VCF <xsl:choose>
			  <xsl:when test="/project/properties/property[@key='known.indels.vcf']">
			  	<xsl:value-of select="/project/properties/property[@key='known.indels.vcf']"/>
			  </xsl:when>
			  <xsl:otherwise>
			  	<xsl:message terminate="yes">known.indels.vcf undefined</xsl:message>
			  </xsl:otherwise>
			</xsl:choose>
		@$(call timeenddb,$@_indelrealigner,indelrealign)
		@$(call sizedb,$@)
		$(call notempty,$@)
		rm -f $(addsuffix .intervals, $(filter %.bam,$^) )
		$(call delete_and_touch,$(filter %.bam,$^)  )
		$(call delete_and_touch,$(filter %.bam.bai,$^)  )
		touch $@

</xsl:otherwise>
</xsl:choose>

<xsl:if test="count(sequences/pair)&gt;1">
#
#
# Merge all Bams for Sample &quot;<xsl:value-of select="@name"/>&quot;
#
#
LIST_BAM_MERGED+=<xsl:apply-templates select="." mode="merged"/><xsl:text>
</xsl:text>
<xsl:apply-templates select="." mode="merged"/> : <xsl:for-each select="sequences/pair"><xsl:apply-templates select="." mode="sorted"/></xsl:for-each>
	@$(call timebegindb,$@,merge)
	$(JAVA) -jar $(PICARD)/MergeSamFiles.jar O=$@ AS=true \
		<xsl:choose>
		  <xsl:when test="/project/properties/property[@key='picard.merge.options']">
		  	<xsl:value-of select="/project/properties/property[@key='picard.merge.options']"/>
		  </xsl:when>
		  <xsl:otherwise>
		  	<!-- picard.merge.options   -->
		  </xsl:otherwise>
		</xsl:choose> VALIDATION_STRINGENCY=SILENT \
		COMMENT="Merged from $^" \
		$(foreach B,$^, I=$(B) )
	$(DELETEFILE) $^
	@$(call timeenddb,$@,merge)
	@$(call sizedb,$@)
	$(call notempty,$@)
	$(call delete_and_touch,$^)
	touch $@
	
</xsl:if>

<!-- bamstats01-->

#
# bamstats01 for sample: <xsl:value-of select="@name"/>
#
<xsl:apply-templates select="." mode="bamstats01.tsv"/> : $(call indexed_bam, <xsl:apply-templates select="." mode="recal"/>) $(capture.bed)
	@$(call timebegindb,$@,bamstats01)
	mkdir -p $(dir $@)
	${VARKIT}/bamstats01 -b $(capture.bed) $(filter %.bam,$^) | sed -e 's/_recal.bam//' -e "s%$(dir $(filter %.bam,$^))%%" > $@
	@$(call timeendb,$@,bamstats01)
	@$(call sizedb,$@)
	$(call notempty,$@)
	
#
# bamstats04 for sample: <xsl:value-of select="@name"/>
#
<xsl:apply-templates select="." mode="bamstats04.tsv"/> : $(call indexed_bam, <xsl:apply-templates select="." mode="recal"/>) $(capture.bed)
	@$(call timebegindb,$@,bamstats04)
	mkdir -p $(dir $@)
	$(JAVA) -jar ${JVARKIT}/bamstats04.jar -b $(capture.bed) $(filter %.bam,$^) | sed -e 's/_recal.bam//' -e "s%$(dir $(filter %.bam,$^))%%" > $@
	@$(call timeendb,$@,bamstats04)
	@$(call sizedb,$@)
	$(call notempty,$@)
	


<!-- distribution of coverage -->
<xsl:call-template name="DISTRIBUTION_OF_COVERAGE">
	<xsl:with-param name="target"><xsl:apply-templates select="." mode="coverage.distribution.merged"/></xsl:with-param>
	<xsl:with-param name="dependencies"><xsl:apply-templates select="." mode="merged"/></xsl:with-param>
	<xsl:with-param name="type">depthofcovdist</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="DISTRIBUTION_OF_COVERAGE">
	<xsl:with-param name="target"><xsl:apply-templates select="." mode="coverage.distribution.markdup"/></xsl:with-param>
	<xsl:with-param name="dependencies"><xsl:apply-templates select="." mode="markdup"/></xsl:with-param>
	<xsl:with-param name="type">depthofcovdist</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="DISTRIBUTION_OF_COVERAGE">
	<xsl:with-param name="target"><xsl:apply-templates select="." mode="coverage.distribution.recal"/></xsl:with-param>
	<xsl:with-param name="dependencies"><xsl:apply-templates select="." mode="recal"/></xsl:with-param>
	<xsl:with-param name="type">depthofcovdist</xsl:with-param>
</xsl:call-template>



<xsl:call-template name="VARKIT_BEDDEDPTH">
	<xsl:with-param name="target"><xsl:apply-templates select="." mode="varkit.beddepth"/></xsl:with-param>
	<xsl:with-param name="dependencies"><xsl:apply-templates select="." mode="recal"/></xsl:with-param>
</xsl:call-template>



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
	$(SAMTOOLS) sort <xsl:choose><xsl:when test="/project/properties/property[@key='samtools.sort.options']">
	  	<xsl:value-of select="/project/properties/property[@key='samtools.sort.options']"/>
	  </xsl:when>
	  <xsl:otherwise>
	  	<!-- no samtools.sort option   -->
	  </xsl:otherwise>
	</xsl:choose> $&lt; $(basename $@)
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
<xsl:apply-templates select="." mode="unsorted"/> : <xsl:apply-templates select="fastq[@index='1']" mode="preprocessed.fastq"/>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="fastq[@index='2']" mode="preprocessed.fastq"/>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="fastq[@index='1']" mode="sai"/>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="fastq[@index='2']" mode="sai"/>
	## ALIGN WITH BWA #######################################################################
	@$(call timebegindb,$@,bwasampe)
	$(BWA) sampe <xsl:choose>
	  <xsl:when test="/project/properties/property[@key='bwa.sampe.options']">
	  	<xsl:value-of select="/project/properties/property[@key='bwa.sampe.options']"/>
	  </xsl:when>
	  <xsl:otherwise>
	  	<!-- no bwa.sampe option $(BWA.aln.options)  -->
	  	<xsl:text> -a </xsl:text>
	  	<xsl:apply-templates select="." mode="fragmentSize"/> 
	  	<xsl:text> </xsl:text>
	  </xsl:otherwise>
	</xsl:choose>  \
		-r "@RG	ID:<xsl:value-of select="generate-id(.)"/>	LB:<xsl:value-of select="../../@name"/>	SM:<xsl:value-of select="../../@name"/>	PL:ILLUMINA	PU:<xsl:value-of select="@lane"/>" \
		${REF} \
		<xsl:apply-templates select="fastq[@index='1']" mode="sai"/> \
		<xsl:apply-templates select="fastq[@index='2']" mode="sai"/> \
		<xsl:apply-templates select="fastq[@index='1']" mode="preprocessed.fastq"/> \
		<xsl:apply-templates select="fastq[@index='2']" mode="preprocessed.fastq"/> |\
	$(SAMTOOLS) view -S -b -o $@ -T ${REF} -
	$(DELETEFILE) <xsl:apply-templates select="fastq" mode="sai"/> <xsl:for-each select="fastq">
		<xsl:if test="number($limit)&gt;0 or substring(@path, string-length(@path)- 3)='.bz2'">
			<xsl:text> </xsl:text>
			<xsl:apply-templates select="." mode="preprocessed.fastq"/>
		</xsl:if>
	</xsl:for-each> 
	@$(call timeenddb,$@,bwasampe)
	@$(call sizedb,$@)
	@$(call notempty,$@)
	@$(call delete_and_touch,$(filter %.sai,$^))
	touch $@




<!-- if the simulation.reads is set and greater than 0, the two fastqs will be created -->
<xsl:if test="number(/project/properties/property[@key='simulation.reads'])&gt;0">
<xsl:variable name="twofastqs">
<xsl:apply-templates select="fastq[@index='1']" mode="raw.fastq"/>
<xsl:text> </xsl:text>
<xsl:apply-templates select="fastq[@index='2']" mode="raw.fastq"/>
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

##
## BEGIN : loop over the fastqs
##
<xsl:for-each select="fastq">
<xsl:text>

</xsl:text>

<xsl:choose>
<xsl:when test="substring(@path, string-length(@path)- 3)='.bz2'">

#need to convert from bz2 to gz
<xsl:apply-templates select="." mode="preprocessed.fastq"/>:<xsl:value-of select="@path"/>
	mkdir -p <xsl:apply-templates select="." mode="dir"/>
	bunzip -c $&lt; | <xsl:if test="number($limit)&gt;0"> head -n <xsl:value-of select="number($limit)*4"/> |</xsl:if> gzip --best &gt; $@

</xsl:when>

<xsl:when test="number($limit)&gt;0">
<xsl:apply-templates select="." mode="preprocessed.fastq"/>:<xsl:value-of select="@path"/><xsl:text> </xsl:text><xsl:apply-templates select="." mode="dir"/>
	gunzip -c $&lt; | head  -n <xsl:value-of select="number($limit)*4"/> | gzip --best &gt; $@	
</xsl:when>

</xsl:choose>


<xsl:apply-templates select="." mode="sai"/>:<xsl:apply-templates select="." mode="preprocessed.fastq"/> $(INDEXED_REFERENCE)
	mkdir -p $(dir $@)
	@$(call timebegindb,$@,sai)
	@$(call sizedb,$&lt;)
	$(BWA) aln <xsl:choose>
	  <xsl:when test="/project/properties/property[@key='bwa.aln.options']">
	  	<xsl:value-of select="/project/properties/property[@key='bwa.aln.options']"/>
	  </xsl:when>
	  <xsl:otherwise>
	  	<!-- no bwa.aln option $(BWA.aln.options)  -->
	  </xsl:otherwise>
	</xsl:choose> -f $@ ${REF} $&lt;
	@$(call timeenddb,$@,sai)
	@$(call sizedb,$@)
	@$(call notempty,$@)



<!-- using haloplex ? need to preprocess the fastqs -->
<xsl:if test="/project/properties/property[@key='is.haloplex']='yes'">
#
# Preprocess FASTQ
#
<xsl:apply-templates select="." mode="preprocessed.fastq"/>: <xsl:apply-templates select="." mode="raw.fastq"/>
	mkdir -p $(dir $@)
	@$(call timebegindb,$@,cutadapt)
	@$(call sizedb,$&lt;)
	$(CUTADAPT) -b <xsl:choose>
	  <xsl:when test="/project/properties/property[@key='cutadapt.sequence.for'] and @index='1' ">
	  	<xsl:value-of select="/project/properties/property[@key='cutadapt.sequence.for']"/>
	  </xsl:when>
	   <xsl:when test="/project/properties/property[@key='cutadapt.sequence.rev'] and @index='2' ">
	  	<xsl:value-of select="/project/properties/property[@key='cutadapt.sequence.rev']"/>
	  </xsl:when>
	  <xsl:when test="@index='1'">
	  	<xsl:text>AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC</xsl:text>
	  </xsl:when>
	  <xsl:when test="@index='2'">
	  	<xsl:text>AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTAGATCTCGGTGGTCGCCGTATCATT</xsl:text>
	  </xsl:when> 
	  <xsl:otherwise>
	  	<xsl:message terminate="yes">error with xsl:choose statement of cutadapt</xsl:message>
	  </xsl:otherwise>
	</xsl:choose> $&lt; -o $(basename $@) > $(addsuffix .report.txt,$@)
	gzip --best --force $(basename $@)
	@$(call timeenddb,$@,cutadapt)
	@$(call sizedb,$@)
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

<xsl:apply-templates select="." mode="tophat"/>
<xsl:apply-templates select="." mode="fastx"/>

#####################################################################################
#
# statistics from HSQLDB
#
LIST_PHONY_TARGET+= hsqldb_statistics 
hsqldb_statistics: $(OUTDIR)/durations.stats.txt $(OUTDIR)/filesize.stats.txt

$(OUTDIR)/durations.stats.txt:
	lockfile $(LOCKFILE)
	-$(JAVA) -jar ${HSQLDB.sqltool} --autoCommit --inlineRc=url=jdbc:hsqldb:file:$(HSQLSTATS) \
		--sql "select B.category$(foreach T,SECOND MINUTE HOUR DAY, ,AVG(TIMESTAMPDIFF(SQL_TSI_${T},B.W,E.W)) as duration_${T}) from begindb as B ,enddb as E where B.file=E.file group by B.category;" > $@
	rm -f $(LOCKFILE)

$(OUTDIR)/filesize.stats.txt:
	lockfile $(LOCKFILE)
	-$(JAVA) -jar ${HSQLDB.sqltool} --autoCommit --inlineRc=url=jdbc:hsqldb:file:$(HSQLSTATS) \
		--sql "select B.category,count(*) as N, AVG(L.size) as AVG_FILESIZE from begindb as B ,sizedb as L where B.file=L.file group by B.category;" > $@
	rm -f $(LOCKFILE)

######################################################################################
#
# list target(s) for which processing has been canceled or is still
# an ongoing process.
#
LIST_PHONY_TARGET+= ongoing
ongoing:
	lockfile $(LOCKFILE)
	-$(JAVA) -jar ${HSQLDB.sqltool} --autoCommit --inlineRc=url=jdbc:hsqldb:file:$(HSQLSTATS) \
		--sql "select B.file,B.w,E.file,E.w,B.category from begindb as B LEFT JOIN enddb as E on ( B.file=E.file and B.category=E.category ) where E.file is NULL or B.w &gt;= E.w order by B.file ;" 
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
LIST_PHONY_TARGET+= build_bowtie_index 
build_bowtie_index:$(BOWTIE_INDEXED_REFERENCE)
$(filter-out %.1.bt2,$(BOWTIE_INDEXED_REFERENCE)): $(filter  %.1.bt2,$(BOWTIE_INDEXED_REFERENCE))
$(filter  %.1.bt2,$(BOWTIE_INDEXED_REFERENCE)): $(REF)
	${BOWTIE2.dir}/bowtie2-build  -f $(REF) $(basename $(REF))
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

################################################################################################
#
# track project changes with git
#
#
LIST_PHONY_TARGET+= git 
git:.git/config
	-git add $(makefile.name)
	-git commit -m "changes $(makefile.name)"
	
.git/config:
	git init $(dir $(makefile.name))

</xsl:template>


<xsl:template match="fastq" mode="dir">
	<xsl:apply-templates select="../../.." mode="dir"/>
</xsl:template>

<xsl:template match="fastq" mode="preprocessed.fastq">
<xsl:choose>
 <xsl:when test="/project/properties/property[@key='is.haloplex']='yes'">
	<xsl:variable name="p"><xsl:apply-templates select=".." mode="pairname"/></xsl:variable>
	<xsl:text>$(OUTDIR)/</xsl:text><xsl:value-of select="concat(../../../@name,'/$(TMPREFIX)',$p,'_',@index,'.preproc.fastq.gz ')"/>
 </xsl:when>
 <xsl:otherwise>
	<xsl:apply-templates select="." mode="raw.fastq"/>
 </xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:template match="fastq" mode="raw.fastq">
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

<!-- distribution of coverage   -->
<xsl:template match="sample" mode="coverage.distribution.merged">
<xsl:text>$(dir </xsl:text>
<xsl:apply-templates select="." mode="merged"/>
<xsl:text>)</xsl:text>
<xsl:value-of select="concat(@name,'.merged.coverage.pdf')"/>
<xsl:text> </xsl:text>
</xsl:template>

<xsl:template match="sample" mode="coverage.distribution.markdup">
<xsl:text>$(dir </xsl:text>
<xsl:apply-templates select="." mode="markdup"/>
<xsl:text>)</xsl:text>
<xsl:value-of select="concat(@name,'.markdup.coverage.pdf')"/>
<xsl:text> </xsl:text>
</xsl:template>

<xsl:template match="sample" mode="coverage.distribution.recal">
<xsl:text>$(dir </xsl:text>
<xsl:apply-templates select="." mode="recal"/>
<xsl:text>)</xsl:text>
<xsl:value-of select="concat(@name,'.recal.coverage.pdf')"/>
<xsl:text> </xsl:text>
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


<xsl:template match="sample" mode="vcf.samtools.gz">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_variations.samtools.vcf.gz ')"/>
</xsl:template>

<xsl:template match="sample" mode="vcf.gatk.gz">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_variations.gatk.vcf.gz ')"/>
</xsl:template>

<xsl:template match="sample" mode="vcf.samtools.snpeff.gz">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_variations.samtools.snpeff.vcf.gz ')"/>
</xsl:template>

<xsl:template match="sample" mode="vcf.gatk.snpeff.gz">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_variations.gatk.snpeff.vcf.gz ')"/>
</xsl:template>

<xsl:template match="sample" mode="vcf.samtools.vep.gz">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_variations.samtools.vep.vcf.gz ')"/>
</xsl:template>

<xsl:template match="sample" mode="vcf.gatk.vep.gz">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_variations.gatk.vep.vcf.gz ')"/>
</xsl:template>


<xsl:template match="sample" mode="bamstats01.tsv">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_bamstats01.tsv ')"/>
</xsl:template>

<xsl:template match="sample" mode="bamstats04.tsv">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_bamstats04.tsv ')"/>
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
	@$(call timebegindb,$@,bai)
	$(SAMTOOLS) index $&lt;
	@$(call timeenddb,$@,bai)
	@$(call sizedb,$@)
	$(call notempty,$@)
	

</xsl:text>
</xsl:template>

<!-- =======================================
        BEDDEPTH
     ======================================= -->
<xsl:template match="sample" mode="varkit.beddepth">
<xsl:apply-templates select="." mode="dir"/>
<xsl:value-of select="concat('/',@name,'_beddepth.tsv.gz ')"/>
</xsl:template>   


     
<!-- ======================================================================================================
     
   	TOPHAT
     
     ====================================================================================================== -->
<xsl:template match="sample" mode="tophat.dir">
<xsl:variable name="p"><xsl:apply-templates select="." mode="dir"/></xsl:variable>
<xsl:value-of select="concat($p,'/TOPHAT/')"/>
</xsl:template>

<xsl:template match="pair" mode="tophat.dir">
<xsl:variable name="s1"><xsl:apply-templates select="../.." mode="tophat.dir"/></xsl:variable>
<xsl:variable name="s2"><xsl:apply-templates select="." mode="pairname"/></xsl:variable>
<xsl:value-of select="concat($s1,$s2,'/')"/>
</xsl:template>

<xsl:template match="pair" mode="tophat.accepted_hits.bam">
<xsl:text>$(addsuffix accepted_hits.bam,</xsl:text>
<xsl:apply-templates select="." mode="tophat.dir"/>
<xsl:text>)</xsl:text>
</xsl:template>


<xsl:template match="pair" mode="tophat.transcripts.gtf">
<xsl:text>$(addsuffix  transcripts.gtf,</xsl:text>
<xsl:apply-templates select="." mode="tophat.dir"/>
<xsl:text>)</xsl:text>
</xsl:template>

<xsl:template match="pair" mode="tophat">
#
# cufflinks: assemble transcripts for sample '<xsl:value-of select="../../@name"/>'
#
<xsl:apply-templates select="." mode="tophat.transcripts.gtf"/>: <xsl:apply-templates select="." mode="tophat.accepted_hits.bam"/>
	mkdir -p $(dir $@)
	$(call timebegindb,$@,tophat_accepted_hits)
	$(CUFFLINKS.dir)/cufflinks -o $(dir $@) $&lt;
	$(call timeenddb,$@,tophat_accepted_hits)

#
# tophat: Align the RNA-seq reads to the genome for sample '<xsl:value-of select="../../@name"/>'
#
<xsl:apply-templates select="." mode="tophat.accepted_hits.bam"/> : <xsl:apply-templates select="fastq[@index='1']" mode="preprocessed.fastq"/> \
	<xsl:apply-templates select="fastq[@index='2']" mode="preprocessed.fastq"/> \
	$(BOWTIE_INDEXED_REFERENCE) \
	$(exons.gtf)
	mkdir -p $(dir $@)
	$(call timebegindb,$@,tophat_accepted_hits)
	#tophat requires a .fa extension
	$(foreach F,$(filter %.fasta,$(REF)), if [ ! -f $(basename $F).fa ]; then ln -s --force $F $(basename $F).fa; fi; )
	${TOPHAT.dir}/tophat2 -G $(exons.gtf) -o $(dir $@) \
		--rg-id  <xsl:value-of select="generate-id(.)"/> \
		--rg-library <xsl:value-of select="../../@name"/> \
		--rg-sample <xsl:value-of select="../../@name"/> \
		--rg-description <xsl:value-of select="../../@name"/> \
		--rg-platform-unit <xsl:value-of select="concat('L',@lane)"/> \
		--rg-center Nantes \
		--rg-platform Illumina \
		$(basename $(REF)) \
		<xsl:apply-templates select="fastq[@index='1']" mode="preprocessed.fastq"/> \
		<xsl:apply-templates select="fastq[@index='2']" mode="preprocessed.fastq"/>
	$(call sizedb,$@)
	$(call timeenddb,$@,tophat_accepted_hits)

</xsl:template>


<xsl:template match="sample" mode="tophat">
<xsl:apply-templates select="sequences/pair" mode="tophat"/>
</xsl:template>



<xsl:template match="project" mode="tophat">
##############################################################################################
#
#  BEGIN TOPHAT 
#
#
LIST_PHONY_TARGET+= all_tophat
all_tophat: $(OUTDIR)/diff_out/gene_exp.diff

#
# identify differencially expressed genes and transcripts
#
$(OUTDIR)/diff_out/gene_exp.diff : $(OUTDIR)/merged_asm/merged.gtf \
	<xsl:for-each select="sample/sequences/pair"><xsl:text> </xsl:text><xsl:apply-templates select="." mode="tophat.accepted_hits.bam"/></xsl:for-each>
	$(call timebegindb,$@,tophat_cuffdiff)
	$(CUFFLINKS.dir)/cuffdiff -v -o $(dir $@) \
		-b $(REF) \
		-L <xsl:for-each select="sample"><xsl:if test="position()&gt;1">,</xsl:if><xsl:value-of select="@name"/></xsl:for-each> \
		-u $&lt; \
		<xsl:for-each select="sample"><xsl:text> </xsl:text><xsl:for-each select="sequences/pair"><xsl:if test="position()&gt;1">,</xsl:if><xsl:apply-templates select="." mode="tophat.accepted_hits.bam"/></xsl:for-each></xsl:for-each>
	$(call timeenddb,$@,tophat_cuffdiff)	

#
# Run cuffmerge to create a single merged transcription annotation
#
$(OUTDIR)/merged_asm/merged.gtf : $(OUTDIR)/tophat.assemblies.txt $(exons.gtf) $(BOWTIE_INDEXED_REFERENCE)
	$(call timebegindb,$@,tophat_cuffmerge)
	$(CUFFLINKS.dir)/cuffmerge -o $(dir $@) -g $(exons.gtf) -s $(REF) $&lt;
	$(call timeenddb,$@,tophat_cuffmerge)	

#
# assembly file for cuffmerge
#
$(OUTDIR)/tophat.assemblies.txt: <xsl:for-each select="sample/sequences/pair"><xsl:text> </xsl:text><xsl:apply-templates select="." mode="tophat.transcripts.gtf"/></xsl:for-each>
	mkdir -p $(dir $@)
	rm -f $@
	$(foreach F,$^, echo "$F" &gt;&gt; $@ ; )
	
<xsl:apply-templates select="sample" mode="tophat"/>


#
#  END TOPHAT
#
##############################################################################################

</xsl:template>

<!-- ======================================================================================================
     
   	FASTX
     
     ====================================================================================================== -->

<xsl:template match="project" mode="fastx">
#
# merge all the FASTX reports in one PDF
#
LIST_PHONY_TARGET+= fastx
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
	$(FASTX.dir)/bin/fastx_quality_stats  -Q33 &gt; <xsl:value-of select="$stat"/>
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

<!-- ======================================================================================================
     
   	FREEBAYES
     
     ====================================================================================================== -->
<xsl:template match="project" mode="freebayes">
#
# FREEBAYES
#
LIST_PHONY_TARGET+= freebayes

freebayes:$(OUTDIR)/freebayes.vcf.gz 
$(OUTDIR)/freebayes.vcf.gz : $(call indexed_bam,<xsl:apply-templates select="sample" mode="merged"/>)
	${freebayes.bin} $(foreach B,$(filter %.bam,$^), -b ${B} ) -o $(basename $@) -f ${REF}
	${TABIX.bgzip} -f $(basename $@)
	${TABIX.tabix} -f -p vcf $@ 
</xsl:template>




<!-- ===================================================================================== -->

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


<xsl:template name="ANNOTATE_WITH_SNPEFF">
<xsl:param name="target"/>
<xsl:param name="dependencies"/>
<xsl:param name="type"/>
<xsl:param name="variantfiltration"/>
#
# Annotation of <xsl:value-of select="$dependencies"/>
#
<xsl:value-of select="$target"/> : <xsl:value-of select="$dependencies"/> $(REF)
	#Annotation of $&lt; with SNPEFF 
	@$(call timebegindb,$@,<xsl:value-of select="$type"/>)
	gunzip -c  $&lt; |\
	egrep -v '^GL' |\
	$(VARKIT)/missingvcf -S missing |\
	$(JAVA) -jar $(SNPEFF)/snpEff.jar eff -i vcf -o vcf -c $(SNPEFF)/snpEff.config  $(SNPEFFBUILD) |\
	$(SNPEFF)/scripts/vcfEffOnePerLine.pl  <xsl:if test="/project/properties/property[@key='discard.intergenic.variants']/text()='yes'"> | grep -v ";EFF=INTERGENIC(" </xsl:if> <xsl:value-of select="/project/properties/property[@key='downstream.vcf.annotation']/text()"/>  | LC_ALL=C sort -t '	' -k1,1 -k2,2n -k4,4 -k5,5  |\
	$(VARKIT)/missingvcf -S MISSING |\
	${TABIX.bgzip} -c &gt; $@
	${TABIX.tabix} -f -p vcf $@ 
	##VEP done <xsl:call-template name="GATK_VARIANT_FILTRATION">
		<xsl:with-param name="vcffile">$@</xsl:with-param>
		<xsl:with-param name="variantfiltration"><xsl:value-of select="$variantfiltration"/></xsl:with-param>
	</xsl:call-template>
	@$(call timeenddb,$@,<xsl:value-of select="$type"/>)
	@$(call sizedb,$@)
	$(call notempty,$@)

</xsl:template>


<xsl:template name="ANNOTATE_WITH_VEP">
<xsl:param name="target"/>
<xsl:param name="dependencies"/>
<xsl:param name="type"/>
<xsl:param name="variantfiltration"/>

<xsl:value-of select="$target"/> : <xsl:value-of select="$dependencies"/>
	#Annotation with VEP
	#VEP only work as root
	@$(call timebegindb,$@,<xsl:value-of select="$type"/>)
	$(VEP.bin) $(VEP.args) $(VEP.cache) --fasta $(REF) --offline --hgnc --format vcf --force_overwrite --sift=b --polyphen=b  -i $&lt; -o - --quiet --vcf <xsl:if test="/project/properties/property[@key='discard.intergenic.variants']/text()='yes'"> --no_intergenic </xsl:if> <xsl:value-of select="/project/properties/property[@key='downstream.vcf.annotation']/text()"/> | LC_ALL=C sort -t '	' -k1,1 -k2,2n -k4,4 -k5,5  |\
	$(VARKIT)/missingvcf -S MISSING |\
	${TABIX.bgzip} -c &gt; $@
	${TABIX.tabix} -f -p vcf $@ 
	##VEP done <xsl:call-template name="GATK_VARIANT_FILTRATION">
		<xsl:with-param name="vcffile">$@</xsl:with-param>
		<xsl:with-param name="variantfiltration"><xsl:value-of select="$variantfiltration"/></xsl:with-param>
	</xsl:call-template>
	@$(call timeenddb,$@,<xsl:value-of select="$type"/>)
	@$(call sizedb,$@)
	$(call notempty,$@)
	
</xsl:template>

<xsl:template name="GATK_VARIANT_FILTRATION">
<xsl:param name="vcffile"/>
<xsl:param name="variantfiltration"/>
<xsl:if test="string-length(normalize-space($variantfiltration))&gt;0">
<xsl:variable name="tmp">$(addsuffix .tmp.vcf,<xsl:value-of select="$vcffile"/>)</xsl:variable>
<xsl:variable name="tmpgz">$(addsuffix .gz,<xsl:value-of select="$tmp"/>)</xsl:variable>
	#filtering with GATK variant filtration
	$(JAVA) $(GATK.jvm) -jar $(GATK.jar) $(GATK.flags) \
		-T VariantFiltration \
		-R $(REF) \
		-o <xsl:value-of select="$tmp"/> \
		-U LENIENT_VCF_PROCESSING \
		--variant:vcfinput,VCF <xsl:value-of select="$vcffile"/> \
		<xsl:value-of select="normalize-space($variantfiltration)"/>
	#compress filtered VCF
	${TABIX.bgzip} -f  <xsl:value-of select="$tmp"/>
	#replace with target
	mv <xsl:value-of select="$tmpgz"/> <xsl:text> </xsl:text>  <xsl:value-of select="$vcffile"/>
	#index VCF with tabix
	${TABIX.tabix} -f -p vcf <xsl:value-of select="$vcffile"/>
</xsl:if>
</xsl:template>


<xsl:template name="DISTRIBUTION_OF_COVERAGE">
<xsl:param name="target"/>
<xsl:param name="dependencies"/>
<xsl:param name="type"/>
##
# distribution of coverage for sample &quot;<xsl:value-of select="@name"/>&quot; ( <xsl:value-of select="$type"/> )
#
<xsl:value-of select="$target"/>:  $(call indexed_bam, <xsl:value-of select="$dependencies"/> ) $(capture.bed)
	$(call timebegindb,$@,<xsl:value-of select="$type"/>)
	${VARKIT}/depthofcoverage -m $(MIN_MAPPING_QUALITY) -B $(capture.bed) $(filter %.bam,$^) |\
		grep -v bam | cut -d '	' -f 4 &gt; $(patsubst %.pdf,%.tsv,$@)
	echo 'pdf("$@",paper="A4r");  hist(as.integer(as.matrix(read.table("$(patsubst %.pdf,%.tsv,$@)"))), main="coverage for $(filter %.bam,$^) q=$(MIN_MAPPING_QUALITY)",breaks = 100, xlim = c(1,150)); dev.off()' |\
		${R.exe} --no-save 
	$(call timeenddb,$@,<xsl:value-of select="$type"/>)
	$(call sizedb,$@)

</xsl:template>

<xsl:template name="VARKIT_BEDDEDPTH">
<xsl:param name="target"/>
<xsl:param name="dependencies"/>
#
# coverage using varkit/beddepth
#
<xsl:value-of select="$target"/> : $(capture.bed)  $(call indexed_bam,<xsl:value-of select="$dependencies"/> )
	@$(call timebegindb,$@,$@)
	${VARKIT}/beddepth  -D 0 -D 5 -D 10 -D 20 -D 30 -D 40 -D 50  -m $(MIN_MAPPING_QUALITY) $(foreach S,$(filter %.bam,$^),-f $(S) ) &lt; $&lt; |\
		sed 's/_recal.bam//' |\
		gzip --best &gt; $@
	@$(call timeendb,$@,$@)
	@$(call sizedb,$@)
	$(call notempty,$@)

</xsl:template>

</xsl:stylesheet>
