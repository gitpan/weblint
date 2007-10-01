# $Id: Makefile.PL 2318 2007-10-01 20:31:32Z comdog $
use ExtUtils::MakeMaker;


eval "use Test::Manifest 1.14";

WriteMakefile(
    'NAME'		    => 'weblint++',
	'VERSION'       => '1.15',
	'LICENSE'		=> 'perl',
	'AUTHOR'		=> 'brian d foy <bdfoy@cpan.org>',
	
	'EXE_FILES' =>  [ 'weblint++' ],
	    	
	'PREREQ_PM' => {
		'ConfigReader::Simple'   	=> '1.15',
		'Data::Dumper'	            => '0',
		'Digest::MD5'	            => '0',
		'HTML::Lint'	            => '0',
		'HTML::SimpleLinkExtor'	    => '0',
		'HTTP::Request'             => '0',
		'HTTP::SimpleLinkChecker'	=> '0',
		'HTTP::Size'	            => '0.4',
		'Mail::Sendmail'	        => '0',
		'Test::File'                => '0',
		'Test::More'                => '0',
		'Text::Diff'	            => '0',
		'Text::Template'	        => '0',
		'Time::HiRes'	            => '0',
		'URI'	                    => '0',
		},

	'MAN1PODS' => {
		'weblint++' => '$(INST_MAN1DIR)/weblint++.1',
		},
		
	clean => { FILES => '*.bak weblint++-*' },
	);
