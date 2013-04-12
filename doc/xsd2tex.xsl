<?xml version='1.0'  encoding="UTF-8" ?>
<!--

Auhor: Pierre Lindenbaum

-->
<xsl:stylesheet
	xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
        xmlns:xsd='http://www.w3.org/2001/XMLSchema'
	version='1.0'
	>
 <xsl:output method="text"/>

<xsl:template match="/">

<xsl:apply-templates select="xsd:schema"/>

</xsl:template>

<xsl:template match="xsd:schema">
\section{The Project XML Schema}
 <xsl:apply-templates select="xsd:complexType"/>
</xsl:template>




<xsl:template match="xsd:complexType">

\subsection{<xsl:value-of select="@name"/>}
<xsl:apply-templates select="xsd:sequence"/>
<xsl:apply-templates select="xsd:simpleContent"/>
<xsl:if test=".//xsd:attribute">
\subsubsection{Attributes}
\begin{itemize}
<xsl:apply-templates select=".//xsd:attribute"/>
\end{itemize}
</xsl:if>
</xsl:template>


<xsl:template match="xsd:simpleContent">
Is a simple content. <xsl:apply-templates select="xsd:extension"/>.\\
</xsl:template>

<xsl:template match="xsd:extension">
It extends <xsl:value-of select="@base"/>.\\

</xsl:template>


<xsl:template match="xsd:attribute">

\item[<xsl:value-of select="concat('@',@name)"/>]

<xsl:if test="@type">
 type:<xsl:value-of select="@type"/>
</xsl:if>
<xsl:if test="@use">
 use: <xsl:value-of select="@use"/>
</xsl:if>
<xsl:apply-templates select="xsd:simpleType"/>
</xsl:template>



<xsl:template match="xsd:simpleType">
<xsl:apply-templates select="xsd:restriction[xsd:enumeration]"/>
</xsl:template>

<xsl:template match="xsd:restriction[xsd:enumeration]">
Enumeration:
\begin{enumerate}
<xsl:apply-templates select="xsd:enumeration"/>
\end{enumerate}
</xsl:template>

<xsl:template match="xsd:enumeration">
\item[<xsl:value-of select="@value"/>]
\begin{verbatim}
<xsl:apply-templates select="xsd:annotation"/>
\end{verbatim}
</xsl:template>


<xsl:template match="xsd:annotation">
<xsl:apply-templates select="xsd:documentation"/>
</xsl:template>

<xsl:template match="xsd:documentation">
<xsl:value-of select="."/>
</xsl:template>



<xsl:template match="xsd:sequence">
is a sequence of:
\begin{itemize}
<xsl:apply-templates select="xsd:element" mode="seq"/>
\end{itemize}
</xsl:template>

<xsl:template match="xsd:element" mode="seq">
\item[<xsl:apply-templates select="@name"/>] type:<xsl:value-of select="@type"/>
</xsl:template>



</xsl:stylesheet>
