: # use perl
        eval 'exec perl -S $0 "$@"'
                if $runnning_under_some_shell;

#
# test.pl - regression tests for weblint
#
# Copyright (C) 1995,1996 Neil Bowers.  All rights reserved.
#
# See README for additional blurb.
# Bugs, comments, suggestions welcome: neilb@khoral.com
#
$VERSION	= '1.008';
($PROGRAM = $0) =~ s@.*/@@;
$FILENAME	= 'testfile.html';
$LOGFILE	= 'weblint-test.log';
$ENV{WEBLINTRC} = '/dev/null';
@TMPDIR_OPTIONS	= ('/usr/tmp', '/tmp', '/var/tmp', '/temp');


&WeblintTestInitialize();


&ExpectOK('simple syntactically correct html', '',
	  "<HTML>\n<HEAD><TITLE>test</TITLE></HEAD>\n".
	  "<BODY>this is the body</BODY>\n</HTML>");

&ExpectOK('paragraph usage', '',
	  "<HTML>\n<HEAD><TITLE>test</TITLE></HEAD>\n".
          "<BODY>first paragraph<P>second paragraph</BODY>\n</HTML>");

&ExpectOK('html which starts with DOCTYPE specifier', '',
	  "<!DOCTYPE HTML PUBLIC '-//W3O//DTD WWW HTML 2.0//EN'>\n".
	  "<HTML>\n<HEAD><TITLE>test</TITLE></HEAD>\n".
	  "<BODY>this is the body</BODY>\n</HTML>");

&ExpectOK('acceptable usage of META element', '',
	  '<HTML><HEAD><TITLE>foo</TITLE>'.
	  '<META NAME="IndexType" CONTENT="Service"></HEAD>'.
	  '<BODY>this is the body</BODY></HTML>');

&ExpectOK('correct use of information type and font style elements', '',
	  "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	  "<EM>Emphasized Text</EM>\n".
	  "<CITE>Cited Text</CITE>\n".
	  "<STRONG>Strongly emphasized Text</STRONG>\n".
	  "<CODE>Teletype Text</CODE>\n".
	  "<SAMP>sequence of literal characters</SAMP>\n".
	  "<KBD>Keyboarded Text</KBD>\n".
	  "<VAR>Variable name</VAR>\n".
	  "<DFN>Defining instance</DFN>\n".
	  "<Q>Short quotation</Q>\n".
	  "<LANG>alter language context</LANG>\n".
	  "<AU>Name of author</AU>\n".
	  "<PERSON>name of a person</PERSON>\n".
	  "<ACRONYM>acronym</ACRONYM>\n".
	  "<ABBREV>Abbreviation</ABBREV>\n".
	  "<INS>Inserted text</INS>\n".
	  "<DEL>Deleted text</DEL>\n".
	  "<B>Bold text</B>\n".
	  "<I>Italic text</I>\n".
	  "<TT>Teletype text</TT>\n".
	  "<U>Underlined text</U>\n".
	  "<S>Striked through text</S>\n".
	  "<BIG>Big text</BIG>\n".
	  "<SMALL>Small text</SMALL>\n".
	  "<SUB>Subscript text</SUB>\n".
	  "<SUP>Superscript text</SUP>\n".
	  '</BODY></HTML>');

&ExpectOK('IMG element with ALT and ISMAP attributes', '',
	  '<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>'.
	  '<IMG SRC=foo.gif ISMAP ALT="alt text">'.
	  '</BODY></HTML>');

&ExpectOK('newline within a tag', '',
	  '<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>'.
	  '<IMG SRC="foo.gif"'."\n".'ALT="alt text">'.
	  '</BODY></HTML>');

&ExpectOK('simple comment', '',
	  "<!-- comment before the HTML element -->\n".
	  "<HTML>\n".
	  "<!-- comment between the HTML and HEAD elements -->\n".
	  "<HEAD>\n".
	  "<!-- comment in the HEAD element -->\n".
	  "<TITLE>foo</TITLE></HEAD><BODY>".
	  "<!-- this is a simple comment in the body -->\n".
	  "this is the body\n".
	  "</BODY>\n".
	  "<!-- comment between end of BODY and end of HTML -->\n".
	  "</HTML>\n".
	  "<!-- comment after the end of the HTML element -->\n");

&ExpectOK('comment with space before the closing >', '',
	  '<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>'.
	  '<!-- this is a simple comment -- >'.
	  'this is the body'.
	  '</BODY></HTML>');

&ExpectOK('whitespace around the = of an element attribute', '',
	  "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>".
	  "<IMG SRC = foo.gif ALT=\"alt text\">".
	  "</BODY></HTML>");

&ExpectOK('legal unordered list', '',
	  "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	  "<UL>\n".
	  "<LI>first item\n".
	  "<LI>second item</LI>\n".
	  "</UL>\n".
	  "</BODY></HTML>\n");

&ExpectOK('legal definition list', '',
	  "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	  "<DL>\n".
	  "<DT>first tag<DD>first definition\n".
	  "<DT>second tag<DD>second definition\n".
	  "</DL>\n".
	  "</BODY></HTML>\n");

&ExpectOK('simple table', '',
	  '<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>'.
	  '<TABLE><TR><TH>height<TD>1.0<TR><TH>weight<TD>1.0</TABLE>'.
	  '</BODY></HTML>');

&ExpectWARN('table without TR', '',
	    "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	    "<TABLE><TH>height<TD>1.0<TR><TH>weight<TD>1.0</TABLE>".
	    "</BODY></HTML>",
	    2, 'required-context',
	    2, 'required-context');

&ExpectOK('simple figure with caption', '',
	  "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	  "<FIG SRC=\"nicodamus.jpeg\">\n".
          "<CAPTION>Ground dweller: <I>Nicodamus bicolor</I>\n".
	  "builds silk snares</CAPTION>\n".
	  "<P>A small hairy spider light fleshy red in color with a brown ".
	  "abdomen.\n<CREDIT>J. A. L. Cooke/OSF</CREDIT>\n".
	  "</FIG></BODY></HTML>");

&ExpectOK('simple math usage', '',
	  "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	  "<MATH>\n".
	  "<BOX>1+x<OVER>sin x</BOX>\n".
	  "<ABOVE>1+x</ABOVE>\n".
	  "<BELOW>1+x</BELOW>\n".
	  "<SQRT>1+x</SQRT>\n".
	  "<ROOT>3<OF>1+x</ROOT>\n".
	  "<ARRAY><ROW><ITEM>a<SUB>11</SUB><ITEM>a<SUB>12</SUB></ARRAY>\n".
	  "</MATH>\n".
	  "</BODY></HTML>\n");

&ExpectWARN('no HTML tags around document', '',
	    "<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>this is the body</BODY>\n",
	    1, 'html-outer',
	    1, 'must-follow');

&ExpectWARN('whitespace between opening < and tag name', '',
	    "<HTML><HEAD>< TITLE>title</TITLE></HEAD>\n".
	    "<BODY>this is the body</BODY></HTML>",
	    1, 'leading-whitespace');

&ExpectWARN('no TITLE element in HEAD', '',
	    "<HTML>\n<HEAD></HEAD>\n<BODY>this is the body</BODY>\n</HTML>",
	    2, 'empty-container',
	    2, 'require-head');

&ExpectWARN('unclosed TITLE in HEAD', '',
	    "<HTML>\n<HEAD><TITLE></HEAD>\n".
	    "<BODY>this is the body</BODY>\n</HTML>",
	    2, 'unclosed-element');

&ExpectWARN('bad style to use "here" as anchor text', '',
	    "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY><A HREF=\"foo.html\">here</A></BODY>\n</HTML>",
	    3, 'here-anchor');

&ExpectWARN('mis-matched heading tags <H1> .. </H2>', '',
	    "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY><H1>title</H2></BODY>\n</HTML>",
	    3, 'heading-mismatch');

&ExpectWARN('obsolete element', '',
	    "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY><XMP>foobar()</XMP></BODY></HTML>",
	    3, 'obsolete');

&ExpectWARN('illegal attribute in B element', '',
	    "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY><B FOO>foobar</B></BODY></HTML>",
	    3, 'unknown-attribute');

&ExpectWARN('empty tag: <>', '',
	    "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY><>this is the body</BODY></HTML>",
	    3, 'unknown-element');

&ExpectWARN('Netscape tags *without* Netscape extension enabled', '',
	    "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY BGCOLOR=\"#ffffff\">\n".
	    "<CENTER>centered text</CENTER>\n".
	    "<BLINK>blinking text</BLINK>\n".
	    "<FONT SIZE=+1>larger font size text</FONT>\n".
	    "</BODY></HTML>",
	    3, 'extension-attribute',	# BGCOLOR attribute for BODY
	    4, 'extension-markup',	# one for the opening tag of CENTER
	    4, 'extension-markup',	# one for the closing tag of CENTER
	    5, 'extension-markup',
	    5, 'extension-markup',
	    6, 'extension-markup',
	    6, 'attribute-format',	# hmm, checking tags of unknown elts?
	    6, 'extension-markup');

&ExpectOK('Netscape tags *with* Netscape extension enabled', '-x Netscape',
	    "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY BGCOLOR=\"#ffffff\">\n".
	    "<CENTER>centered text</CENTER>\n".
	    "<BLINK>blinking text</BLINK>\n".
	    "<FONT SIZE=+1>larger font size text</FONT>\n".
	    "</BODY></HTML>");

&ExpectWARN('not allowed to nest FORM elements', '',
	    "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<FORM METHOD=post ACTION=\"http://www.khoral.com/foo\">\n".
	    "<FORM METHOD=post ACTION=\"http://www.khoral.com/foo\">\n".
	    "This is inside the nested form".
	    "</FORM>\n".
	    "</FORM></BODY></HTML>",
	    5, 'nested-element');

&ExpectWARN('CAPTION element appearing outside of TABLE or FIG', '',
	    "<HTML><HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<TABLE><CAPTION>legal use of caption</CAPTION></TABLE>\n".
	    "<FIG><CAPTION>legal use of caption</CAPTION></FIG>\n".
	    "<CAPTION>this is an invalid use of caption</CAPTION>\n".
	    "</BODY></HTML>",
	    5, 'required-context');

&ExpectWARN('LH element must be used in UL, OL or DL', '',
	    "<HTML><HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<UL><LH>unordered list heading</LH></UL>\n".
	    "<OL><LH>ordered list heading</LH></OL>\n".
	    "<DL><LH>definition list heading</LH></DL>\n".
	    "<LH>illegal use of list heading</LH>\n".
	    "</BODY></HTML>",
	    6, 'required-context',
	    6, 'must-follow');

&ExpectWARN('LI element must be used in DIR, MENU, OL, OL or UL', '',
	    "<HTML><HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<DIR><LI>legal list item in DIR</DIR>\n".
	    "<MENU><LI>legal list item in MENU</MENU>\n".
	    "<OL><LI>legal list item in OL</OL>\n".
	    "<UL><LI>legal list item in UL</UL>\n".
	    "<LI>illegal list item\n".
	    "</BODY></HTML>",
	    7, 'required-context');

&ExpectWARN('unclosed comment', '',
	    "<HTML><HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<!-- this is an unclosed comment >\n".
	    "</BODY></HTML>",
	    3, 'unclosed-comment');

&ExpectWARN('use of physical font markup', '-e physical-font',
	    "<HTML><HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<B>This is bold text</B>\n".
	    "<STRONG>This is strong text</STRONG>\n".
	    "</BODY></HTML>",
	    3, 'physical-font');

&ExpectWARN('repeated attribute', '',
	    "<HTML><HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<IMG SRC=\"foo.gif\" SRC=\"foo.gif\" ALT=\"alt text\">\n".
	    "</BODY></HTML>",
	    3, 'repeated-attribute');

&ExpectWARN('no HTML tags around document, last thing is valid comment', '',
	    "<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>this is the body</BODY>\n".
	    "<!-- this is a valid comment -->\n",
	    1, 'html-outer',
	    1, 'must-follow');

&ExpectWARN('spurious text between HEAD and BODY elements', '',
	    "<HTML><HEAD><TITLE>title</TITLE></HEAD>\n".
	    "Should not put any text here!\n".
	    "<BODY>this is the body</BODY></HTML>\n",
	    3, 'must-follow');

&ExpectWARN('list heading appears after first list element', '',
	    "<HTML><HEAD><TITLE>title</TITLE></HEAD><BODY>\n".
	    "<UL>\n".
	    "<LI>text of first list item</LI>\n".
	    "<LH>this is the list heading</LH>\n".
	    "</UL>\n".
	    "</BODY></HTML>\n",
	    4, 'must-follow');

&ExpectWARN('empty title element', '',
	    "<HTML><HEAD><TITLE></TITLE></HEAD>\n".
	    "<BODY>this is the body</BODY></HTML>\n",
	    1, 'empty-container');

&ExpectWARN('empty list element', '',
	    "<HTML><HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<UL>\n".
	    "<LI>this is the first element\n".
	    "<LI>\n".
	    "<LI>this is the third or second element...\n".
	    "</UL>\n".
	    "</BODY></HTML>",
	    5, 'empty-container');

&ExpectWARN('attributes on closing tag', '',
	    "<HTML><HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<A NAME=\"foobar\">bleh</A NAME=\"foobar\">\n".
	    "</BODY></HTML>\n",
	    3, 'closing-attribute');

&ExpectWARN('use of Netscape attributes without Netscape extension', '',
	    "<HTML><HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY BGCOLOR=\"#fefefe\">\n".
	    "Nothing exciting in the body\n".
	    "</BODY></HTML>\n",
	    2, 'extension-attribute');

&ExpectWARN("use of ' as attribute value delimiter", '',
	  "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	  "<IMG SRC = foo.gif ALT='alt text'>\n".
	  "</BODY></HTML>\n",
	  2, 'attribute-delimiter');

&ExpectWARN("IMG without HEIGHT and WIDTH attributes", '-e img-size',
	  "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	  "<IMG SRC = foo.gif ALT=\"alt text\">\n".
	  "</BODY></HTML>\n",
	  2, 'img-size');

&ExpectOK('non-empty container, with comment last thing', '',
	    "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<PRE>\n".
	    "Some text ...\n".
	    "<!-- last thing in container is a valid comment -->\n".
	    "</PRE>\n".
	    "</BODY></HTML>");

&ExpectWARN('use of -pedantic command-line switch', '-pedantic',
	  "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	  "<IMG SRC = foo.gif ALT=\"alt text\">\n".
	  "<B>This is bold text -- should use the STRONG element</B>\n".
	  "<A HREF=\"foobar.html\">non-existent file</A>\n".
	  "</BODY></HTML>\n",
	  1, 'mailto-link',
	  2, 'img-size',
	  3, 'physical-font');

&ExpectWARN('leading whitespace in container', '-e container-whitespace',
	  "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	  "<A HREF=foobar.html> hello</A>\n".
	  "</BODY></HTML>\n",
	  2, 'container-whitespace');

&ExpectOK('valid Java applet', '-x Java',
	    "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<APPLET CODEBASE=\"http://java.sun.com/JDK-prebeta1/applets/NervousText\" CODE=\"NervousText.class\" WIDTH=400 HEIGHT=75 ALIGN=CENTER>\n".
	    "<PARAM NAME=\"text\" VALUE=\"This is the applet viewer.\">\n".
	    "<BLOCKQUOTE>\n".
	    "If you were using a Java-enabled browser, ".
	    "you wouldn't see this!\n".
	    "</BLOCKQUOTE>\n".
	    "</APPLET>\n".
	    "</BODY></HTML>");

&ExpectWARN('PARAM can only appear in an APPLET element', '-x Java',
	    "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	    "<PARAM NAME=\"text\" VALUE=\"This is the applet viewer.\">\n".
	    "</BODY></HTML>\n",
	    2, 'required-context');

&ExpectOK('valid use of Netscape 2 markup', '-x Netscape',
	  "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	  "<BODY>\n".
	  "<BIG>this is big text</BIG>\n".
	  "<SMALL>this is small text</SMALL>\n".
	  "<SUB>this is subscript text</SUB>\n".
	  "<SUP>this is superscript text</SUP>\n".
	  "<MAP NAME=\"map1\">\n".
	  "<AREA SHAPE=\"RECT\" COORDS=\"10,10,20,20\" HREF=\"foo.html\">\n".
	  "<AREA SHAPE=\"RECT\" COORDS=\"40,40,50,50\" NOHREF>\n".
	  "</MAP>\n".
	  "<IMG SRC=\"pic.gif\" ALT=map USEMAP=\"#map1\">\n".
	  "<FORM ENCTYPE=\"multipart/form-data\" ACTION=\"_URL_\" METHOD=POST>\n".
	  "<INPUT TYPE=submit VALUE=\"Send File\">\n".
	  "</FORM>\n".
	  "</BODY></HTML>");

&ExpectWARN('AREA can only appear in a MAP, MAP must have a NAME', '-x Netscape',
	    "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	    "<AREA SHAPE=\"RECT\" COORDS=\"10,10,20,20\" HREF=\"foo.html\">\n".
	    "<MAP>\n".
	    "<AREA SHAPE=\"RECT\" COORDS=\"40,40,50,50\" NOHREF>\n".
	    "</MAP>\n".
	    "</BODY></HTML>\n",
	    2, 'required-context',
	    3, 'required-attribute');

&ExpectOK('non-empty list element, with comment last thing', '',
	  "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	  "<BODY>\n".
	  "<UL>\n".
	  "<LI>line 9\n".
	  "<!-- line 10 -->\n".
	  "<LI>line 11\n".
	  "</UL>\n".
	  "</BODY></HTML>");

&ExpectWARN('Enabling Java extension should not enable Netscape', '-x Java',
	    "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY BGCOLOR=\"#ffffff\">\n".
	    "Blah blah\n".
	    "</BODY></HTML>\n",
	    1, 'extension-attribute');

&ExpectWARN("html which doesn't start with DOCTYPE", '-e require-doctype',
	    "<HTML>\n<HEAD><TITLE>test</TITLE></HEAD>\n".
	    "<BODY>this is the body</BODY>\n</HTML>",
	    1, 'require-doctype');

&ExpectOK('html which starts with DOCTYPE', '-e require-doctype',
	  "<!DOCTYPE HTML PUBLIC '-//W3O//DTD WWW HTML 2.0//EN'>\n".
	  "<HTML>\n<HEAD><TITLE>test</TITLE></HEAD>\n".
	  "<BODY>this is the body</BODY>\n</HTML>");

&ExpectWARN('should use &gt; in place of >', '',
	    "<HTML>\n<HEAD><TITLE>test</TITLE></HEAD>\n".
	    "<BODY>text with > instead of &gt;</BODY>\n</HTML>",
	    3, 'literal-metacharacter');

&ExpectOK('IMG element with LOWSRC attribute', '-x Netscape',
	  "<HTML>\n<HEAD><TITLE>test</TITLE></HEAD>\n".
	  "<BODY>\n".
	  "<IMG SRC=\"foo.gif\" LOWSRC=\"lowfoo.gif\" ALT=\"alt text\">".
	  "</BODY>\n</HTML>");

&ExpectOK('Java applet and also using Netscape extensions', '-x Netscape,Java',
	    "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	    "<BODY BACKGROUND=\"background.gif\">\n".
	    "<APPLET CODEBASE=\"http://java.sun.com/JDK-prebeta1/applets/NervousText\" CODE=\"NervousText.class\" WIDTH=400 HEIGHT=75 ALIGN=CENTER>\n".
	    "<PARAM NAME=\"text\" VALUE=\"This is the applet viewer.\">\n".
	    "<BLOCKQUOTE>\n".
	    "If you were using a Java-enabled browser, ".
	    "you wouldn't see this!\n".
	    "</BLOCKQUOTE>\n".
	    "</APPLET>\n".
	    "</BODY></HTML>");

&ExpectWARN('text appearing in unexpected context', '',
	    "<HTML>\n".
	    "<HEAD>\n".
	    "Having text here is not legal!\n".
	    "<TITLE>test</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<UL>\n".
	    "Having text here is not legal!\n".
	    "</UL>\n".
	    "<OL>\n".
	    "Having text here is not legal!\n".
	    "</OL>\n".
	    "<DL>\n".
	    "Having text here is not legal!\n".
	    "</DL>\n".
	    "<TABLE>\n".
	    "Having text here is not legal!\n".
	    "<TR>\n".
	    "Having text here is not legal!\n".
	    "<TD>This is ok</TD>\n".
	    "</TR>\n".
	    "</TABLE>\n".
	    "</BODY></HTML>\n",
	    4, 'bad-text-context',
	    8, 'bad-text-context',
	    11, 'bad-text-context',
	    14, 'bad-text-context',
	    17, 'bad-text-context',
	    19, 'bad-text-context');

&ExpectWARN('IMG element with illegal value for ALIGN attribute', '',
	    "<HTML><HEAD><TITLE>foo</TITLE></HEAD><BODY>\n".
	    "<IMG SRC=foo.gif ALIGN=MODDLE ALT=\"alt text=\">\n".
	    "</BODY></HTML>",
	    2, 'attribute-format');

&ExpectOK('new Netscape markup', '-x Netscape',
	  "<HTML>\n<HEAD><TITLE>test</TITLE></HEAD>\n".
	  "<BODY>\n".
	  "To <A HREF=\"foo.html\" TARGET=\"myWindow\">open a window</A>\n".
	  "<FONT COLOR=\"#00ff00\">blue text</FONT>\n".
	  "<FORM ACTION=\"foo.html\" METHOD=POST>\n".
	  "<TEXTAREA NAME=foo ROWS=24 COLS=24 WRAP=PHYSICAL>\n".
	  "hello</TEXTAREA>\n".
	  "</FORM>\n".
	  "</BODY>\n</HTML>");

&ExpectOK('valid FRAMESET example with FRAMES', '-x Netscape',
	  "<HTML>\n<HEAD><TITLE>test</TITLE></HEAD>\n".
	  "<FRAMESET>\n".
	  "<FRAME SRC=\"cell.html\">\n".
	  "<FRAME SRC=\"cell.html\">\n".
	  "</FRAMESET>\n".
	  "</HTML>");

&ExpectWARN('FRAME outside of FRAMESET is illegal', '-x Netscape',
	    "<HTML>\n".
	    "<HEAD><TITLE>test</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<FRAME SRC=\"cell.html\">\n".
	    "</BODY>\n".
	    "</HTML>",
	    4, 'required-context');

&ExpectOK('A valid JavaScript example', '-x Netscape',
	  "<HTML>\n<HEAD><TITLE>test</TITLE>\n".
	  "<SCRIPT LANGUAGE=\"JavaScript\">\n".
	  "document.write(\"Hello net.\")\n".
	  "</SCRIPT>\n".
	  "</HEAD>\n".
	  "<BODY>\n".
	  "That's all, folks.\n".
	  "</BODY>\n".
	  "</HTML>");

&ExpectOK('FORM element with SELECT element which has SIZE attribute', '',
	  "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	  "<BODY>\n".
	  "<FORM METHOD=post ACTION=\"http://www.khoral.com/foo\">\n".
	  "<SELECT NAME=\"foobar\" SIZE=\"50,8\">\n".
	  "<OPTION>foobar\n".
	  "</SELECT>\n".
	  "</FORM></BODY></HTML>");

&ExpectOK('HR element can have percentage width in Netscape', '-x Netscape',
	  "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	  "<BODY>\n".
	  "<HR WIDTH=\"50%\">\n".
	  "</BODY></HTML>");

&ExpectOK('Legal use of Netscape-specific table attributes', '-x Netscape',
	  "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	  "<BODY>\n".
	  "<TABLE BORDER=2 CELLPADDING=2 CELLSPACING=2>\n".
	  "<TR><TH WIDTH=\"10%\">Hello<TD WIDTH=2>World</TR>\n".
	  "</TABLE>\n".
	  "</BODY></HTML>");

&ExpectOK('Ok to have empty TD elements in a table', '',
	  "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	  "<BODY>\n".
	  "<TABLE>\n".
	  "<TR><TD></TD></TR>\n".
	  "</TABLE>\n".
	  "</BODY></HTML>");

&ExpectOK('ordered lists of different TYPES', '-x Netscape',
	  "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	  "<BODY>\n".
	  "<OL>\n".
	  "<LI>Basic ordered list item\n".
	  "</OL>\n".
	  "<OL TYPE=1>\n".
	  "<LI>Basic ordered list item (same as default)\n".
	  "</OL>\n".
	  "<OL TYPE=a>\n".
	  "<LI>Basic ordered list item\n".
	  "</OL>\n".
	  "<OL TYPE=A>\n".
	  "<LI>Basic ordered list item\n".
	  "</OL>\n".
	  "<OL TYPE=i>\n".
	  "<LI>Basic ordered list item\n".
	  "</OL>\n".
	  "<OL TYPE=I>\n".
	  "<LI>Basic ordered list item\n".
	  "</OL>\n".
	  "</BODY></HTML>");

&ExpectOK('valid use of Microsoft specific markup', '-x Microsoft',
	  "<HTML>\n<HEAD><TITLE>title</TITLE>\n".
	  "<BGSOUND SRC=\"tune.wav\" LOOP=5>\n".
	  "</HEAD>\n".
	  "<BODY TOPMARGIN=2 LEFTMARGIN=2>\n".
	  "<TABLE CELLPADDING=2 CELLSPACING=2>\n".
	  "<CAPTION ALIGN=CENTER VALIGN=BOTTOM>Hello</CAPTION>\n".
	  "<TR><TD></TD></TR>\n".
	  "</TABLE>\n".
	  "<FONT COLOR=RED FACE=\"Lucida\" SIZE=3>Red lucida text</FONT>\n".
	  "<MARQUEE BGCOLOR=#FFFFBB DIRECTION=RIGHT BEHAVIOR=SCROLL\n".
	  "SCROLLAMOUNT=10 SCROLLDELAY=200 WIDTH=\"50%\" HEIGHT=\"50%\"".
	  "><FONT COLOR=\"WHITE\"\n".
	  ">This is a scrolling marquee.</FONT></MARQUEE>\n".
	  "</BODY></HTML>");

&ExpectOK('more valid use of Microsoft specific markup', '-x Microsoft',
	  "<HTML>\n<HEAD><TITLE>title</TITLE>\n".
	  "</HEAD>\n".
	  "<BODY ALINK=red VLINK=blue LINK=green>\n".
	  "Hello\n".
	  "<MARQUEE WIDTH=200 HEIGHT=200>Hello</MARQUEE>\n".
	  "</BODY></HTML>");

&ExpectWARN('Use of Microsoft markup without Microsoft extension', '',
	    "<HTML>\n".
	    "<HEAD><TITLE>test</TITLE></HEAD>\n".
	    "<BODY TOPMARGIN=2 LEFTMARGIN=2>\n".
	    "<FONT COLOR=RED FACE=\"Lucida\" SIZE=3>Red lucida text</FONT>\n".
	    "</BODY>\n".
	    "</HTML>",
	    3, 'extension-attribute',
	    3, 'extension-attribute',
	    4, 'extension-markup',
	    4, 'extension-markup');

&ExpectOK('Valid use of attributes on font markup', '',
	  "<HTML>\n<HEAD><TITLE>title</TITLE></HEAD>\n".
	  "<BODY>\n".
	  "<I CLASS=TREE>Oak</I>\n".
	  "<STRONG CLASS=URGENT>Urgent Text</STRONG>\n".
	  "</BODY></HTML>");

&ExpectOK('valid FRAMESET with ROWS and COLS attributes', '-x Netscape',
	  "<HTML>\n<HEAD><TITLE>test</TITLE></HEAD>\n".
	  "<FRAMESET ROWS=\"20%,60%,20%\" COLS=\"*,2*\">\n".
	  "<FRAME SRC=\"cell.html\">\n".
	  "<FRAME SRC=\"cell.html\">\n".
	  "<FRAME SRC=\"cell.html\">\n".
	  "<FRAME SRC=\"cell.html\">\n".
	  "<FRAME SRC=\"cell.html\">\n".
	  "<FRAME SRC=\"cell.html\">\n".
	  "</FRAMESET>\n".
	  "</HTML>");

&ExpectOK('BASE element with only TARGET attribute (Netscape)', '-x Netscape',
	  "<HTML>\n".
	  "<HEAD>\n".
	  "<BASE TARGET=\"banana\">\n".
	  "<TITLE>test</TITLE>\n".
	  "</HEAD>\n".
	  "<BODY>this is the body</BODY>\n</HTML>");

&ExpectWARN('use of FONT element with no attributes', '-x Netscape',
	    "<HTML>\n".
	    "<HEAD>\n".
	    "<TITLE>test</TITLE>\n".
	    "</HEAD>\n".
	    "<BODY>\n".
	    "this is the <FONT>body</FONT>\n".
	    "</BODY>\n</HTML>",
	    6, 'expected-attribute');

&ExpectOK('Netscape table with percentage WIDTH', '-x Netscape',
	  "<HTML>\n".
	  "<HEAD>\n".
	  "<TITLE>test</TITLE>\n".
	  "</HEAD>\n".
	  "<BODY>\n".
	  "<TABLE BORDER = 5 CELLPADDING=5 CELLSPACING=5 WIDTH=\"100%\">\n".
	  "<TR><TD>Hello</TD></TR>\n".
	  "</TABLE>\n".
	  "</BODY>\n</HTML>");

&ExpectOK('Netscape list with different TYPE bullets', '-x Netscape',
	  "<HTML>\n".
	  "<HEAD>\n".
	  "<TITLE>test</TITLE>\n".
	  "</HEAD>\n".
	  "<BODY>\n".
	  "<UL TYPE=\"disc\">\n".
	  "<LI>First item\n".
	  "<LI TYPE=\"circle\">circle bullet\n".
	  "<LI TYPE=\"square\">square bullet\n".
	  "</UL>\n".
	  "</BODY>\n</HTML>");

&ExpectWARN('correct and incorrect values for CLEAR attribute', '',
	    "<HTML>\n".
	    "<HEAD><TITLE>test</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "ok left<BR CLEAR=LEFT>\n".
	    "ok right<BR CLEAR=RIGHT>\n".
	    "ok all<BR CLEAR=ALL>\n".
	    "not ok<BR CLEAR=RIHGT>\n".
	    "</BODY>\n</HTML>",
	    7, 'attribute-format');

&ExpectWARN('leading whitespace in list item', '-e container-whitespace',
	    "<HTML>\n".
	    "<HEAD><TITLE>test</TITLE></HEAD>\n".
	    "<BODY>\n".
	    "<UL>\n".
	    "<LI>First item\n".
	    "<LI> Second item\n".
	    "<LI>Third item\n".
	    "</UL>\n".
	    "</BODY>\n</HTML>",
	    6, 'container-whitespace');

&ExpectWARN('illegal color attribute values', '-x Netscape',
	    "<HTML>\n".
	    "<HEAD><TITLE>test</TITLE></HEAD>\n".
	    "<BODY ALINK=\"#ffaaff\" VLINK=\"#ggaagg\">\n".
	    "This is the body of the page\n".
	    "</BODY>\n</HTML>",
	    3, 'attribute-format');

&ExpectOK('Valid use of the Microsoft color attributes', '-x Microsoft',
	  "<HTML>\n".
	  "<HEAD>\n".
	  "<TITLE>test</TITLE>\n".
	  "</HEAD>\n".
	  "<BODY TEXT=black BGCOLOR=yellow LINK=Blue ALINK=red VLINK=green>\n".
	  "<FONT COLOR=\"#ff0000\">red text</FONT>\n".
	  "<TABLE BORDER BORDERCOLOR=teal BORDERCOLORLIGHT=Fuchsia ".
	  "	BORDERCOLORDARK=Gray>\n".
	  "<TR><TH>Bleh</TH></TR>\n".
	  "</TABLE>\n".
	  "</BODY>\n</HTML>");


&WeblintTestEnd();


#========================================================================
# Function:	ExpectOK
# Purpose:	This is the high-level interface to the checker.  It takes
#		a file and checks for fluff.
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
   $WORKDIR  = "$TMPDIR/weblint-test.$$";
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
# Function:	WeblintTestEnd()
# Purpose:	Generate summary in logfile, close logfile, then
#		clean up working files and directory.
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
