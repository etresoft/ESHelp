<?xml version="1.0"?>

<xsl:stylesheet
  version = '1.0'
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>

  <xsl:param name="mode"/>
  
  <!-- Convert a page node into an HTML document. -->
  <xsl:template match='/page'>
  
    <html>
  
      <head>

        <!-- Copy the title node -->
        <xsl:apply-templates select="title"/>

        <!-- Add all meta nodes. -->
        <xsl:apply-templates select="meta"/>
  
        <!-- Add CSS styles and imports. -->
        <xsl:apply-templates select="css"/>
      </head>
  
      <body>
 
        <!-- Add header text. -->
        <xsl:apply-templates select="header"/>

        <!-- Add a menu. -->
        <xsl:apply-templates select="menu"/>

        <!-- Add content. -->
        <xsl:apply-templates select="content"/>
  
        <!-- Add any footer information such as copyright, etc. -->
        <xsl:apply-templates select="footer"/>
 
      </body>
      
    </html>
    
  </xsl:template>

  <!-- Copy the a meta node directly into the output. -->
  <xsl:template match="meta">

    <xsl:copy-of select="."/>

  </xsl:template>

  <!-- Convert css nodes into css import rules. -->
  <xsl:template match="css">

    <xsl:for-each select="import">
      <link media="only screen" type="text/css" rel="stylesheet">
        <xsl:attribute name="href">
          <xsl:value-of select="concat('../sty/',.)"/>
        </xsl:attribute>
      </link>
    </xsl:for-each>

  </xsl:template>

  <!-- Include a header into the output. -->
  <xsl:template match="header">

    <div class="header">

      <!-- Copy an external source. -->
      <xsl:copy-of select="document(@src)/header/*"/>

      <!-- Copy inline HTML. -->
      <xsl:copy-of select="./*"/>

      <!-- Copy the page title. -->
      <h1><xsl:value-of select="../title"/></h1>
    
    </div>

  </xsl:template>

  <!-- Copy the contents of a content node directly into the output. -->
  <xsl:template match="content">

    <div class="content scrollfix">
      <!-- Copy inline HTML. -->
      <xsl:apply-templates select="./*"/>
    </div>
    
  </xsl:template>

  <!-- Include a footer into the output. -->
  <xsl:template match="footer">

    <!-- Copy an external source. -->
    <xsl:copy-of select="document(@src)/footer/*"/>

    <!-- Copy inline HTML. -->
    <xsl:copy-of select="./*"/>

  </xsl:template>

  <xsl:template match="@*[@mode] | node()[@mode]">
    <xsl:if test="@mode = $mode">
      <xsl:copy>
        <xsl:apply-templates select="@* | node()"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@mode">
  </xsl:template>

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
