use strict;
use warnings;
use lib 't';

use Test::More;

plan skip_all => q{Windows doesn't have named pipes} if $^O =~ /MSWin32/;

use Util;
use POSIX ();

my @expected = (
    'THIS IS ALL IN UPPER CASE',
    'this is a word here',
);

prep_environment();

plan tests => 1;

my $pipename = POSIX::tmpnam();
POSIX::mkfifo $pipename, 0666;

my $pid = fork();
if ( $pid == 0 ) {
    open my $fifo, '>', $pipename or die "Couldn't create named pipe $pipename: $!";
    open my $f, '<', 't/swamp/options.pl' or die "Couldn't open t/swamp/options.pl: $!";
    while (my $line = <$f>) {
        print {$fifo} $line;
    }
    close $f;
    close $fifo;
    exit 0;
}

my ( $read, $write );

pipe( $read, $write );

$pid = fork();

my @output;

if ( $pid ) {
    close $write;
    while(<$read>) {
        chomp;
        push @output, $_;
    }
    waitpid $pid, 0;
}
else {
    close $read;
    open STDOUT, '>&', $write;
    open STDERR, '>&', $write;

    my @args = ($^X, '-Mblib', build_ack_invocation( qw( --noenv --nocolor --smart-case this ) ), $pipename );
    exec @args;
}

unlink $pipename;

lists_match( \@output, \@expected );
done_testing();
