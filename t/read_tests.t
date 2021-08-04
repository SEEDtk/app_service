use Test::Simple tests => 15;
use Bio::KBase::AppService::ReadSpec;
use Bio::KBase::AppService::CommonSpec;
use Bio::KBase::AppService::UploadSpec;
use Getopt::Long;
use P3AuthToken;
use Cwd;


print "Current directory is " . getcwd() . "\n";
my $token = P3AuthToken->new();
my $uploader = Bio::KBase::AppService::UploadSpec->new($token);
my $reader = Bio::KBase::AppService::ReadSpec->new($uploader);
my $commoner = Bio::KBase::AppService::CommonSpec->new();

@ARGV = qw(--workspace-path-prefix /rastuser25@patricbrc.org/home/Experiments
        --workspace-upload-path Testing
        --overwrite
        --insert-size-mean 110
        --platform illumina
        --paired-end-lib left.fq right.fq
        --platform pacbio
        --interleaved-lib inter.fq
        --read-orientation-outward
        --single-end-lib out1.fq
        --srr-id SRR1000 --srr-id SRR2000
    );
my ($opt, $usage) = GetOptions($reader->lib_options(), $commoner->options());
my $params = {};
$reader->store_libs($params);
my $paired = $params->{paired_end_libs};
ok(scalar @$paired == 2);
ok($paired->[0]{insert_size_mean} == 110);
ok(! $paired->[0]{read_orientation_outward});
ok(! $paired->[0]{interleaved});
ok($paired->[0]{platform} eq 'illumina');
ok($paired->[0]{read1} eq "/rastuser25\@patricbrc.org/home/Experiments/Testing/left.fq");
ok($paired->[0]{read2} eq "/rastuser25\@patricbrc.org/home/Experiments/Testing/right.fq");
ok($paired->[1]{interleaved});
ok($paired->[1]{read1} eq "/rastuser25\@patricbrc.org/home/Experiments/Testing/inter.fq");
my $single = $params->{single_end_libs};
ok(scalar @$single == 1);
ok($single->[0]{platform} eq 'pacbio');
ok($single->[0]{read} eq "/rastuser25\@patricbrc.org/home/Experiments/Testing/out1.fq");
my $srr = $params->{srr_ids};
ok(scalar @$srr == 2);
ok($srr->[0] eq 'SRR1000');
ok($srr->[1] eq 'SRR2000');
