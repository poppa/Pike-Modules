<?xml version='1.0'?>

<!-- this template transforms the autodoc XML files to HTML -->
<!-- the results may be a lot short of pretty - but this is -->
<!-- supposed to be fixed before we release anything public -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output encoding="iso-8859-1"
              method="xml"
              media-type="text/html"
              doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
              doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
              omit-xml-declaration="no"
              indent="yes" />


  <!-- Only draw public methods and members -->
  <xsl:param name="only-public" select="true()" />
  <xsl:param name="lcase" select="'abcdefghijklmnopqrstuvwxyz'" />
  <xsl:param name="ucase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
  <xsl:param name="page-title" select="'Pike doc'" />

  <xsl:template match="text()"></xsl:template>


  <xsl:template match="/"><!-- {{{ -->
    <html xml:lang="en" xmlns="http://www.w3.org/1999/xhtml" lang="en">
      <head>
	<title><xsl:value-of select="$page-title"/></title>
	<!-- <link rel="stylesheet" type="text/css" href="doc.css" /> -->
	<style type="text/css">
	  BODY { 
		  font: 80%/140% arial, sans-serif; 
		  padding: 0; 
		  margin: 0; 
		  background: #212121;
		  color: #F5F5F5;
		  }
	  H1, H2 {
		  padding: 20px 10px; 
		  background: #141212; 
		  font-size: 2.5em;
		  border-bottom: 5px solid #35353C;
		  margin: 0;
		  color: #F1F1F1;
		  clear: left;
		  }
	  H2 { font-size: 2em; }
	  H1 SMALL,
	  H2 SMALL { 
		  font-weight: normal; 
		  font-variant: small-caps; 
		  font-family: georgia, serif;
		  font-style: italic;
		  }
	  A { color: orange; }
	  HR { 
		  height: 1px; 
		  background: #333; 
		  border: none;
		  margin: 0 0 20px 0;
		  }
	  PRE { font-size: 11px; }
	  DIV.docwrap { 
		  border-top: 1px solid black;
		  background: #232323;
		  }
	  DIV.docgroup {
		  border-bottom: 1px solid black;
		  background: #2A2A29;
		  clear: left;
		  }
	  DIV.docgroup DL {
		  clear: both;	
		  }
	  DIV.docgroup DT {
		  float: left;
		  width: 18%;
		  background: #1a1a1a;
		  padding: 5px;
		  clear: left;
		  }
	  DIV.docgroup DD {
		  float: left;
		  width: 76%;
		  color: #BBB;
		  }
	  DIV.docgroup DD P { margin-top: 5px; }
	  DIV.docdoc { 
		  background: #222522; 
		  padding: 7px; 
		  padding-bottom: 0;
		  outline: 1px solid #1e1e1e;
		  }
	  DIV.content { padding: 14px; padding-left: 40px; }
	  DL.method-summary { margin: 0 }
	  DL.method-summary UL { padding-left: 0; list-style: none; margin: 10px 0 0 0; }
	  DL.method-summary UL LI { background:#181818; margin-bottom: 1px; padding: 3px}
	  DL.method-summary UL LI A { color: #66ccff; font-weight: bold; }
	  DL.method-summary UL LI .params SPAN,
	  DL.method-summary UL LI .params { color: #555 !important; }
	  DL.method-summary UL LI UL { margin: 0 0 0 25px;}
	  .label { font-weight: bold; margin-right: 10px; color: #777; }
	  .homogen-name { font-size: 1.6em; font-weight: bold; }
	  .top-level { color: #6cf; }
	  .modifier { color: #cf5e5e;  }
	  .homogen-type { color: #909; }
	  .type-type { color: #b9b91d; }
	  .type-name, .var-name { color: #A0F0E0; }
	  .delim { color: #CCC; }
	  .literal { color: #C00; }
	  .method { color: #66ccff; }
	  .ref { 
		  font-family: 'andale mono', monospace;
		  background: #212129;
		  padding: 2px;
		  font-size: .9em;
		  color: #f66;
		  }
	  .program-name { color: #1379a9; }
	  DT .param-name { color: #f66; font-size: 1.0em !important; }
	  P.expanded-member { 
		  font-size: 1.3em; margin-top: 0;
		  background: #212129;
		  padding: 0px 5px 3px 5px;
		  display: table;
		  margin-top: 2px;
		  }
	  P TT {
		  background: #212129;
		  font-size: 1.3em;
		  padding: 2px;
		  color: #f0f56b;
		  }
	  DIV.code, CODE { color: white; font: 11.5px/120% 'andale mono', monospace !IMPORTANT }
	  DIV.code {
		  padding: 1px;
		  border: 1px solid #000;
		  background: #333;
		  }
	  DIV.code OL {
		  list-style: none;
		  padding: 10px;
		  margin: 0;
		  background: #212129;
		  }
	</style>
      </head>
      <body>
	<xsl:apply-templates/>
      </body>
    </html>
  </xsl:template><!-- }}} -->


  <xsl:template match="*"><!-- {{{ -->
    <xsl:apply-templates/>
  </xsl:template><!-- }}} -->


  <!-- Module summary -->
  <xsl:template match="module" mode="summary">
    <li>module <a href="#{generate-id()}"><xsl:value-of select="@name"/></a>
      <xsl:if test="module">
	<ul>
	  <xsl:apply-templates select="module" mode="summary"/>
	</ul>
      </xsl:if>
    </li>
  </xsl:template>


  <!-- Class summary -->
  <xsl:template match="class" mode="summary"><!-- {{{ -->
    <xsl:if test="not(modifiers) or modifiers/public or not($only-public)">
      <li>class <a href="#{generate-id()}"><xsl:value-of select="@name" /></a>
	<xsl:if test="class and (not(class/modifiers) or class/modifiers/public or not($only-public))">
	  <ul>
	    <xsl:apply-templates select="class" mode="summary" />
	  </ul>
	</xsl:if>
      </li>
    </xsl:if>
  </xsl:template><!-- }}} -->


  <!-- Method summary -->
  <xsl:template match="docgroup[@homogen-type='method']/method[not(modifiers)]" mode="summary"><!-- {{{ -->
    <li>
      <xsl:apply-templates select="modifiers" mode="type" />
      <xsl:apply-templates select="returntype/*" mode="type"/>
      <xsl:value-of select="' '"/>
      <a href="#{generate-id(parent::node())}"><xsl:value-of select="@name" /></a>
      <span class="params"><strong>
	<span class="delim">(</span>
	<xsl:for-each select="arguments/argument">
	   <xsl:apply-templates select="."/>
	   <xsl:if test="position() != last()">, </xsl:if>
	</xsl:for-each>
	<span class="delim">)</span>
      </strong></span>
    </li>
  </xsl:template><!-- }}} -->


  <xsl:template match="module[@name != '']"><!-- {{{ -->
    <div class="module" id="{generate-id()}">
      <h1>
	<small>Module</small>
	<xsl:text> </xsl:text>
	<span class="top-level"><xsl:value-of select="@name"/></span>
      </h1>
      <xsl:if test="doc">
	<div class="description content">
	  <xsl:apply-templates select="./doc"/>
	</div>
      </xsl:if>
      <xsl:if test="module">
	<div class="description content">
	  <dl class="method-summary">
	    <dt class="label">Module summary</dt>
	    <dd>
	      <ul><xsl:apply-templates select="module" mode="summary" /></ul>
	    </dd>
	  </dl>
	</div>
      </xsl:if>
      <xsl:if test="class">
	<div class="description content">
	  <dl class="method-summary">
	    <dt class="label">Class summary</dt>
	    <dd>
	      <ul><xsl:apply-templates select="class" mode="summary" /></ul>
	    </dd>
	  </dl>
	</div>
      </xsl:if>
      <xsl:if test="docgroup[@homogen-type='method']">
	<div class="description content">
	  <dl class="method-summary">
	    <dt class="label">Method summary</dt>
	    <dd>
	      <ul><xsl:apply-templates select="docgroup[@homogen-type='method']/method" mode="summary" /></ul>
	    </dd>
	  </dl>
	</div>
      </xsl:if>
      <xsl:if test="docgroup">
	<div class="docwrap">
	  <xsl:for-each select="docgroup">
	    <xsl:apply-templates select="."/>
	  </xsl:for-each>
	</div>
      </xsl:if>

    </div>
    <xsl:for-each select="class">
      <xsl:apply-templates select="."/>
    </xsl:for-each>
    <xsl:for-each select="module">
      <xsl:apply-templates select="."/>
    </xsl:for-each>
  </xsl:template><!-- }}} -->


  <xsl:template match="class"><!-- {{{ -->
    <xsl:if test="not(modifiers) or modifiers/public or not($only-public)">
      <div class="class" id="{generate-id()}">
	<h2>
	  <xsl:apply-templates select="modifiers" />
	  <small>Class</small>
	  <xsl:text> </xsl:text>
	  <span class="top-level">
	    <xsl:for-each select="ancestor::*[@name != '']"
	    ><xsl:value-of select="@name"/>.</xsl:for-each
	    ><xsl:value-of select="@name"/>
	  </span>
	</h2>
	<div class="description content">
	  <xsl:apply-templates select="doc"/>
	  <dl class="method-summary">
	    <dt class="label">Method summary</dt>
	    <dd>
	      <ul><xsl:apply-templates select="docgroup[@homogen-type='method']/method" mode="summary" /></ul>
	    </dd>
	  </dl>
	</div>
	<xsl:apply-templates select="docgroup"/>
	<xsl:apply-templates select="class"/>
      </div>
    </xsl:if>
  </xsl:template><!-- }}} -->


  <xsl:template match="inherit">
    <li><xsl:value-of select="classname"/></li>
  </xsl:template>

  <!-- DOCGROUPS -->

  <xsl:template name="show-class-path">
    <xsl:if test="count(ancestor::*[@name != '']) > 0">
      <span class="program-name">
        <xsl:for-each select="ancestor::*[@name != '']">
          <xsl:value-of select="@name"/>
          <xsl:if test="position() != last()">.</xsl:if>
        </xsl:for-each>
      </span>
    </xsl:if>
  </xsl:template>


  <xsl:template name="show-class-path-arrow">
    <xsl:if test="count(ancestor::*[@name != '']) > 0">
      <xsl:call-template name="show-class-path"/>
      <xsl:choose>
	<xsl:when test="name() = 'constant'">.</xsl:when> 
        <xsl:when test="ancestor::class">
          <xsl:text>()-&gt;</xsl:text>
        </xsl:when>
        <xsl:when test="ancestor::module">
          <xsl:text>.</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>


  <xsl:template match="docgroup">
    <xsl:if test="not($only-public)
                  or */modifiers/public
		  or not(*/modifiers)">
      <div class="docgroup content">
	<div class="member">
	  <xsl:choose>
	    <xsl:when test="@homogen-type">
	      <span class="label homogen-type">
		<xsl:call-template name="ucfirst">
		  <xsl:with-param name="text" select="@homogen-type" />
		</xsl:call-template>
	      </span>
	      <xsl:choose>
		<xsl:when test="@homogen-name">
		  <!-- FIXME: Should have the module path here. -->
		  <span class="homogen-name" id="{generate-id()}">
		    <xsl:if test="@homogen-type != 'inherit'">
		      <xsl:call-template name="find-class-path">
			<xsl:with-param name="node" select="parent::node()" />
			<xsl:with-param name="text" select="''" />
		      </xsl:call-template>
		    </xsl:if>
		    <xsl:value-of select="concat(@belongs, @homogen-name)"/>
		  </span>
		</xsl:when>
		<xsl:when test="count(./*[name() != 'doc']) > 1">s
		</xsl:when>
		<xsl:when test="@homogen-type = 'import'">
		  <span class="homogen-name" id="{generate-id()}">
		    <xsl:value-of select="import/classname" />
		  </span>
		</xsl:when>
	      </xsl:choose>
	    </xsl:when>
	    <xsl:otherwise>syntax</xsl:otherwise>
	  </xsl:choose>
	</div>
	<xsl:if test="@homogen-type != 'inherit' and doc/text">
	  <p class="expanded-member"><xsl:apply-templates select="*[name() != 'doc']"/></p>
	  <div class="docdoc">
	    <xsl:apply-templates select="doc"/>
	    <br style="clear: both" />
	  </div>
	</xsl:if>
	<xsl:if test="@homogen-type = 'inherit' and doc/text">
	  <div class="docdoc">
	    <xsl:apply-templates select="doc"/>
	    <br style="clear: both" />
	  </div>
	</xsl:if>
      </div>
    </xsl:if>
  </xsl:template>


  <xsl:template match="constant">
    <xsl:if test="position() != 1"><br/></xsl:if>
    <code>
      <span class="type-type">constant</span><xsl:text> </xsl:text>
      <xsl:call-template name="show-class-path-arrow"/>
      <span class="type-name">
        <xsl:value-of select="@name"/>
      </span>
      <xsl:if test="typevalue">
        =
        <xsl:apply-templates select="typevalue/*" mode="type"/>
      </xsl:if>
    </code>
  </xsl:template>


  <xsl:template match="variable">
    <xsl:if test="position() != 1"><br/></xsl:if>
    <code>
      <xsl:apply-templates select="modifiers" mode="type" />
      <xsl:apply-templates select="type/*" mode="type"/>
      <xsl:value-of select="' '"/>
      <span class="delim"><xsl:call-template name="show-class-path-arrow"/></span>
      <span class="var-name"><xsl:value-of select="@name"/></span>
    </code>
  </xsl:template>


  <xsl:template match="method">
    <xsl:if test="position() != 1"><br/></xsl:if>
    <code>
      <xsl:apply-templates select="modifiers" mode="type" />
      <xsl:apply-templates select="returntype/*" mode="type"/>
      <xsl:value-of select="' '"/>
      <span class="delim"><xsl:call-template name="show-class-path-arrow"/></span>
      <span class="method"><xsl:value-of select="@name"/></span>
      <span class="delim">(</span>
      <xsl:for-each select="arguments/argument">
	 <xsl:apply-templates select="."/>
	 <xsl:if test="position() != last()">
	   <span class="delim">, </span>
	 </xsl:if>
      </xsl:for-each>
      <span class="delim">)</span>
    </code>
  </xsl:template>


  <xsl:template match="argument">
    <xsl:choose>
      <xsl:when test="value">
        <span class="literal"><xsl:value-of select="value"/></span>
      </xsl:when>
      <xsl:when test="type and @name">
        <xsl:apply-templates select="type/*" mode="type"/>
        <xsl:value-of select="' '"/>
        <span class="param-name"><xsl:value-of select="@name"/></span>
      </xsl:when>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="modifiers">
    <xsl:for-each select="./*">
      <small class="modifier">
	<xsl:call-template name="ucfirst">
	  <xsl:with-param name="text" select="name()" />
	</xsl:call-template>
      </small>
      <xsl:text> </xsl:text>
    </xsl:for-each>
  </xsl:template>


  <!-- TYPES -->


  <xsl:template match="modifiers" mode="type">
    <xsl:for-each select="./*">
      <xsl:value-of select="name()" />
      <xsl:text> </xsl:text>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="object" mode="type">
    <xsl:choose>
      <xsl:when test="text()">
        <span class="type-type">object</span>
	<span class="delim">(</span>
	<em><xsl:value-of select="."/></em>
	<span class="delim">)</span>
      </xsl:when>
      <xsl:otherwise>
        <span class="type-type">object</span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="multiset" mode="type">
    <span class="type-type">multiset</span>
    <xsl:if test="indextype"
    ><span class="delim">(</span><xsl:apply-templates select="indextype/*" mode="type"
    /><span class="delim">)</span></xsl:if>
  </xsl:template>


  <xsl:template match="array" mode="type">
    <span class="type-type">array</span>
    <xsl:if test="valuetype"
    ><span class="delim">(</span><xsl:apply-templates select="valuetype/*" mode="type"
    /><span class="delim">)</span></xsl:if>
  </xsl:template>


  <xsl:template match="mapping" mode="type">
    <span class="type-type">mapping</span>
    <xsl:if test="indextype and valuetype"
      ><span class="delim">(</span><xsl:apply-templates select="indextype/*" mode="type"/>
       <span class="delim">:</span> <xsl:apply-templates select="valuetype/*" mode="type"
    /><span class="delim">)</span></xsl:if>
  </xsl:template>


  <xsl:template match="function" mode="type">
    <span class="type-type">function</span>
    <xsl:if test="argtype or returntype"
     ><span class="delim">(</span><xsl:for-each select="argtype/*">
        <xsl:apply-templates select="." mode="type"/>
        <xsl:if test="position() != last()">, </xsl:if>
      </xsl:for-each>
      <span class="delim">:</span>
      <xsl:apply-templates select="returntype/*" mode="type"
    /><span class="delim">)</span></xsl:if>
  </xsl:template>


  <xsl:template match="varargs"  mode="type">
    <xsl:apply-templates select="*" mode="type"/>
    <span class="delim"> ... </span>
  </xsl:template>


  <xsl:template match="or" mode="type">
    <xsl:for-each select="./*">
      <xsl:apply-templates select="." mode="type"/>
      <xsl:if test="position() != last()">|</xsl:if>
    </xsl:for-each>
  </xsl:template>


  <xsl:template match="string|void|program|mixed|float" mode="type">
    <span class="type-type">
      <xsl:value-of select="name()"/>
    </span>
  </xsl:template>


  <xsl:template match="int" mode="type">
    <span class="type-type">int</span>
    <xsl:if test="min|max">
      <span class="delim">(</span>
	<span class="literal"><xsl:value-of select="min"/></span>
	<span class="delim">..</span>
	<span class="literal"><xsl:value-of select="max"/></span>
      <span class="delim">)</span>
    </xsl:if>
  </xsl:template>

  <xsl:template match="p" mode="type"></xsl:template>


  <!-- DOC -->


  <xsl:template match="doc">
    <xsl:if test="text">
      <dt><span class="label">Description</span></dt>
      <xsl:apply-templates select="text" mode="doc"/>
    </xsl:if>
    <xsl:apply-templates select="group" mode="doc"/>
  </xsl:template>


  <xsl:template match="group" mode="doc">
    <xsl:apply-templates select="*[name(.) != 'text']" mode="doc"/>
    <xsl:apply-templates select="text" mode="doc"/>
    <xsl:if test="not(text) or string-length(text/node()) = 0">
      <dd><p>&#160;</p></dd>
    </xsl:if>
  </xsl:template>


  <xsl:template match="param" mode="doc">
    <dt>
      <span class="label">Parameter</span>
      <xsl:text> </xsl:text>
      <code class="param-name"><xsl:value-of select="@name"/></code>
    </dt>
  </xsl:template>


  <xsl:template match="seealso" mode="doc">
    <dt><span class="label">See also</span></dt>
  </xsl:template>


  <xsl:template match="*" mode="doc">
    <xsl:if test="parent::*[name() = 'group']">
      <dt>
	<span class="label">
	  <xsl:call-template name="ucfirst">
	    <xsl:with-param name="text" select="name()" />
	  </xsl:call-template>
	</span>
      </dt>
      <xsl:apply-templates mode="doc"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="text" mode="doc">
    <dd><xsl:apply-templates mode="text"/></dd>
  </xsl:template>


  <!-- TEXT -->


  <xsl:template match="dl" mode="text">
    <dl>
      <xsl:for-each select="group">
        <xsl:apply-templates mode="text"/>
      </xsl:for-each>
    </dl>
  </xsl:template>


  <xsl:template match="item" mode="text">
    <dt><xsl:value-of select="@name"/></dt>
  </xsl:template>


  <xsl:template match="text" mode="text">
    <dd><xsl:apply-templates mode="text"/></dd>
  </xsl:template>


  <xsl:template match="ul|ol" mode="text">
    <xsl:copy>
      <xsl:value-of select="name" />
      <xsl:for-each select="group">
	<li><xsl:apply-templates select="text/node()" mode="text" /></li>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>


  <xsl:template match="mapping" mode="text">
    <dl>
      <xsl:for-each select="group">
        <xsl:for-each select="member">
          <dt>
            <code>
              <span class="literal"><xsl:value-of select="index"/></span>
              <span class="delim"> : </span>
	      <xsl:apply-templates select="type" mode="type"/>
            </code>
          </dt>
        </xsl:for-each>
        <dd><xsl:apply-templates select="text" mode="text"/></dd>
      </xsl:for-each>
    </dl>
  </xsl:template>


  <xsl:template match="array" mode="text">
    <dl>
      <xsl:for-each select="group">
        <xsl:for-each select="elem">
          <dt>
            <code>
              <xsl:apply-templates select="type" mode="type"/>
              <xsl:text> </xsl:text>
              <span class="literal"><xsl:value-of select="index"/></span>
            </code>
          </dt>
        </xsl:for-each>
        <dd>
          <xsl:apply-templates select="text" mode="text"/>
        </dd>
      </xsl:for-each>
    </dl>
  </xsl:template>


  <xsl:template match="int" mode="text">
    <dl>
      <xsl:for-each select="group">
        <xsl:for-each select="value">
          <dt>
            <code>
              <span class="literal"><xsl:value-of select="value"/></span>
            </code>
          </dt>
        </xsl:for-each>
        <dd>
          <xsl:apply-templates select="text" mode="text"/>
        </dd>
      </xsl:for-each>
    </dl>
  </xsl:template>


  <xsl:template match="mixed" mode="text">
    &lt;tt&gt;<xsl:value-of select="@name"/>&lt;/tt&gt; can have any of the following types:
    <dl>
      <xsl:for-each select="group">
        <dt><code><xsl:apply-templates select="type" mode="type"/></code></dt>
	<dd><xsl:apply-templates select="text" mode="text"/></dd>
      </xsl:for-each>
    </dl>
  </xsl:template>


  <xsl:template match="ref" mode="text">
    <span class="ref"><xsl:value-of select="."/></span>
  </xsl:template>

  <xsl:template match="expr" mode="text">
    <code><xsl:value-of select="." /></code>
  </xsl:template>

  <xsl:template match="i|p|b|tt" mode="text">
    <xsl:copy select=".">
      <xsl:apply-templates mode="text"/>
    </xsl:copy>
  </xsl:template>


  <xsl:template match="pre/pre" mode="text">
    <xsl:copy select=".">
      <xsl:apply-templates mode="text"/>
    </xsl:copy>
  </xsl:template>


  <xsl:template match="url" mode="text">
    <a href="{.}"><xsl:value-of select="."/></a>
  </xsl:template>


  <xsl:template match="code" mode="text">
    <code>
      <xsl:copy-of select="node()"/>
    </code>
  </xsl:template>


  <xsl:template match="code[@example]" mode="text">
    <div class="code">
      <xsl:copy-of select="node()"/>
    </div>
  </xsl:template>


  <xsl:template match="text()" mode="text">
    <xsl:copy-of select="."/>
  </xsl:template>


  <!-- Utils -->


  <xsl:template name="ucfirst">
    <xsl:param name="text" />
    <xsl:value-of select="concat(translate(substring($text, 1, 1), $lcase, $ucase),
                                 substring($text, 2))" />
  </xsl:template>


  <!-- Recursivley searches the three backwards to create a Module.Class path -->
  <xsl:template name="find-class-path"><!-- {{{ -->
    <xsl:param name="node" />
    <xsl:param name="text" />
    <xsl:choose>
      <xsl:when test="name($node/../*[1])">
	<xsl:choose>
	  <!--<xsl:when test="name($node) = 'class'"><xsl:value-of select="$node/@name" />.</xsl:when>-->
	  <xsl:when test="name($node) = 'class' or name($node) = 'module'">
	    <xsl:call-template name="find-class-path">
	      <xsl:with-param name="node" select="$node/../../*[1]" />
	      <xsl:with-param name="text" select="concat($node/@name, '.',  $text)" />
	    </xsl:call-template>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:call-template name="find-class-path">
	      <xsl:with-param name="node" select="$node/../../*[1]" />
	      <xsl:with-param name="text" select="$text" />
	    </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$text" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template><!-- }}} -->

</xsl:stylesheet>
