# $Id: Makefile.PL,v 1.4 2002/12/12 19:56:59 comdog Exp $
use ExtUtils::MakeMaker;

sub ExtUtils::MM_Any::test_via_harness
	{
    my($self, $perl, $tests) = @_;

    return qq|\t$perl "-MTest::Manifest" | .
           qq|"-e" "run_t_manifest(\$(TEST_VERBOSE), '\$(INST_LIB)', | .
           qq|'\$(INST_ARCHLIB)')"\n|;
	}

WriteMakefile(
    'NAME'		    => 'weblint++',
	'VERSION'       => '1.14',
	
	'EXE_FILES' =>  [ 'weblint++' ],
	    	
	'PREREQ_PM' => {
		'ConfigReader::Simple'   	=> '1.15',
		'Data::Dumper'	            => '0',
		'Digest::MD5'	            => '0',
		'File::Find::Rule'          => '0',
		'HTML::Lint'	            => '0',
		'HTML::SimpleLinkExtor'	    => '0',
		'HTTP::Request'             => '0',
		'HTTP::SimpleLinkChecker'	=> '0',
		'HTTP::Size'	            => '0.4',
		'Mail::Sendmail'	        => '0',
		'Test::Manifest'            => '0.91',
		'Test::More'                => '0',
		'Test::Pod'                 => '0.90',
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
