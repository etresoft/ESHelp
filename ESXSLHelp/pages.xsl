<?xml version="1.0"?>

<xsl:stylesheet
  version = '1.0'
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>

  <!-- Output indented HTML 4.01 code in UTF-8. -->
  <xsl:output
    method="html"
    indent="yes"
    version="4.01"
    encoding="UTF-8"
    doctype-system="http://www.w3.org/TR/html4/loose.dtd"
    doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"/>

  <xsl:include href="eshelp.xsl"/>

  <!-- This is the default (non-index) page. -->
  
  <!-- Include a header into the output. -->
  <xsl:template match="header">

    <div class="header">

      <!-- Copy an external source. -->
      <xsl:if test="@src">
        <xsl:copy-of select="document(@src)/header/*[@mode='pages']"/>
      </xsl:if>

      <!-- Copy inline HTML. -->
      <xsl:copy-of select="./*"/>

      <!-- Copy the page title. -->
      <h1><xsl:value-of select="../title"/></h1>

    </div>

  </xsl:template>

</xsl:stylesheet>
