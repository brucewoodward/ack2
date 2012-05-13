#!perl

use warnings;
use strict;

use Test::More tests => 29;

use lib 't';
use Util;

prep_environment();

NO_STARTDIR: {
    my $regex = 'non';

    my @files = qw( t/foo/non-existent );
    my @args = ( '-g', $regex );
    my ($stdout, $stderr) = run_ack_with_stderr( @args, @files );

    is( scalar @{$stdout}, 0, 'No STDOUT for non-existent file' );
    is( scalar @{$stderr}, 1, 'One line of STDERR for non-existent file' );
    like( $stderr->[0], qr/non-existent: No such file or directory/,
        'Correct warning message for non-existent file' );
}


NO_METACHARCTERS: {
    my @expected = qw(
        t/swamp/Makefile
        t/swamp/Makefile.PL
        t/swamp/notaMakefile
    );
    my $regex = 'Makefile';

    my @files = qw( t/ );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


METACHARACTERS: {
    my @expected = qw(
        t/swamp/html.htm
        t/swamp/html.html
    );
    my $regex = 'swam.......htm';

    my @files = qw( t/ );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


FRONT_ANCHOR: {
    my @expected = qw(
        t/filter.t
    );
    my $regex = '^t.fil';

    my @files = qw( t );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


BACK_ANCHOR: {
    my @expected = qw(
        t/swamp/options.pl
        t/swamp/perl.pl
    );
    my $regex = 'pl$';

    my @files = qw( t );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


CASE_INSENSITIVE_DASH_I: {
    my @expected = qw(
        t/swamp/pipe-stress-freaks.F
    );
    my $regex = 'PIPE';

    my @files = qw( . );
    my @args = ( '-i', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for -i -g $regex " );
}


# Can also be emulated with (?i:regex)
CASE_INSENSITIVE_IN_REGEX: {
    my @expected = qw(
        t/swamp/pipe-stress-freaks.F
    );
    my $regex = '(?i:PIPE)';

    my @files = qw( . );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}

FILE_ON_COMMAND_LINE_IS_ALWAYS_SEARCHED: {
    my @expected = ( 't/swamp/#emacs-workfile.pl#' );
    my $regex = 'emacs';

    my @files = ( 't/swamp/#emacs-workfile.pl#' );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'File on command line is always searched' );
}

FILE_ON_COMMAND_LINE_IS_ALWAYS_SEARCHED_EVEN_WITH_WRONG_TYPE: {
    my @expected = qw(
        t/swamp/parrot.pir
    );
    my $regex = 'parrot';

    my @files = qw( t/swamp/parrot.pir );
    my @args = ( '--html', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'File on command line is always searched, even with wrong type.' );
}


QUOTEMETA_FILE_NOT: {
    # -Q works on -g regex
    my @expected = qw(
    );
    my $regex = 'ack-g.t$';

    my @files = qw( t );
    my @args = ( '-Q', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex with quotemeta." );
}

WORDS_FILE_NOT: {
    # -w works on -g
    my @expected = qw();
    my $regex = 'free';

    my @files = qw( t/text/ );
    my @args = ( '-w', '-g', $regex ); # The -w means "free" won't match "freedom"
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex with '-w'." );
}

INVERT_FILE_MATCH: {
    my @expected = qw(
        t/text/boy-named-sue.txt
        t/text/me-and-bobbie-mcgee.txt
        t/text/shut-up-be-happy.txt
    );
    my $file_regex = 'of';

    my @files = qw( t/text/ );
    my @args = ( '-v', '-g', $file_regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for file names that do not match $file_regex" );
}

F_WITH_REGEX: {
    # specifying both -f and a regex should result in an error
    my @files = qw( t/text );
    my @args = qw( -f --match Sue );

    my ($stdout, $stderr) = run_ack_with_stderr( @args, @files );
    isnt( get_rc(), 0, 'Specifying both -f and --match must lead to an error RC' );
    is( scalar @{$stdout}, 0, 'No normal output' );
    is( scalar @{$stderr}, 1, 'One line of stderr output' );
    like( $stderr->[0], qr/\Q(Sue)/, 'Error message must contain "(Sue)"' );
}
