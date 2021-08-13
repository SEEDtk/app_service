=head1 Submit an RNA Seq Processing Job

This script submits an RNA Seq processing job to PATRIC.  It allows input from all supported read libraries, and specifies
the tool to use as well as any conditions or contrasts that we want to appear on the output.

=head1 Usage Synopsis

    p3-submit-fastqutils [options] output-path output-name

Start a FASTQ processing job specified workspace path, using the specified name for the output job folder.

=head2 Command-Line Options

=over 4

=item --paired-end-lib

Two paired-end libraries containing reads.  These are coded with a single invocation, e.g. C<--paired-end-libs left.fa right.fa>.  The
libraries must be paired FASTQ files.  A prefix of C<ws:> indicates a file is in the PATRIC workspace; otherwise they are uploaded
from the local file system.  This parameter may be specified multiple times.

=item --interleaved-lib

A single library of paired-end reads in interleaved format.  This must be a FASTQ file with paired reads mixed together, the forward read
always preceding the reverse read.  A prefix of C<ws:> indicates a file is in the PATRIC workspace; otherwise they are uploaded
from the local file system.  This parameter may be specified multiple times.

=item --single-end-lib

A library of single reads.  This must be a FASTQ file.  A prefix of C<ws:> indicates a file is in the PATRIC workspace; otherwise they are
uploaded from the local file system.  This parameter may be specified multiple times.

=item --srr-id

A run ID from the NCBI sequence read archive.  The run will be downloaded from the NCBI for processing.  This parameter may be specified
multiple times.

=item --condition

Experimental condition to use for labelling subsequent read libraries on the command line.  Can be any string.

=item --contrast

Contrast name to be used for labelling the run.  This parameter can be specified multiple times.

=item --tuxedo

Use the Tuxedo suite of RNA tools. (This is the default.)

=item --hisat

Use the Host HISAT suite of RNA tools.

=item --reference-genome-id

If specified, the ID of a genome in PATRIC to which the reads will be aligned.  This operation is always performed last.

=item --workspace-path-prefix

Base workspace directory for relative workspace paths.

=item --workspace-upload-path

Name of workspace directory to which local files should be uplaoded.

=item --overwrite

If a file to be uploaded already exists and this parameter is specified, it will be overwritten; otherwise, the script will error out.

=item --help

Display the command-line usage and exit.

=item --dry-run

Display the JSON submission string and exit without invoking the service or uploading files.

=back

=cut

use strict;
use Getopt::Long;
use Bio::KBase::AppService::Client;
use P3AuthToken;
use Data::Dumper;
use Bio::KBase::AppService::CommonSpec;
use Bio::KBase::AppService::ReadSpec;
use Bio::KBase::AppService::UploadSpec;
use Bio::KBase::AppService::GenomeIdSpec;

# Insure we're logged in.
my $p3token = P3AuthToken->new();
if (! $p3token->token()) {
    die "You must be logged into PATRIC to use this script.";
}
# Get a common-specification processor, an uploader, and a reads-processor.
my $commoner = Bio::KBase::AppService::CommonSpec->new();
my $uploader = Bio::KBase::AppService::UploadSpec->new($p3token);
my $reader = Bio::KBase::AppService::ReadSpec->new($uploader, rnaseq => 1);

# Get the application service helper.
my $app_service = Bio::KBase::AppService::Client->new();

# Declare the option variables and their defaults.
my $rnaRocket = 0;		# This is the internal name for the Tuxedo option
my $hisat = 0;
my $fastqc = 0;
my $align = 0;
my $referenceGenomeId;
my @contrasts;
# Now we parse the options.
GetOptions($commoner->options(), $reader->lib_options(),
        'tuxedo' => \$rnaRocket,
        'hisat' => \$hisat,
        'contrast=s' => \@contrasts,
        'reference-genome-id|ref|genome=s' => \$referenceGenomeId
        );
# Verify the argument count.
if (! $ARGV[0] || ! $ARGV[1]) {
    die "Too few parameters-- output path and output name are required.";
} elsif (scalar @ARGV > 2) {
    die "Too many parameters-- only output path and output name should be specified.";
}
# Handle the output path and name.
my ($outputPath, $outputFile) = $uploader->output_spec(@ARGV);
# We will compute the recipe here.
if ($rnaRocket && $hisat) {
    die "Only one tool suite can be specified.";
}
my $recipe = ($hisat ? 'Host' : 'RNA-Rocket');
if (! $referenceGenomeId) {
    die "Reference genome ID is required.";
} elsif (! Bio::KBase::AppService::GenomeIdSpec::validate_genomes($referenceGenomeId)) {
    die "Invalid reference genome ID.";
}
# Build the parameter structure.
my $params = {
    contrasts => \@contrasts,
    recipe => $recipe,
    reference_genome_id => $referenceGenomeId,
    output_path => $outputPath,
    output_file => $outputFile
};
if (! $reader->check_for_reads()) {
    die "You must specify a FASTQ source.";
}
# Add the input FASTQ files.
$reader->store_libs($params);

# Submit the job.
$commoner->submit($app_service, $uploader, $params, RNASeq => 'RNASeq utilities');
