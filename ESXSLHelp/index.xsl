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

  <!-- In Apple's help example, the index file is one level higher than
       other pages. This requires hacking of any included files. -->
       
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

  <!-- Emit Javascript. -->
  <xsl:template match="js">

    <xsl:for-each select="script">
      <script type="text/javascript">
        <xsl:attribute name="src">
          <xsl:value-of select="concat('scrpt/',.)"/>
        </xsl:attribute>
      </script>
    </xsl:for-each>

  </xsl:template>

  <!-- Include a header into the output. -->
  <xsl:template match="header">

    <!-- Use the index parameter to pull the header content for the index
         page. -->
    <xsl:call-template name="header">
      <xsl:with-param name="type">index</xsl:with-param>
    </xsl:call-template>

  </xsl:template>

  <!-- Construct a menu page. -->
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
