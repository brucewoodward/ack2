#!perl

use warnings;
use strict;

use Test::More tests => 35;

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


# -i no longer applies to regex given by -g
NOT_CASE_INSENSITIVE: {
    my @expected = qw();
    my $regex = 'PIPE';

    my @files = qw( . );
    my @args = ( '-i', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for -i -g $regex " );
}


# ... but can be emulated with (?i:regex)
CASE_INSENSITIVE: {
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
    # -Q does nothing for -g regex
    my @expected = qw(
        t/ack-g.t
    );
    my $regex = 'ack-g.t$';

    my @files = qw( t );
    my @args = ( '-Q', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex with quotemeta." );
}

WORDS_FILE_NOT: {
    # -w does nothing for -g regex
    my @expected = qw(
        t/text/freedom-of-choice.txt
    );
    my $regex = 'free';

    my @files = qw( t/text/ );
    my @args = ( '-w', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex with '-w'." );
}

INVERT_MATCH_FILE_NOT: {
    # -v does nothing for -g regex
    my @expected = qw(
        t/text/4th-of-july.txt
        t/text/freedom-of-choice.txt
        t/text/science-of-myth.txt
    );
    my $regex = 'of';

    my @files = qw( t/text/ );
    my @args = ( '-v', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for filenames NOT matching $regex." );
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

G_WITH_REGEX: {
    # specifying both -g and a regex should result in an error
    my @files = qw( t/text );
    my @args = qw( -g boy --match Sue );

    my ($stdout, $stderr) = run_ack_with_stderr( @args, @files );
    isnt( get_rc(), 0, 'Specifying both -g and --match must lead to an error RC' );
    is( scalar @{$stdout}, 0, 'No normal output' );
    is( scalar @{$stderr}, 1, 'One line of stderr output' );
    like( $stderr->[0], qr/\Q(Sue)/, 'Error message must contain "(Sue)"' );
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
