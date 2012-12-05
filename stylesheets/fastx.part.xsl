<?xml version='1.0'  encoding="UTF-8" ?>
<!--

Auhor: Pierre Lindenbaum

-->
<xsl:stylesheet
	xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
	version='1.0'
	>

<xsl:template match="project" match="fastx">

#
# path to GHOSTVIEW
#
GHOSTVIEW ?= gs

#
# merge all the reports in one PDF
#
fastx.report.pdf: <xsl:for-each select="sample">
	<xsl:text> \
	</xsl:text>
	<xsl:apply-templates select="." mode="fastx.qual.and.nuc"/>
</xsl:for-each><xsl:for-each select="lane">
	<xsl:text> \
	</xsl:text>
	<xsl:apply-templates select="." mode="fastx.qual.and.nuc"/>
</xsl:for-each>
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
	$(FASTX.dir)/bin/fastx_quality_stats -Q33  &gt; <xsl:value-of select="$stat"/>
	$(FASTX.dir)/bin/ffastq_quality_boxplot_graph.sh -p  -i <xsl:value-of select="$stat"/> -t "QUAL <xsl:value-of select="@name"/>" -o <xsl:apply-templates select="." mode="fastx.qual"/>
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
