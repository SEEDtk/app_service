use Test::Simple tests => 4;

use Bio::KBase::AppService::UploadSpec;
use Getopt::Long;
use P3AuthToken;
use Cwd;

print "Current directory is " . getcwd() . "\n";

@ARGV = qw(--workspace-path-prefix /rastuser25@patricbrc.org/home/Experiments
        --workspace-upload-path Testing
        --overwrite
        fake.fa
        ws:1623.25.fa
        ws:/Vparrello@patricbrc.org/FIGCoreProjects/AlzheimersProject/AlzheimersControls/Binning/.SRS015264/.bin.1.820/GenomeReport.html);
my $token = P3AuthToken->new();
my $uploader = Bio::KBase::AppService::UploadSpec->new($token);
GetOptions($uploader->file_options());
my $file1 = $uploader->fix_file_name($ARGV[0]);
ok($file1 eq '/rastuser25@patricbrc.org/home/Experiments/Testing/fake.fa');
my $file2 = $uploader->fix_file_name($ARGV[1]);
ok($file2 eq '/rastuser25@patricbrc.org/home/Experiments/1623.25.fa');
my $file3 = $uploader->fix_file_name($ARGV[2]);
ok($file3 eq '/Vparrello@patricbrc.org/FIGCoreProjects/AlzheimersProject/AlzheimersControls/Binning/.SRS015264/.bin.1.820/GenomeReport.html');
$uploader->process_uploads();
# Here it's enough that we didn't die.
ok(1);

