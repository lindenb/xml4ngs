<?xml version='1.0'  encoding="UTF-8" ?>
<!--

Auhor: Pierre Lindenbaum

-->
<xsl:stylesheet
	xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
	version='1.0'
	>


<xsl:template match="fastq" mode="dir">
	<xsl:apply-templates select="../../.." mode="dir"/>
</xsl:template>

<xsl:template match="fastq" mode="fastq">
	<xsl:value-of select="@path"/>
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


<xsl:template match="lanes" mode="dir">
<xsl:text>$(OUTDIR)/Lanes/</xsl:text>
</xsl:template>

<xsl:template match="lane" mode="dir">
<xsl:apply-templates select=".." mode="dir"/>
<xsl:value-of select="concat('L',.)"/>
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
	$(call timebegindb,$@)
	$(SAMTOOLS) index $&lt;
	$(call timeenddb,$@)
	$(call sizedb,$@)

</xsl:text>
</xsl:template>

<!-- provides a BED for the capture --> 
<xsl:template name="capture.bed">
 <xsl:choose>
  <xsl:when test="//capture/bed/@path"><xsl:value-of select="//capture/bed/@path"/></xsl:when>
  <xsl:otherwise>ensembl.exons.bed</xsl:otherwise>
 </xsl:choose>
</xsl:template>


</xsl:stylesheet>
