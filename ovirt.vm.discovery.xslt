<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema-instance"
                version="1.0" exclude-result-prefixes="xs xsl">
    <xsl:output version="1.0" encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="yes"/>
    <xsl:template match="/">
        <xsl:text>{"data":[</xsl:text>
        <xsl:for-each select="vms/vm">

            <!--


{#VM.ID}	Unique virtual machine identifier.
{#VM.FQDN}	Fully Qualified Domain Name
{#VM.NAME}	Virtual machine name.
{#HV.ID}	Hypervisor identifier.
{#CLUSTER.ID}	Cluster identifner

            -->
            <xsl:text>{</xsl:text>

            <xsl:text>"{#VM.ID}":"</xsl:text>
            <xsl:value-of select="@id"/>
            <xsl:text>",</xsl:text>

            <xsl:text>"{#VM.FQDN}":"</xsl:text>
            <xsl:value-of select="fqdn"/>
            <xsl:text>",</xsl:text>

            <xsl:text>"{#VM.NAME}":"</xsl:text>
            <xsl:value-of select="name"/>
            <xsl:text>",</xsl:text>

            <xsl:text>"{#HV.ID}":"</xsl:text>
            <xsl:value-of select="host/@id"/>
            <xsl:text>",</xsl:text>

            <xsl:text>"{#CLUSTER.ID}":"</xsl:text>
            <xsl:value-of select="cluster/@id"/>
            <xsl:text>"</xsl:text>

            <xsl:text>}</xsl:text>
            <xsl:choose>
                <xsl:when test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
        <xsl:text>]}</xsl:text>
    </xsl:template>
</xsl:stylesheet>

