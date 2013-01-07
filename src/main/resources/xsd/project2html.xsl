<?xml version='1.0'  encoding="UTF-8" ?>
<!--

Auhor: Pierre Lindenbaum

-->
<xsl:stylesheet
	xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
        xmlns:xsd='http://www.w3.org/2001/XMLSchema'
	version='1.0'
	>
 <xsl:output method="html"/>

<xsl:template match="/">
<html>
<xsl:apply-templates select="xsd:schema"/>
</html>
</xsl:template>

<xsl:template match="xsd:schema">
 <head>
  <title>Project2Make: Schema</title>
 </head>
 <body>
 <h1>Project2Make: Schema</h1>
 <h2>Types</h2>
 <xsl:apply-templates select="xsd:complexType"/>
 </body>
</xsl:template>




<xsl:template match="xsd:complexType">
<a><xsl:attribute name="name"><xsl:value-of select="generate-id(.)"/></xsl:attribute></a>
<h3><xsl:value-of select="@name"/></h3>
<xsl:apply-templates select="xsd:sequence"/>
<xsl:apply-templates select="xsd:simpleContent"/>
<xsl:if test="xsd:attribute">
<h4>Attributes</h4>
<ul>
<xsl:apply-templates select="xsd:attribute"/>
</ul>
</xsl:if>
</xsl:template>


<xsl:template match="xsd:simpleContent">
Is a simple content.<xsl:apply-templates select="xsd:extension"/>
</xsl:template>

<xsl:template match="xsd:extension">
It extends <b><xsl:value-of select="@base"/></b>.
<xsl:if test="xsd:attribute">
<h4>Attributes</h4>
<ul>
<xsl:apply-templates select="xsd:attribute"/>
</ul>
</xsl:if>

</xsl:template>


<xsl:template match="xsd:attribute">
<li><b><xsl:value-of select="concat('@',@name)"/></b>
<xsl:if test="@type">
 type:<xsl:value-of select="@type"/>
</xsl:if>
<xsl:if test="@use">
 use: <xsl:value-of select="@use"/>
</xsl:if>
<xsl:apply-templates select="xsd:simpleType"/>
</li>
</xsl:template>



<xsl:template match="xsd:simpleType">
<xsl:apply-templates select="xsd:restriction[xsd:enumeration]"/>
</xsl:template>

<xsl:template match="xsd:restriction[xsd:enumeration]">
Enumeration:<ul>
<xsl:apply-templates select="xsd:enumeration"/>
</ul>
</xsl:template>

<xsl:template match="xsd:enumeration">
<li><b><xsl:value-of select="@value"/></b><xsl:apply-templates select="xsd:annotation"/></li>
</xsl:template>


<xsl:template match="xsd:annotation">
<xsl:apply-templates select="xsd:documentation"/>
</xsl:template>

<xsl:template match="xsd:documentation">
 <xsl:text> :</xsl:text><i>&quot;<xsl:value-of select="."/>&quot;</i>
</xsl:template>



<xsl:template match="xsd:sequence">
<p>is a sequence of:</p><ul>
<xsl:apply-templates select="xsd:element" mode="seq"/>
</ul>
</xsl:template>

<xsl:template match="xsd:element" mode="seq">
<li>
Element <b>&lt;<xsl:apply-templates select="@name"/>/&gt;</b> type:<a><xsl:attribute name="href"><xsl:value-of select="concat('#',generate-id(../../..))"/></xsl:attribute><xsl:value-of select="@type"/></a>.
</li>
</xsl:template>



</xsl:stylesheet>
