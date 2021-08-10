use Test::Simple tests => 6;
use Bio::KBase::AppService::GenomeIdSpec;

my @bad_ids = ("1234.A", "83333.1", "83333.2", "A3333.2");
my @good_ids =
my $gList = Bio::KBase::AppService::GenomeIdSpec::validate_genomes("123.4,83333.1,83333.2,A3333.2");
ok(! defined($gList));
$gList = Bio::KBase::AppService::GenomeIdSpec::validate_genomes("556262.10");
ok(scalar(@$gList) == 1 && $gList->[0] eq "556262.10");
$gList = Bio::KBase::AppService::GenomeIdSpec::validate_genomes("556262.10,83333.1,83333.390");
ok(! defined $gList);
$gList = Bio::KBase::AppService::GenomeIdSpec::validate_genomes("556262.10,83333.390");
ok(scalar(@$gList) == 2 && $gList->[0] eq "556262.10" && $gList->[1] eq "83333.390");
$gList = Bio::KBase::AppService::GenomeIdSpec::validate_genomes("genomeIds.tbl");
ok(scalar(@$gList) == 3 && $gList->[0] eq "556262.10" && $gList->[1] eq "83333.390" && $gList->[2] eq "289376.4");
$gList = Bio::KBase::AppService::GenomeIdSpec::validate_genomes();
ok(! $gList);
