<?xml version="1.0"?>

<xsl:stylesheet
  version = '1.0'
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>

  <!-- Output indented XHTML 1.0 code in UTF-8. -->
  <xsl:output 
    method="xml" 
    indent="yes" 
    version="1.0" 
    encoding="utf-8"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"/>

  <xsl:include href="eshelp.xsl"/>

  <!-- Convert css nodes into css import rules. -->
  <xsl:template match="css">
  
    <style type="text/css">
      <xsl:for-each select="import">
        @import url(sty/<xsl:value-of select="."/>);
      </xsl:for-each>
    </style>
  
  </xsl:template>

  <!-- Include a header into the output. -->
  <xsl:template match="header">

    <div class="header">

      <a href="https://www.mycompany.com">
        <img src="../shrd/mycompany.png" alt="mycompany" class="companylogo"/>
      </a>
      <img src="../shrd/myapp.png" alt="Icon" class="applogo"/>

      <!-- Copy inline HTML. -->
      <xsl:copy-of select="./*"/>
      
      <!-- Copy the page title. -->
      <h1><xsl:value-of select="../title"/></h1>
    
    </div>

  </xsl:template>

  <!-- Convert css nodes into css import rules. -->
  <xsl:template match="css">

    <xsl:for-each select="import">
      <link media="only screen" type="text/css" rel="stylesheet">
        <xsl:attribute name="href">
          <xsl:value-of select="concat('sty/',.)"/>
        </xsl:attribute>
      </link>
    </xsl:for-each>

  </xsl:template>

  <!-- Copy the contents of a content node directly into the output. -->
  <xsl:template match="menu">

    <!-- Extract menu data from an external XML document. -->
    <xsl:variable name="menu" select="document(../menu/@src)/menu"/>
    <xsl:variable name="menuitems" select="$menu/item"/>

    <table class="menu">
      <tr>
        <td>
          <table class="tablelist">
            <xsl:for-each select="$menuitems">
              <tr class="horizontalborder">
                <td>
                  <a>
                    <xsl:attribute name="href">
                      <xsl:value-of select="concat('pgs/', @id, '.html')"/>
                    </xsl:attribute>
                    <xsl:value-of select="name"/>
                  </a>
                </td>
              </tr>
            </xsl:for-each>
          </table>
        </td>
      </tr>
    </table>

  </xsl:template>

</xsl:stylesheet>
