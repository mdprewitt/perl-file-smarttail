use strict;
use Test::More 'no_plan';
use FindBin qw( $Bin );

use_ok('File::SmartTail');
use_ok('File::SmartTail::Logger');

my $testfile = "simple.data";

END {
    unlink $testfile;
    ok( !-f $testfile, "Test file removed" );
}

open( TST, ">$testfile" ) || die "Unable to open $testfile [$!]";
print TST "Line 1\nLine 2\nLine 3\n";
close(TST);

my $bindir = "$Bin/../";
my $tail = new File::SmartTail( -bindir => $bindir, );
my $host = `hostname`;
chomp($host);

foreach my $ssh (qw( rsh ssh )) {
  SKIP:
    {
        diag("Testing to see if $ssh is enabled on $host");
        skip "$ssh is disabled on $host" if system("$ssh $host ls > /dev/null") != 0;
        $tail->WatchFile(
            -file            => $testfile,
            -request_timeout => 1,
            -reset           => 1,
            -type            => "UNIX-REMOTE",
            -rmtsh           => $ssh,
            -host            => $host
          )
          || next;
        my $i = 1;
        while ( my $line = $tail->GetLine() ) {
            my ( $host, $file, $content ) = split( /:/, $line );
            last if $content =~ /^_timeout_/;
            chomp($content);
            ok( $content eq "Line $i", "Line Matches" );
            $i++;
        }
    }
}
