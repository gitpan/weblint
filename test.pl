: # use perl
        eval 'exec perl -S $0 "$@"'
                if $runnning_under_some_shell;

#
# test.pl - regression tests for weblint
#
# Copyright (C) 1995,1996,1997 Neil Bowers.  All rights reserved.
#
# See README for additional blurb.
# Bugs, comments, suggestions welcome: neilb@cre.canon.co.uk
#
$VERSION	= '1.012';
($PROGRAM = $0) =~ s@.*/@@;
$FILENAME	= 'testfile.htm';
$LOGFILE	= 'test.log';
$ENV{WEBLINTRC} = '/dev/null';
@TMPDIR_OPTIONS	= ('/usr/tmp', '/tmp', '/var/tmp', '/temp');
@COLOR_NAMES    = ('aqua', 'black', 'blue', 'fuchsia', 'gray', 'green',
                   'lime', 'maroon', 'navy',
                   'olive', 'purple', 'red', 'silver', 'teal',
                   'white', 'yellow');


&WeblintTestInitialize();
$state = 'start';
while (<DATA>)
{
    chop;

    #--------------------------------------------------------------------
    # A line of dashes (minus characters) signify end of test
    #--------------------------------------------------------------------
    if (/^\#----/)
    {
        push(@args, '') if @args == 0;
        foreach $arg (@args)
        {
            if (@warns > 0)
            {
                &ExpectWARN($subject, $arg, $body, @warns);
            }
            else
            {
                &ExpectOK($subject, $arg, $body);
            }
        }

        $subject = undef;
        $body    = '';
        @args    = ();
        @warns   = ();

        $state   = 'start';

        next;
    }

    #--------------------------------------------------------------------
    # A line starting with 3 (FOUR) hashes (#) delimits the HTML test
    #--------------------------------------------------------------------
    if (/^\#\#\#\#/)
    {
        $state = ($state eq 'start' || $state eq 'args') ? 'body' : 'end';

        next;
    }

    #--------------------------------------------------------------------
    # In START state, we are about to read the subject line of the test
    #--------------------------------------------------------------------
    if ($state eq 'start')
    {
        $subject = $_;
        $state   = 'args';
        next;
    }

    if ($state eq 'args')
    {
        $_ = '' if /^\s*<none>\s*$/io;
        push(@args, $_);
        next;
    }

    if ($state eq 'body')
    {
        $body .= "$_\n";
        next;
    }

    if ($state eq 'end')
    {
        next if /^\s*$/;
        ($line, $id) = split(/:/, $_, 2);
        push(@warns, $line, $id);
        next;
    }
}

foreach $color (@COLOR_NAMES)
{
    &ExpectOK("BODY with BGCOLOR attribute set to \"$color\"", '',
              "<HTML>\n<HEAD><TITLE>test</TITLE></HEAD>\n".
              "<BODY BGCOLOR=\"$color\">this is the body</BODY>\n</HTML>");
}

&WeblintTestEnd();


#========================================================================
# Function:	ExpectOK
# Purpose:	Run a test, for which we expect no warnings.
#========================================================================
sub ExpectOK
{
   local($description, $flags, $html) = @_;
   local(@results);


   &NextTest($description);
   &CreateFile($html) || die "Failed to create working file ($filename): $!\n";
   @results = &RunWeblint($flags);
   if (@results == 0)
   {
      &TestPasses();
   }
   else
   {
      &TestFails($html, @results);
   }
}


#========================================================================
# Function:	ExpectWARN
# Purpose:	A test which we expect weblint to complain about.
#		We pass in one or more expected errors.
#========================================================================
sub ExpectWARN
{
   local($description, $flags, $html, @expected) = @_;
   local(@results, @notSeen);
   local($i, $j);


   &NextTest($description);
   &CreateFile($html) || die "Failed to create working file ($filename): $!\n";
   @results = &RunWeblint($flags);

   if (@results == 0)
   {
      &TestFails($html);
      return;
   }

   OUTER: for ($i=0; $i < $#expected; $i += 2)
   {
      INNER: for ($j = 0; $j < $#results; $j += 2)
      {
	 if ($results[$j] == $expected[$i] &&
	     $results[$j+1] eq $expected[$i+1])
	 {
	    @lost = splice(@results, $j, 2);
	    next OUTER;
	 }
      }
      @notSeen = (@notSeen, $expected[$i], $expected[$i+1]);
   }

   if (@notSeen == 0 && @results == 0)
   {
      &TestPasses();
   }
   else
   {
      &TestFails($html, @results);
   }
}


#========================================================================
# Function:	RunWeblint
# Purpose:	This function runs weblint and parses the output.
#		The results from weblint are passed back in an array.
#========================================================================
sub RunWeblint
{
   local($flags) = @_;
   local(*OUTPUT);
   local(@results);


   open(OUTPUT, "./weblint -noglobals -t $flags $filename |") || do
   {
      die "Failed to create pipe from weblint: $!\n";
   };
   while (<OUTPUT>)
   {
      next if /^$/;
      chop;
      ($repfile, $line, $wid) = split(/:/);
      push(@results, $line, $wid);
   }
   close OUTPUT;
   $status = ($? >> 8);

   return @results;
}


#========================================================================
# Function:	CreateFile
# Purpose:	Create sample html file from text string.
#========================================================================
sub CreateFile
{
   local($html) = @_;
   local(*FILE);


   open(FILE, "> $filename") || return undef;
   print FILE $html."\n";
   close FILE;

   1;
}

#========================================================================
# Function:	WeblintTestInitialize()
# Purpose:	Initialize global variables and open log file.
#========================================================================
sub WeblintTestInitialize
{
   $TMPDIR   = &PickTmpdir(@TMPDIR_OPTIONS);
   $WORKDIR  = "$TMPDIR/webtest.$$";
   mkdir($WORKDIR, 0755) || do
   {
      die "Failed to create working directory $WORKDIR: $!\n";
   };

   $filename = $WORKDIR.'/'.$FILENAME;
   $testID   = 0;
   $failCount = 0;
   $passCount = 0;

   $WEBLINTVERSION = &DetermineWeblintVersion() || 'could not determine';

   open(LOGFILE, "> $LOGFILE") || die "Can't write logfile $LOGFILE: $!\n";

   print LOGFILE "Weblint Testsuite:\n";
   print LOGFILE "    Weblint Version:   $WEBLINTVERSION\n";
   print LOGFILE "    Testsuite Version: $VERSION\n";
   print LOGFILE '=' x 76, "\n";

   print STDERR "Running weblint testsuite:\n";
   print STDERR "    Weblint Version:   $WEBLINTVERSION\n";
   print STDERR "    Testsuite Version: $VERSION\n";
   print STDERR "    Results Logfile:   $LOGFILE\n";
   print STDERR "Running test cases (. for pass, ! for failure):\n";
}

#========================================================================
# Function:	DetermineWeblintVersion
# Purpose:	Work out which version of weblint we think we're testing.
#		Hi Adam!
#========================================================================
sub DetermineWeblintVersion
{
   local(*PIPE);
   local($VERSION);

   open(PIPE, "./weblint -v 2>&1 |") || return undef;

   while (<PIPE>)
   {
      return $1 if /^(weblint\s+v.*)$/;

      /^\s*This is weblint, version\s*([0-9.]+)/ && do
      {
	 return "weblint v$1";
      };
   }
}

#========================================================================
# Function:	WeblintTestEnd()
# Purpose:	Generate summary in logfile, close logfile, then
#		clean up working files and directory.
#========================================================================
sub WeblintTestEnd
{
   print LOGFILE '=' x 76, "\n";
   print LOGFILE "Number of Passes:   $passCount\n";
   print LOGFILE "Number of Failures: $failCount\n";
   close LOGFILE;

   print STDERR "\n", '-' x 76, "\n";
   if ($failCount > 0)
   {
      print STDERR "Failed tests:\n";
      foreach $failure (@failedTests)
      {
	 print STDERR "    $failure\n";
      }
      print STDERR '-' x 76, "\n";
      
   }
   print STDERR "Number of Passes:   $passCount\n";
   print STDERR "Number of Failures: $failCount\n";

   unlink $filename;
   rmdir $WORKDIR;
}

#========================================================================
# Function:	NextTest()
# Purpose:	Introduce a new test -- increment test id, write
#		separator and test information to log file.
#========================================================================
sub NextTest
{
   local($description) = @_;


   ++$testID;
   print LOGFILE '-' x 76, "\n";
   $testDescription = $description;
}

#========================================================================
# Function:	TestPasses()
# Purpose:	The current test passed.  Write result to logfile, and
#		increment the count of successful tests.
#========================================================================
sub TestPasses
{
   printf LOGFILE ("%3d %s%s%s", $testID, $testDescription,
		   ' ' x (68 - length($testDescription)), "PASS\n");
   # printf STDERR "%3d: pass (%s)\n", $testID, $testDescription;
   print STDERR ".";
   print STDERR "\n" if $testID % 70 == 0;
   ++$passCount;
}

#========================================================================
# Function:	TestFails()
# Purpose:	The current test failed.  Write result to logfile,
#		including the html which failed, and the output from weblint.
#========================================================================
sub TestFails
{
   local($html, @results) = @_;
   local($string);


   # printf STDERR "%3d: FAIL (%s)\n", $testID, $testDescription;
   $string = sprintf("%3d: %s", $testID, $testDescription);
   push(@failedTests, $string);
   print STDERR "!";
   print STDERR "\n" if $testID % 70 == 0;

   printf LOGFILE ("%3d %s%s%s", $testID, $testDescription,
		   ' ' x (68 - length($testDescription)), "FAIL\n");

   $html =~ s/\n/\n    /g;
   print LOGFILE "\n  HTML:\n    $html\n\n";
   print LOGFILE "  WEBLINT OUTPUT:\n";
   while (@results > 1)
   {
      ($line, $wid) = splice(@results, 0, 2);
      print LOGFILE "    line $line: $wid\n";
   }
   print LOGFILE "\n";
   ++$failCount;
}

#========================================================================
# Function:	PickTmpdir
# Purpose:	Pick a temporary working directory. If TMPDIR environment
#		variable is set, then we try that first.
#========================================================================
sub PickTmpdir
{
   local(@options) = @_;
   local($tmpdir);

   @options = ($ENV{'TMPDIR'}, @options) if defined $ENV{'TMPDIR'};
   foreach $tmpdir (@options)
   {
      return $tmpdir if -d $tmpdir && -w $tmpdir;
   }
   die "$PROGRAM: unable to find a temporary directory.\n",
       ' ' x (length($PROGRAM)+2), "tried: ",join(' ',@options),"\n";
}

#============================================================================
#============================================================================

__END__
simple syntactically correct html
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>this is the body</BODY>
</HTML>
#------------------------------------------------------------------------
paragraph usage
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>first paragraph<P>second paragraph</BODY>
</HTML>
#------------------------------------------------------------------------
html which starts with DOCTYPE specifier
####
<!DOCTYPE HTML PUBLIC '-//W3O//DTD WWW HTML 2.0//EN'>
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>this is the body</BODY>
</HTML>
#------------------------------------------------------------------------
acceptable usage of META element
####
<HTML><HEAD><TITLE>foo</TITLE>
<META NAME="IndexType" CONTENT="Service"></HEAD>
<BODY>this is the body</BODY></HTML>
#------------------------------------------------------------------------
correct use of information type and font style elements
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<EM>Emphasized Text</EM>
<CITE>Cited Text</CITE>
<STRONG>Strongly emphasized Text</STRONG>
<CODE>Teletype Text</CODE>
<SAMP>sequence of literal characters</SAMP>
<KBD>Keyboarded Text</KBD>
<VAR>Variable name</VAR>
<DFN>Defining instance</DFN>
<B>Bold text</B>
<I>Italic text</I>
<TT>Teletype text</TT>
<U>Underlined text</U>
<STRIKE>Striked through text</STRIKE>
<BIG>Big text</BIG>
<SMALL>Small text</SMALL>
<SUB>Subscript text</SUB>
<SUP>Superscript text</SUP>
</BODY></HTML>
#------------------------------------------------------------------------
IMG element with ALT and ISMAP attributes
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<IMG SRC=foo.gif ISMAP ALT="alt text">
</BODY></HTML>
#------------------------------------------------------------------------
newline within a tag
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<IMG SRC="foo.gif"
 ALT="alt text">
</BODY></HTML>
#------------------------------------------------------------------------
simple comment
####
<!-- comment before the HTML element -->
<HTML>
<!-- comment between the HTML and HEAD elements -->
<HEAD>
<!-- comment in the HEAD element -->
<TITLE>foo</TITLE></HEAD><BODY>
<!-- this is a simple comment in the body -->
this is the body
</BODY>
<!-- comment between end of BODY and end of HTML -->
</HTML>
<!-- comment after the end of the HTML element -->
####
#------------------------------------------------------------------------
comment with space before the closing >
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<!-- this is a simple comment -- >
this is the body
</BODY></HTML>

#------------------------------------------------------------------------
whitespace around the = of an element attribute
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<IMG SRC = foo.gif ALT="alt text">
</BODY></HTML>
#------------------------------------------------------------------------
legal unordered list
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<UL>
<LI>first item
<LI>second item</LI>
</UL>
</BODY></HTML>
#------------------------------------------------------------------------
legal definition list
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<DL>
<DT>first tag<DD>first definition
<DT>second tag<DD>second definition
</DL>
</BODY></HTML>
#------------------------------------------------------------------------
simple table
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<TABLE><TR><TH>height<TD>1.0<TR><TH>weight<TD>1.0</TABLE>
</BODY></HTML>
#------------------------------------------------------------------------
table without TR
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<TABLE><TH>height<TD>1.0<TR><TH>weight<TD>1.0</TABLE>
</BODY></HTML>
####
2:required-context
2:required-context
#------------------------------------------------------------------------
no HTML tags around document
####
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>this is the body</BODY>
####
1:html-outer
1:must-follow
#------------------------------------------------------------------------
whitespace between opening < and tag name
####
<HTML><HEAD>< TITLE>title</TITLE></HEAD>
<BODY>this is the body</BODY></HTML>
####
1:leading-whitespace
#------------------------------------------------------------------------
no TITLE element in HEAD
####
<HTML>
<HEAD></HEAD>
<BODY>this is the body</BODY>
</HTML>
####
2:empty-container
2:require-head
#------------------------------------------------------------------------
unclosed TITLE in HEAD
####
<HTML>
<HEAD><TITLE></HEAD>
<BODY>this is the body</BODY>
</HTML>
####
2:unclosed-element
#------------------------------------------------------------------------
bad style to use "here" as anchor text
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY><A HREF="foo.html">here</A></BODY>
</HTML>
####
3:here-anchor
#------------------------------------------------------------------------
mis-matched heading tags <H1> .. </H2>
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY><H1>title</H2></BODY>
</HTML>
####
3:heading-mismatch
#------------------------------------------------------------------------
obsolete element
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY><XMP>foobar()</XMP></BODY></HTML>
####
3:obsolete
#------------------------------------------------------------------------
illegal attribute in B element
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY><B FOO>foobar</B></BODY></HTML>
####
3:unknown-attribute
#------------------------------------------------------------------------
empty tag: <>
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY><>this is the body</BODY></HTML>
####
3:unknown-element
#------------------------------------------------------------------------
Netscape tags *without* Netscape extension enabled
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY BGCOLOR="#ffffff">
<CENTER>centered text</CENTER>
<BLINK>blinking text</BLINK>
<FONT SIZE="+1">larger font size text</FONT>
</BODY></HTML>
####
5:extension-markup
5:extension-markup
#------------------------------------------------------------------------
Netscape tags *with* Netscape extension enabled
-x Netscape
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY BGCOLOR="#ffffff">
<CENTER>centered text</CENTER>
<BLINK>blinking text</BLINK>
<FONT SIZE="+1">larger font size text</FONT>
</BODY></HTML>
####
#------------------------------------------------------------------------
not allowed to nest FORM elements
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<FORM METHOD=post ACTION="http://www.cre.canon.co.uk/foo">
<FORM METHOD=post ACTION="http://www.cre.canon.co.uk/foo">
This is inside the nested form
</FORM>
</FORM></BODY></HTML>
####
5:nested-element
#------------------------------------------------------------------------
CAPTION element appearing outside of TABLE or FIG
####
<HTML><HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<TABLE><CAPTION>legal use of caption</CAPTION></TABLE>
<CAPTION>this is an invalid use of caption</CAPTION>
</BODY></HTML>
####
4:required-context
#------------------------------------------------------------------------
LI element must be used in DIR, MENU, OL, OL or UL
####
<HTML><HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<DIR><LI>legal list item in DIR</DIR>
<MENU><LI>legal list item in MENU</MENU>
<OL><LI>legal list item in OL</OL>
<UL><LI>legal list item in UL</UL>
<LI>illegal list item
</BODY></HTML>
####
7:required-context
#------------------------------------------------------------------------
unclosed comment
####
<HTML><HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<!-- this is an unclosed comment >
</BODY></HTML>
####
3:unclosed-comment
#------------------------------------------------------------------------
use of physical font markup
-e physical-font
####
<HTML><HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<B>This is bold text</B>
<STRONG>This is strong text</STRONG>
</BODY></HTML>
####
3:physical-font
#------------------------------------------------------------------------
repeated attribute
####
<HTML><HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<IMG SRC="foo.gif" SRC="foo.gif" ALT="alt text">
</BODY></HTML>
####
3:repeated-attribute
#------------------------------------------------------------------------
no HTML tags around document, last thing is valid comment
####
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>this is the body</BODY>
<!-- this is a valid comment -->
####
1:html-outer
1:must-follow
#------------------------------------------------------------------------
spurious text between HEAD and BODY elements
####
<HTML><HEAD><TITLE>title</TITLE></HEAD>
Should not put any text here!
<BODY>this is the body</BODY></HTML>
####
3:must-follow
#------------------------------------------------------------------------
empty title element
####
<HTML><HEAD><TITLE></TITLE></HEAD>
<BODY>this is the body</BODY></HTML>
####
1:empty-container
#------------------------------------------------------------------------
empty list element
####
<HTML><HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<UL>
<LI>this is the first element
<LI>
<LI>this is the third or second element...
</UL>
</BODY></HTML>
####
5:empty-container
#------------------------------------------------------------------------
attributes on closing tag
####
<HTML><HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<A NAME="foobar">bleh</A NAME="foobar">
</BODY></HTML>
####
3:closing-attribute
#------------------------------------------------------------------------
use of ' as attribute value delimiter
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<IMG SRC = foo.gif ALT='alt text'>
</BODY></HTML>
####
2:attribute-delimiter
#------------------------------------------------------------------------
IMG without HEIGHT and WIDTH attributes
-e img-size
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<IMG SRC = foo.gif ALT="alt text">
</BODY></HTML>
####
2:img-size
#------------------------------------------------------------------------
non-empty container, with comment last thing
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<PRE>
Some text ...
<!-- last thing in container is a valid comment -->
</PRE>
</BODY></HTML>
####
#------------------------------------------------------------------------
use of -pedantic command-line switch
-pedantic
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<IMG SRC = foo.gif ALT="alt text">
<B>This is bold text -- should use the STRONG element</B>
<A HREF="foobar.html">non-existent file</A>
</BODY></HTML>
####
1:mailto-link
2:img-size
3:physical-font
#------------------------------------------------------------------------
leading whitespace in container
-e container-whitespace
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<A HREF=foobar.html> hello</A>
</BODY></HTML>
####
2:container-whitespace
#------------------------------------------------------------------------
valid Java applet
-x Netscape
-x Microsoft
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<APPLET CODEBASE="http://java.sun.com/JDK-prebeta1/applets/NervousText" CODE="NervousText.class" WIDTH=400 HEIGHT=75 ALIGN=CENTER>
<PARAM NAME="text" VALUE="This is the applet viewer.">
<BLOCKQUOTE>
If you were using a Java-enabled browser,
you wouldn't see this!
</BLOCKQUOTE>
</APPLET>
</BODY></HTML>
#------------------------------------------------------------------------
PARAM can only appear in an APPLET element
-x Netscape
-x Microsoft
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<PARAM NAME="text" VALUE="This is the applet viewer.">
</BODY></HTML>
####
2:required-context
#------------------------------------------------------------------------
valid use of Netscape 2 markup
-x Netscape
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<BIG>this is big text</BIG>
<SMALL>this is small text</SMALL>
<SUB>this is subscript text</SUB>
<SUP>this is superscript text</SUP>
<MAP NAME="map1">
<AREA SHAPE="RECT" COORDS="10,10,20,20" HREF="foo.html">
<AREA SHAPE="RECT" COORDS="40,40,50,50" NOHREF>
</MAP>
<IMG SRC="pic.gif" ALT=map USEMAP="#map1">
<FORM ENCTYPE="multipart/form-data" ACTION="_URL_" METHOD=POST>
<INPUT TYPE=submit VALUE="Send File">
</FORM>
</BODY></HTML>

#------------------------------------------------------------------------
AREA can only appear in a MAP, MAP must have a NAME
-x Netscape
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<AREA SHAPE="RECT" COORDS="10,10,20,20" HREF="foo.html">
<MAP>
<AREA SHAPE="RECT" COORDS="40,40,50,50" NOHREF>
</MAP>
</BODY></HTML>
####
2:required-context
3:required-attribute
#------------------------------------------------------------------------
non-empty list element, with comment last thing
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<UL>
<LI>line 9
<!-- line 10 -->
<LI>line 11
</UL>
</BODY></HTML>
####
#------------------------------------------------------------------------
html which doesn't start with DOCTYPE
-e require-doctype
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>this is the body</BODY>
</HTML>
####
1:require-doctype
#------------------------------------------------------------------------
html which starts with DOCTYPE
-e require-doctype
####
<!DOCTYPE HTML PUBLIC '-//W3O//DTD WWW HTML 2.0//EN'>
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>this is the body</BODY>
</HTML>
#------------------------------------------------------------------------
should use &gt; in place of >
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>
text with > instead of &gt;
</BODY>
</HTML>
####
4:literal-metacharacter
#------------------------------------------------------------------------
IMG element with LOWSRC attribute
-x Netscape
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>
<IMG SRC="foo.gif" LOWSRC="lowfoo.gif" ALT="alt text">
</BODY>
</HTML>
#------------------------------------------------------------------------
Java applet using Netscape extensions
-x Netscape
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY BACKGROUND="background.gif">
<APPLET CODEBASE="http://java.sun.com/JDK-prebeta1/applets/NervousText" CODE="NervousText.class" WIDTH=400 HEIGHT=75 ALIGN=CENTER>
<PARAM NAME="text" VALUE="This is the applet viewer.">
<BLOCKQUOTE>
If you were using a Java-enabled browser,
you wouldn't see this!
</BLOCKQUOTE>
</APPLET>
</BODY></HTML>
#------------------------------------------------------------------------
text appearing in unexpected context
####
<HTML>
<HEAD>
Having text here is not legal!
<TITLE>test</TITLE></HEAD>
<BODY>
<UL>
Having text here is not legal!
</UL>
<OL>
Having text here is not legal!
</OL>
<DL>
Having text here is not legal!
</DL>
<TABLE>
Having text here is not legal!
<TR>
Having text here is not legal!
<TD>This is ok</TD>
</TR>
</TABLE>
</BODY></HTML>
####
4:bad-text-context
8:bad-text-context
11:bad-text-context
14:bad-text-context
17:bad-text-context
19:bad-text-context
#------------------------------------------------------------------------
IMG element with illegal value for ALIGN attribute
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>
<IMG SRC=foo.gif ALIGN=MODDLE ALT="alt text=">
</BODY></HTML>
####
2:attribute-format
#------------------------------------------------------------------------
new Netscape markup
-x Netscape
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>
To <A HREF="foo.html" TARGET="myWindow">open a window</A>
<FONT COLOR="#00ff00">blue text</FONT>
<FORM ACTION="foo.html" METHOD=POST>
<TEXTAREA NAME=foo ROWS=24 COLS=24 WRAP=PHYSICAL>
hello</TEXTAREA>
</FORM>
</BODY>
</HTML>
#------------------------------------------------------------------------
valid FRAMESET example with FRAMES
-x Netscape
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<FRAMESET>
<FRAME SRC="cell.html">
<FRAME SRC="cell.html">
</FRAMESET>
</HTML>
#------------------------------------------------------------------------
FRAME outside of FRAMESET is illegal
-x Netscape
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>
<FRAME SRC="cell.html">
</BODY>
</HTML>
####
4:required-context

#------------------------------------------------------------------------
A valid JavaScript example
-x Netscape
####
<HTML>
<HEAD><TITLE>test</TITLE>
<SCRIPT LANGUAGE="JavaScript">
document.write("Hello net.")
</SCRIPT>
</HEAD>
<BODY>
That's all, folks.
</BODY>
</HTML>
#------------------------------------------------------------------------
FORM element with SELECT element which has SIZE attribute
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<FORM METHOD=post ACTION="http://www.cre.canon.co.uk/foo">
<SELECT NAME="foobar" SIZE="50,8">
<OPTION>foobar
</SELECT>
</FORM></BODY></HTML>
#------------------------------------------------------------------------
HR element can have percentage width in Netscape
-x Netscape
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<HR WIDTH="50%">
</BODY></HTML>
#------------------------------------------------------------------------
Legal use of Netscape-specific table attributes
-x Netscape
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<TABLE BORDER=2 CELLPADDING=2 CELLSPACING=2>
<TR><TH WIDTH="10%">Hello<TD WIDTH=2>World</TR>
</TABLE>
</BODY></HTML>
####

#------------------------------------------------------------------------
Ok to have empty TD elements in a table
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<TABLE>
<TR><TD></TD></TR>
</TABLE>
</BODY></HTML>
#------------------------------------------------------------------------
ordered lists of different TYPES
-x Netscape
####
<HTML>
<HEAD><TITLE>title</TITLE></HEAD>
<BODY>
<OL>
<LI>Basic ordered list item
</OL>
<OL TYPE=1>
<LI>Basic ordered list item (same as default)
</OL>
<OL TYPE=a>
<LI>Basic ordered list item
</OL>
<OL TYPE=A>
<LI>Basic ordered list item
</OL>
<OL TYPE=i>
<LI>Basic ordered list item
</OL>
<OL TYPE=I>
<LI>Basic ordered list item
</OL>
</BODY></HTML>
#------------------------------------------------------------------------
valid use of Microsoft specific markup
-x Microsoft
####
<HTML>
<HEAD><TITLE>title</TITLE>
<BGSOUND SRC="tune.wav" LOOP=5>
</HEAD>
<BODY TOPMARGIN=2 LEFTMARGIN=2>
<TABLE CELLPADDING=2 CELLSPACING=2>
<CAPTION ALIGN=CENTER VALIGN=BOTTOM>Hello</CAPTION>
<TR><TD></TD></TR>
</TABLE>
<FONT COLOR=RED FACE="Lucida" SIZE=3>Red lucida text</FONT>
<MARQUEE BGCOLOR="#FFFFBB" DIRECTION=RIGHT BEHAVIOR=SCROLL
SCROLLAMOUNT=10 SCROLLDELAY=200 WIDTH="50%" HEIGHT="50%"
><FONT COLOR="WHITE"
>This is a scrolling marquee.</FONT></MARQUEE>
</BODY></HTML>
#------------------------------------------------------------------------
more valid use of Microsoft specific markup
-x Microsoft
####
<HTML>
<HEAD><TITLE>title</TITLE>
</HEAD>
<BODY ALINK=red VLINK=blue LINK=green>
Hello
<MARQUEE WIDTH=200 HEIGHT=200>Hello</MARQUEE>
</BODY></HTML>
#------------------------------------------------------------------------
Use of Microsoft markup without Microsoft extension
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY TOPMARGIN=2 LEFTMARGIN=2>
<FONT COLOR=RED FACE="Lucida" SIZE=3>Red lucida text</FONT>
</BODY>
</HTML>
####
3:extension-attribute
3:extension-attribute
4:extension-attribute
#------------------------------------------------------------------------
valid FRAMESET with ROWS and COLS attributes
-x Netscape
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<FRAMESET ROWS="20%,60%,20%" COLS="*,2*">
<FRAME SRC="cell.html">
<FRAME SRC="cell.html">
<FRAME SRC="cell.html">
<FRAME SRC="cell.html">
<FRAME SRC="cell.html">
<FRAME SRC="cell.html">
</FRAMESET>
</HTML>
#------------------------------------------------------------------------
BASE element with only TARGET attribute (Netscape)
-x Netscape
####
<HTML>
<HEAD>
<BASE TARGET="banana">
<TITLE>test</TITLE>
</HEAD>
<BODY>this is the body</BODY>
</HTML>
#------------------------------------------------------------------------
use of FONT element with no attributes
-x Netscape
####
<HTML>
<HEAD>
<TITLE>test</TITLE>
</HEAD>
<BODY>
this is the <FONT>body</FONT>
</BODY>
</HTML>
####
6:expected-attribute
#------------------------------------------------------------------------
Netscape table with percentage WIDTH
-x Netscape
####
<HTML>
<HEAD>
<TITLE>test</TITLE>
</HEAD>
<BODY>
<TABLE BORDER = 5 CELLPADDING=5 CELLSPACING=5 WIDTH="100%">
<TR><TD>Hello</TD></TR>
</TABLE>
</BODY>
</HTML>
#------------------------------------------------------------------------
Netscape list with different TYPE bullets
-x Netscape
####
<HTML>
<HEAD>
<TITLE>test</TITLE>
</HEAD>
<BODY>
<UL TYPE="disc">
<LI>First item
<LI TYPE="circle">circle bullet
<LI TYPE="square">square bullet
</UL>
</BODY>
</HTML>
#------------------------------------------------------------------------
correct and incorrect values for CLEAR attribute
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>
ok left<BR CLEAR=LEFT>
ok right<BR CLEAR=RIGHT>
ok all<BR CLEAR=ALL>
not ok<BR CLEAR=RIHGT>
</BODY>
</HTML>
####
7:attribute-format
#------------------------------------------------------------------------
leading whitespace in list item
-e container-whitespace
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>
<UL>
<LI>First item
<LI> Second item
<LI>Third item
</UL>
</BODY>
</HTML>
####
6:container-whitespace
#------------------------------------------------------------------------
illegal color attribute values
-x Netscape
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY ALINK="#ffaaff" VLINK="#ggaagg">
This is the body of the page
</BODY>
</HTML>
####
3:attribute-format

#------------------------------------------------------------------------
Valid use of the Microsoft color attributes
-x Microsoft
####
<HTML>
<HEAD>
<TITLE>test</TITLE>
</HEAD>
<BODY TEXT=black BGCOLOR=yellow LINK=Blue ALINK=red VLINK=green>
<FONT COLOR="#ff0000">red text</FONT>
<TABLE BORDER BORDERCOLOR=teal BORDERCOLORLIGHT=Fuchsia
	BORDERCOLORDARK=Gray>
<TR><TH>Bleh</TH></TR>
</TABLE>
</BODY>
</HTML>
#------------------------------------------------------------------------
use of percentages in WIDTH attribute
-x Netscape
####
<HTML>
<HEAD>
<TITLE>test</TITLE>
</HEAD>
<BODY>
<TABLE WIDTH="100%">
<TR><TH>Bleh</TH><TD>Foobar</TD></TR>
</TABLE>
</BODY>
</HTML>
#------------------------------------------------------------------------
complicated FRAME example
-x Netscape
####
<HTML>
<HEAD>
        <TITLE>Netscape example</TITLE>
</HEAD>
<FRAMESET COLS="50%,50%">
<NOFRAMES>
<BODY>
<H1>Title of non-frames version</H1>
This will be seen if you don't have a FRAME capable browser
</BODY>
</NOFRAMES>

<FRAMESET ROWS="50%,50%">
  <FRAME SRC="cell.html"><FRAME SRC="cell.html">
</FRAMESET>
<FRAMESET ROWS="33%,33%,33%">
  <FRAME SRC="cell.html"><FRAME SRC="cell.html">
<FRAME SRC="cell.html">
</FRAMESET>
</FRAMESET>
</HTML>
#------------------------------------------------------------------------
unquoted attribute value which should be quoted
-x Netscape
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY TEXT=#00ffff>
<TABLE WIDTH=100%>
<TR><TH>Heading<TD>Datum</TD></TR>
</TABLE>
</BODY>
</HTML>
####
3:quote-attribute-value
4:quote-attribute-value
#------------------------------------------------------------------------
use of > in a PRE element
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>
<PRE>
   if (x > y)
      printf("x is greater than y");
</PRE>
</BODY>
</HTML>
####
5:meta-in-pre
#------------------------------------------------------------------------
heading inside an anchor
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>
<A NAME="foo"><H2>Bogus heading in anchor</H2></A>
</BODY>
</HTML>
####
4:heading-in-anchor
#------------------------------------------------------------------------
TITLE of page is longer then 64 characters
####
<HTML>
<HEAD><TITLE>WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW</TITLE></HEAD>
<BODY>
body of page
</BODY>
</HTML>
####
2:title-length
#------------------------------------------------------------------------
use of WRAP=HARD in TEXTAREA
-x Netscape
####
<HTML>
<HEAD>
<TITLE>test</TITLE>
</HEAD>
<BODY>
<FORM ACTION="foo.html" METHOD=POST>
<TEXTAREA NAME=foo ROWS=24 COLS=24 WRAP=HARD>
hello</TEXTAREA>
</FORM>
</BODY>
</HTML>
#------------------------------------------------------------------------
empty list items
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>
<UL>
<LI>
<LI>Second item
<LI>
<LI>Fourth item
<LI>
</UL>
</BODY>
</HTML>
####
5:empty-container
7:empty-container
9:empty-container
#------------------------------------------------------------------------
IMG with ALT set to empty string
####
<HTML>
<HEAD>
<TITLE>test</TITLE>
</HEAD>
<BODY>
<IMG SRC="foo.gif" ALT="">
<IMG SRC="foo.gif" ALT=''>
</BODY>
</HTML>
#------------------------------------------------------------------------
use of > multiple times in a PRE element
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>
<PRE>
   if (x > y)
      foobar();
   if (x > z)
      barfoo();
</PRE>
</BODY>
</HTML>
####
5:meta-in-pre
7:meta-in-pre
#------------------------------------------------------------------------
don't check attributes of unknown elements
####
<HTML>
<HEAD><TITLE>test</TITLE></HEAD>
<BODY>
Hello, <BOB SIZE="+1">World!</BOB>
</BODY>
</HTML>
####
4:unknown-element
4:unknown-element
#------------------------------------------------------------------------
images with all variants of ALIGN for Netscape
-x Netscape
####
<HTML>
<HEAD>
<TITLE>test</TITLE>
</HEAD>
<BODY>
<IMG SRC="foo.gif" ALT="" ALIGN=LEFT>
<IMG SRC="foo.gif" ALT="" ALIGN=RIGHT>
<IMG SRC="foo.gif" ALT="" ALIGN=TOP>
<IMG SRC="foo.gif" ALT="" ALIGN=TEXTTOP>
<IMG SRC="foo.gif" ALT="" ALIGN=MIDDLE>
<IMG SRC="foo.gif" ALT="" ALIGN=ABSMIDDLE>
<IMG SRC="foo.gif" ALT="" ALIGN=BASELINE>
<IMG SRC="foo.gif" ALT="" ALIGN=BOTTOM>
<IMG SRC="foo.gif" ALT="" ALIGN=ABSBOTTOM>
</BODY>
</HTML>
#------------------------------------------------------------------------
ISINDEX with PROMPT
####
<HTML>
<HEAD>
<ISINDEX PROMPT="Enter Surname:">
<TITLE>test</TITLE>
</HEAD>
<BODY>
Hello, World!
</BODY>
</HTML>
#------------------------------------------------------------------------
ISINDEX with HREF is illegal in HTML 3.2
####
<HTML>
<HEAD>
<ISINDEX HREF="phone.db" PROMPT="Enter Surname:">
<TITLE>test</TITLE>
</HEAD>
<BODY>
Hello, World!
</BODY>
</HTML>
####
3:extension-attribute
#------------------------------------------------------------------------
Checking against new microsoft spec #1
-x Microsoft
####
<HTML>
<HEAD>
  <TITLE>test</TITLE>
  <BASE HREF="http://www.foo.bar/" TARGET="that_window">
  <BGSOUND SRC="tune.wav" LOOP=5>
  <ISINDEX ACTION="phone.db" PROMPT="Enter Surname:">
  <LINK HREF="other-doc.html">
  <META HTTP-EQUIV=refresh CONTENT="5; URL=foo.html">
  <META NAME="ROBOTS" CONTENT="NOFOLLOW">
</HEAD>
<BODY BACKGROUND="background.gif" BGCOLOR=white
 BGPROPERTIES=FIXED LEFTMARGIN=2 LINK=red TEXT=black VLINK=blue
 TOPMARGIN=5>
<A HREF="foo.html" NAME="foobar" REL=parent REV=made
 TARGET="_top" TITLE="The Foo Page">Foo</A>
<ADDRESS>Neil Bowers, Canon Research Europe</ADDRESS>
<APPLET ALIGN=CENTER ALT="an applet"
 CODEBASE="http://foo.com/applets/" CODE="foo.app"
 HEIGHT=100 HSPACE=5 NAME="Foo Applet" VSPACE=5 WIDTH=100>
If you were using a Java enabled browser, you wouldn't see this.
</APPLET>
<MAP NAME="mappie">
<AREA COORDS="1,1,1,1" SHAPE=RECT HREF="http://www.foo.com/"
 TARGET="_top">
</MAP>
<B>bold text</B>
<BASEFONT COLOR=red ID=times SIZE=3>
<BIG>This text is a little bit bigger</BIG>
<BLOCKQUOTE>This is in a blockquote element</BLOCKQUOTE>
<BR CLEAR=LEFT><BR CLEAR=RIGHT><BR CLEAR=ALL>
<CENTER>This text will be centered</CENTER>
<CITE>This is a citation</CITE>
<CODE>foobar() if $do_foo;</CODE>
<COMMENT>This is a comment</COMMENT>
<DL><DT>coffee<DD>one of the basic food groups</DL>
<DFN>This is a definition</DFN>
<DIR><LI>dirlist item 1<LI>dirlist item 2</DIR>
<DIV ALIGN=LEFT>left justified text</DIV>
<DIV ALIGN=CENTER>center justified text</DIV>
<DIV ALIGN=RIGHT>right justified text</DIV>
<EM>emphasized text</EM>
<EMBED HEIGHT=50 NAME="embeddedObject"
 SRC="http://www.foo.com/object" WIDTH=50>
<FONT FACE="arial" COLOR=red SIZE=4>red arial text</FONT>
<FORM METHOD=post ACTION="http://www.cre.canon.co.uk/foo"
 TARGET="fooWindow">
  <INPUT NAME="imgControl" SRC="foo.gif"
   TYPE=IMAGE VALUE=5>
  <INPUT SIZE="50,1" TYPE=TEXT MAXLENGTH=100
   VALUE="hello">
  <INPUT SIZE="50,1" TYPE=CHECKBOX CHECKED>
  <SELECT MULTIPLE SIZE=100 NAME=fruit>
    <OPTION SELECTED VALUE=1>Bananas
    <OPTION          VALUE=2>Oranges
  </SELECT>
  <TEXTAREA COLS=60 NAME=textbox ROWS=5>
    default contents
  </TEXTAREA>
</FORM>
<H1>level one heading</H1>
<HR ALIGN=LEFT COLOR=blue NOSHADE SIZE=4 WIDTH="80%">
<I>this is in italics</I>
<IFRAME ALIGN=CENTER FRAMEBORDER=1 MARGINHEIGHT=2 MARGINWIDTH=2
 NAME="bob" SCROLLING=YES SRC="bob.htm">
  This is the contents of a floating frame.
</IFRAME>
<IMG ALIGN=LEFT ALT="alt text" BORDER=1
 DYNSRC="dynsrc.mpg" HEIGHT=50 HSPACE=5 ISMAP LOOP=4
 SRC="foo.gif" USEMAP VSPACE=5 WIDTH=50>
<KBD>text entered at the keyboard</KBD>
<OL><LI TYPE=A VALUE=1>First item</OL>
<LISTING>This is for listings. Ugh.</LISTING>
<MARQUEE BEHAVIOR=SCROLL BGCOLOR="#FFFFBB"
 DIRECTION=RIGHT HEIGHT=40 HSPACE=10 LOOP=INFINITE
 SCROLLAMOUNT=10 SCROLLDELAY=200 VSPACE=10 WIDTH=500>
  This is a scrolling marquee.
</MARQUEE>
<MENU><LI>first item in menu<LI>second menu item</MENU>
<NOBR>a long line of text which i don't want to be broken</NOBR>
<OBJECT ALIGN=CENTER CLASSID="CLSID:foo"
 CODEBASE="foo/" CODETYPE=dunno DATA="foo.data"
 HEIGHT=50 NAME=bob
 TYPE=image WIDTH=50>
  contents of object element.
  <!-- dunno about correct values for TYPE yet -->
  <PARAM NAME=home VALUE="http://www.home.com" DATAFLD=field DATASRC=bob>
</OBJECT>
<P ALIGN=CENTER>centered paragraph</P>
<PLAINTEXT>some plain text</PLAINTEXT>
<PRE>some preformatted text</PRE>
<SAMP>some sample text</SAMP>
<SCRIPT LANGUAGE=VBscript>
  Visual basic script goes here
</SCRIPT>
<SMALL>some small text</SMALL>
<SPAN STYLE="margin-left: 1.0in">blah blah</SPAN>
<STRIKE>strike-through text</STRIKE>
<STRONG>strong text</STRONG>
Subscript: oxygen is O<SUB>2</SUB>
Superscript: Unix<SUP>TM</SUP>
<TABLE ALIGN=LEFT BACKGROUND="foo.gif" BGCOLOR=white BORDER=1
 BORDERCOLOR=black BORDERCOLORLIGHT=white BORDERCOLORDARK=black
 CELLPADDING=4 CELLSPACING=4 COLS=2 WIDTH="100%" FRAME=BORDER
 RULES=ALL>
<CAPTION>This is the caption for the table</CAPTION>

<COLGROUP ALIGN=RIGHT>
  <COL ALIGN=LEFT>
  <COL ALIGN=RIGHT>

  <!-- table heading section -->
  <THEAD>
    <TR ALIGN=LEFT BGCOLOR=white
     BORDERCOLOR=black BORDERCOLORDARK=black
     BORDERCOLORLIGHT=white VALIGN=TOP>
      <TH ALIGN=CENTER BACKGROUND="header.gif" BGCOLOR=white
       BORDERCOLOR=black BORDERCOLORDARK=black
       BORDERCOLORLIGHT=white COLSPAN=1 NOWRAP ROWSPAN=1
       VALIGN=TOP>Name<TH>Description
    </TR>
  </THEAD>

  <!-- table body section -->
  <TBODY>
    <TR>
      <TD ALIGN=CENTER BACKGROUND="header.gif" BGCOLOR=white
       BORDERCOLOR=black BORDERCOLORDARK=black
       BORDERCOLORLIGHT=white COLSPAN=1 NOWRAP ROWSPAN=1
       VALIGN=TOP>Banana<TD>Bendy, Yellow, Tasty
    </TR>
  </TBODY>

  <!-- table footer section -->
  <TFOOT>
    <TR>
      <TH>Name<TH>Description
    </TR>
  </TFOOT>

</TABLE>

<TT>teletype text</TT>
<U>underlined text</U>
<UL><LI>ordered item 1<LI>unordered 2</UL>
<VAR>variable</VAR>
<NOBR>let's do an explicit<WBR>line break</NOBR>
<XMP>some example text</XMP>
</BODY>
</HTML>
#------------------------------------------------------------------------
Checking new microsoft spec #2 - FRAMESET
-x Microsoft
####
<HTML>
<HEAD>
  <TITLE>test</TITLE>
  <BASE HREF="http://www.foo.bar/" TARGET="that_window">
  <BGSOUND SRC="tune.wav" LOOP=5>
</HEAD>
<FRAMESET COLS=2 ROWS=2 FRAMEBORDER=1 FRAMESPACING=5>
  <FRAME FRAMEBORDER=1 MARGINHEIGHT=4 MARGINWIDTH=4
   NAME="myFrame" NORESIZE SCROLLING=YES SRC="foo.html">
  <NOFRAMES>
    <BODY>
      This is what you see if you don't have a frames browser
    </BODY>
  </NOFRAMES>
</FRAMESET>
</HTML>
#------------------------------------------------------------------------
basic structure with Wilbur enabled
####
<HTML>
<HEAD>
  <TITLE>test</TITLE>
</HEAD>
<BODY BACKGROUND="back.gif" BGCOLOR=white TEXT=black
 LINK=blue VLINK=red ALINK=purple>
    Hello, World!
</BODY>
</HTML>
#------------------------------------------------------------------------
Wilbur test #2
####
<HTML>
<HEAD>
    <ISINDEX PROMPT="text prompt">
    <TITLE>test</TITLE>
    <LINK HREF="foo" REL="rel" REV=MADE TITLE="le title">
</HEAD>
<BODY>
<BASEFONT SIZE=4>
    <APPLET ALIGN=LEFT ALT="alt text" CODE="foo code"
     CODEBASE="applets" HEIGHT=100 HSPACE=5 NAME=applet
     VSPACE=5 WIDTH=100>
        <PARAM NAME="fruit" VALUE="banana">
    </APPLET>
<MAP NAME="testmap">
    <AREA ALT="alt test" COORDS="1,1,2,2" SHAPE=RECT
     HREF="foo.html">
    <AREA COORDS="2,2,4,4" SHAPE=CIRCLE NOHREF>
</MAP>
<BR><BR CLEAR=LEFT><BR CLEAR=RIGHT><BR CLEAR=ALL><BR CLEAR=NONE>
<DIR><LI>item 1<LI>item 2</DIR>
<DIR COMPACT><LI>item 1<LI>item 2</DIR>
<DIV>a text division</DIV>
<DIV ALIGN=LEFT>left aligned text</DIV>
<DIV ALIGN=CENTER>center aligned text</DIV>
<DIV ALIGN=RIGHT>right aligned text</DIV>
<FONT SIZE=4>size 4 text</FONT>
<FONT COLOR=red>red text</FONT>
<H1 ALIGN=LEFT>left aligned level 1 heading</H1>
<H2 ALIGN=CENTER>centered level 2 heading</H2>
<H3 ALIGN=RIGHT>right aligned level 3 heading</H3>
<H4 ALIGN=LEFT>left aligned level 4 heading</H4>
<H5 ALIGN=CENTER>centered level 5 heading</H5>
<H6 ALIGN=RIGHT>right aligned level 6 heading</H6>
<IMG ALIGN=LEFT ALT="alt text" BORDER=1
 HEIGHT=50 HSPACE=5 ISMAP
 SRC="foo.gif" USEMAP VSPACE=5 WIDTH=50>
<UL><LI TYPE=DISC>item 1<LI TYPE=SQUARE>item 2
    <LI TYPE=CIRCLE>item 3</UL>
<OL><LI TYPE=A VALUE=1>item 1<LI TYPE=a>item 2
    <LI TYPE=i>item 3<LI TYPE=I>item 4<LI TYPE=1>item 5</OL>
<MENU><LI>item 1<LI>item 2</MENU>
<MENU COMPACT><LI>compact item 1<LI>compact item 2</MENU>
<OL TYPE=a START=1 COMPACT><LI>item 1<LI>item 2</OL>
<P ALIGN=CENTER>centered paragraph</P>
<UL TYPE=disc COMPACT><LI>item 1<LI>item 2</UL>
</BODY>
</HTML>
#------------------------------------------------------------------------
BASEFONT must have SIZE attribute
<none>
-x Netscape
####
<HTML>
<HEAD>
  <TITLE>test</TITLE>
</HEAD>
<BODY>
<BASEFONT>
</BODY>
</HTML>
####
6:required-attribute
#------------------------------------------------------------------------
Anchor (A) element with Netscape 4 attributes for Javascript
-x Netscape
####
<HTML>
<HEAD>
  <TITLE>test</TITLE>
</HEAD>
<BODY>
<A HREF=foo NAME=name ONCLICK="click()" ONMOUSEOUT="out()"
   ONMOUSEOVER="over()" TARGET="_top">fun stuff</A>
</BODY>
</HTML>
#------------------------------------------------------------------------
Legal use of ADDRESS element
<none>
-x Netscape
-x Microsoft
####
<HTML>
<HEAD>
  <TITLE>test</TITLE>
</HEAD>
<BODY>
Hello, World!
<ADDRESS>Neil Bowers</ADDRESS>
</BODY>
</HTML>
#------------------------------------------------------------------------
Netscape use of APPLET element
-x Netscape
####
<HTML><HEAD><TITLE>test</TITLE></HEAD>
<BODY>
<APPLET ALIGN=CENTER
        ALT="alternate text"
        CODEBASE="StarField/"
        CODE="stars.class"
        WIDTH=400
        HEIGHT=100
        VSPACE=5
        HSPACE=5
        MAYSCRIPT
        NAME=Bob
>

<PARAM NAME="numstars" VALUE="50">
</APPLET>

<APPLET ARCHIVE="archive.jar"
        CODE="stars.class">
<PARAM NAME="numstars" VALUE="50">
</APPLET>

</BODY>
</HTML>
#------------------------------------------------------------------------
Netscape client-side image map with JavaScript attributes
-x Netscape
####
<HTML><HEAD><TITLE>test</TITLE></HEAD><BODY>
<MAP NAME="mainmap">
          <AREA COORDS="0,0,65,24" HREF="/escapes/index.html">
          <AREA SHAPE=circle COORDS="50,50,65,65" HREF="foo/" NAME=Bob>
          <AREA SHAPE=rect COORDS="20,20,65,65" NOHREF TARGET="_top">
          <AREA SHAPE=poly COORDS="20,20,65,65,30,65" HREF="bar/"
                ONMOUSEOVER="over()" ONMOUSEOUT="out()">
</MAP>
</BODY></HTML>
#------------------------------------------------------------------------
The text style elements supported by Netscape 4
-x Netscape
####
<HTML><HEAD><TITLE>test</TITLE></HEAD><BODY>
    <B>      bold text        </B>
    <BIG>    big text         </BIG>
    <BLINK>  blinking text    </BLINK>
    <I>      italic text      </I>
    <KBD>    keyboard text    </KBD>
    <CITE>   citation         </CITE>
    <CODE>   code goes here   </CODE>
    <EM>     emphasised text  </EM>
    <S>      strikeout type   </S>
    <SAMP>   sample text      </SAMP>
    <SMALL>  small text       </SMALL>
    <STRIKE> strikeout text   </STRIKE>
    <STRONG> strong emphasis  </STRONG>
    <SUB>    subscript text   </SUB>
    <SUP>    superscript text </SUP>
    <TT>     typewriter font  </TT>
    <U>      underlined text  </U>
    <BLOCKQUOTE>blockquoted text</BLOCKQUOTE>
    <FONT FACE=Helvetica SIZE=4 COLOR=red>red helvetica text</FONT>
</BODY></HTML>
#------------------------------------------------------------------------
Use of BASE element with just the HREF attribute
<none>
-x Netscape
-x Microsoft
####
<HTML>
<HEAD>
    <TITLE>test</TITLE>
    <BASE HREF="http://www.cre.canon.co.uk/~neilb/">
</HEAD><BODY>
<A HREF="weblint/">Weblint home page</A>
</BODY></HTML>
#------------------------------------------------------------------------
BODY element with all Netscape attributes
-x Netscape
####
<HTML>
<HEAD>
    <TITLE>test</TITLE>
</HEAD>
<BODY ALINK=red BACKGROUND="background.gif" BGCOLOR=white LINK=blue
      TEXT=BLACK ONBLUR="blur()" ONFOCUS="focus()" ONLOAD="load()"
      ONUNLOAD="unload()" VLINK="purple">
Hello, World!
</BODY></HTML>
#------------------------------------------------------------------------
EMBED element with Netscape enabled
-x Netscape
####
<HTML><HEAD><TITLE>embed test</TITLE></HEAD>
<BODY>
<NOEMBED>
This page requires a web browser which supports the EMBED element.
</NOEMBED>
<EMBED ALIGN=CENTER BORDER=1 FRAMEBORDER=NO HEIGHT=250 WIDTH=150
       SRC="MyMovie.mov" CONTROLS=TRUE
       HSPACE=5 VSPACE=5 PALETTE=FOREGROUND PLUGINSPAGE="plugins/"
       TYPE="image/gif" HIDDEN=FALSE
       >
</BODY></HTML>
#------------------------------------------------------------------------
FORM with Netscape JavaScript extensions
-x Netscape
####
<HTML><HEAD><TITLE>embed test</TITLE></HEAD>
<BODY>
<FORM ACTION="foo.pl" ENCTYPE="encoding" METHOD=GET NAME=Bob
      ONRESET="reset()" ONSUBMIT="submit()" TARGET="_top">
<INPUT TYPE=BUTTON NAME=button ONCLICK="click()">
<INPUT TYPE=CHECKBOX NAME=box CHECKED ONCLICK="click()" VALUE="bob">
<INPUT TYPE=FILE NAME=file VALUE="foo">
<INPUT TYPE="hidden" NAME="password" VALUE="weblint">
<INPUT TYPE=IMAGE ALIGN=LEFT NAME=image SRC="foo.gif">
<INPUT TYPE=PASSWORD MAXLENGTH=16 NAME=password ONSELECT="select()"
       SIZE=24 VALUE="bob">
<INPUT TYPE=RADIO NAME=radio ONCLICK="click()" VALUE="bob" CHECKED>
<INPUT TYPE=RESET NAME=reset ONCLICK="reset()" VALUE="Reset">
<INPUT TYPE=SUBMIT NAME=submit VALUE=" Submit ">
<INPUT TYPE=TEXT MAXLENGTH=64 NAME=title ONBLUR="blur()" ONCHANGE="change()"
       ONFOCUS="focus()" ONSELECT="select()" SIZE=24 VALUE="">
<KEYGEN NAME=halt CHALLENGE="who goes there?">
<SELECT NAME=Name MULTIPLE ONBLUR="blur()" ONCHANGE="change()"
        ONCLICK="click()" ONFOCUS="focus()" SIZE=2>
    <OPTION VALUE="Bob" SELECTED>Bob
    <OPTION VALUE="Fred">Fred
</SELECT>
<TEXTAREA COLS=50 NAME=textarea ONBLUR="blur()" ONCHANGE="change()"
          ONFOCUS="focus()" ONSELECT="select()" ROWS=4 WRAP=HARD>
    context of text area
</TEXTAREA>
</FORM>
</BODY></HTML>
#------------------------------------------------------------------------
H1 through H6 with combinations of ALIGN attribute
<none>
-x Netscape
-x Microsoft
####
<HTML><HEAD><TITLE>embed test</TITLE></HEAD>
<BODY>
<H1>Level 1 heading</H1>
<H2 ALIGN=LEFT>level 2 heading</H2>
<H3 ALIGN=CENTER>level 3</H3>
<H4 ALIGN=CENTER>level 4</H4>
<H5 ALIGN=CENTER>level 5</H5>
<H6 ALIGN=CENTER>level 6</H6>
</BODY></HTML>
#------------------------------------------------------------------------
HR with all attributes set
<none>
-x Netscape
-x Microsoft
####
<HTML><HEAD><TITLE>embed test</TITLE></HEAD>
<BODY>
Hello
<HR NOSHADE WIDTH="50%" SIZE=3 ALIGN=CENTER>
World
</BODY></HTML>
#------------------------------------------------------------------------
Netscape LAYERs
-x Netscape
####
<HTML><HEAD><TITLE>embed test</TITLE></HEAD>
<BODY>
    <LAYER ID=layer1 TOP=50 LEFT=100>
        <H1>Layer 1 heading</H1>
        <P>Lots of content for this layer</P>
        </LAYER>

    <LAYER ID=layer2 TOP=100 LEFT=200>
        <P>Content for layer 2</P>
    </LAYER>

    <LAYER ID=layer3 TOP=200 LEFT=260>
        <H1>This heading is all there is in layer3</H1>
    </LAYER>

    <NOLAYER>
        This page is written for a browser which supports
        the LAYER element, such as Netscape.
    </NOLAYER>
</BODY></HTML>
#------------------------------------------------------------------------
Netscape example using LINK to link to an external stylesheet
-x Netscape
####
<HTML>
<HEAD>

    <TITLE>A Good Title</TITLE>

            <LINK REL=STYLESHEET TYPE="text/JavaScript"

                HREF="http://style.com/mystyles1" TITLE="Cool">

    </HEAD>
<BODY>
Hello, World!
</BODY></HTML>
#------------------------------------------------------------------------
Netscape MULTICOL example
-x Netscape
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD>
<BODY>
<MULTICOL COLS=2 GUTTER=5 WIDTH="500">
Blah blah blah.
</MULTICOL>
</BODY></HTML>
#------------------------------------------------------------------------
Use of the NOBR element with an explicit word break
-x Netscape
-x Microsoft
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD>
<BODY>
<NOBR>This is a very long ling<WBR>which we don't want broken up.</NOBR>
</BODY></HTML>
#------------------------------------------------------------------------
Use of the SERVER tag with Netscape's livewire
-x Netscape
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD>
<BODY>
<SERVER>

   database.connect("INFORMIX", "blue", "ADMIN", "MANAGER", "mydb")

</SERVER>
</BODY></HTML>
#------------------------------------------------------------------------
Use of the SPACER element
-x Netscape
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD>
<BODY>
Hello
<SPACER ALIGN=CENTER HEIGHT=100 SIZE=100 TYPE=VERTICAL WIDTH=100>
World
</BODY></HTML>
#------------------------------------------------------------------------
Use of STYLE and SPAN with Netscape
-x Netscape
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD>
<BODY>
    <STYLE TYPE="text/javascript">

            classes.initDropCap.fontSize="12pt";

            classes.initDropCap.lineHeight = "12pt";

            classes.initDropCap.fontSize *= 2; // 200%

            classes.initDropCap.align = "left";

    </STYLE>

    <P><SPAN class="initDropCap">T</SPAN>his is ...</P>
</BODY></HTML>
#------------------------------------------------------------------------
Netscape TABLE example
-x Netscape
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD>
<BODY>
<TABLE ALIGN=LEFT BGCOLOR=white BORDER=1 CELLPADDING=5 CELLSPACING=5
       HEIGHT=20 HSPACE=5 WIDTH="100%" VSPACE=5 COLS=2>
<CAPTION ALIGN=CENTER>This is the caption</CAPTION>
<TR ALIGN=CENTER BGCOLOR=white VALIGN=MIDDLE>
    <TH ALIGN=RIGHT BGCOLOR=black COLSPAN=1 NOWRAP ROWSPAN=2 VALIGN=BOTTOM>
        Hello</TH>
    <TD ALIGN=LEFT BGCOLOR=red COLSPAN=1 NOWRAP>
        World</TD>
</TR>
</TABLE>
</BODY></HTML>
#------------------------------------------------------------------------
Microsoft Anchor (A) usage
-x Microsoft
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD>
<BODY>
<A ACCESSKEY="a" CLASS=thing DATAFLD=field DATASRC=foo HREF="foobar"
   ID=Bob LANG=ja LANGUAGE=JAVASCRIPT METHODS=method NAME=bob
   REL="stylesheet" REV="stylesheet" STYLE="foo" TARGET="_top"
   TITLE="title" URN="boburn" ONBLUR="blur()" ONDBLCLICK="double()"
   ONHELP="help()" ONKEYPRESS="key()" ONMOUSEDOWN="down()" ONMOUSEOUT="out()"
   ONMOUSEUP="up()" ONCLICK="foo()" ONFOCUS="foo()" ONKEYDOWN="foo()"
   ONKEYUP="foo()" ONMOUSEMOVE="move()" ONMOUSEOVER="over()"
   ONSELECTSTART="start()">foo</A>
</BODY></HTML>
#------------------------------------------------------------------------
OPTION can have an optional closing tag
<none>
-x Microsoft
-x Netscape
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD>
<BODY>
<FORM ACTION="foo.pl" METHOD=POST>
<SELECT NAME=COLOR>
<OPTION VALUE=red>Red
<OPTION VALUE=green>Green</OPTION>
<OPTION VALUE=blue>Blue</OPTION>
</SELECT>
</FORM>
</BODY></HTML>
#------------------------------------------------------------------------
Should now get a warning if you have an empty OPTION in a SELECT
<none>
-x Microsoft
-x Netscape
####
<HTML><HEAD><TITLE>foo</TITLE></HEAD>
<BODY>
<FORM ACTION="foo.pl" METHOD=POST>
<SELECT NAME=COLOR>
<OPTION VALUE=red>
<OPTION VALUE=green>Green</OPTION>
<OPTION VALUE=blue>Blue</OPTION>
</SELECT>
</FORM>
</BODY></HTML>
####
5:empty-container
#------------------------------------------------------------------------
