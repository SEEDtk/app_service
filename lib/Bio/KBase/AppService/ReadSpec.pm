#
# Copyright (c) 2003-2019 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
#


package Bio::KBase::AppService::ReadSpec;

    use strict;
    use warnings;

=head1 Object for Generating Read Input Specifications in P3 CLI Scripts

This object handles input specifications for reads.  The user can specify multiple read sources, including paired-end libraries,
IDs from the NCBI Sequence Read Archive, interleaved single-end libraries, and simple single-end libraries.  This object generates
the L<Getop::Long/GetOptions> specifications for the four input types as well as their modifiers and provides a method to parse
the options into a parameter object.

=head2 Special Methods

=head3 new

    my $reader = Bio::KBase::AppService::ReadSpec->new($uploader);

Create a new read input specification handler.

=over 4

=item uploader

L<Bio::KBase::AppService::UploadSpec> object for processing files.

=back

=cut

sub new {
    my ($class, $uploader) = @_;
    my $retVal = {
        uploader => $uploader,
        platform => 'infer',
        read_orientation_outward => 0,
        insert_size_mean => undef,
        insert_size_stdev => undef,
        paired_end_libs => [],
        single_end_libs => [],
        srr_ids => [],
        saved_file => undef,
    };
    bless $retVal, $class;
    return $retVal;
}

=head3 lib_options

This method returns a list of L<Getopt::Long> option specifications for the different parameters involved in read input
specification.  This includes the input libraries by type as well as the sequencing platform identifier and
tweaks such as the mean insert size.  The file upload options from L<Bio::KBase::AppService::UploadSpec> are automatically
incorporated in the list.

    my @options = $reader->lib_options();

=cut

sub lib_options {
    my ($self) = @_;
    return ("paired-end-lib=s{2}" => sub { $self->_pairedLib($_[1]); },
            "interleaved-lib=s" => sub { $self->_interleavedLib($_[1]); },
            "single-end-lib=s" => sub { $self->_singleLib($_[1]); },
            "srr-id=s" => sub { $self->_srrDownload($_[1]); },
            "platform=s" => sub { $self->{platform} = $_[1]; },
            "read-orientation-outward" => sub { $self->{read_orientation_outward} = 1; },
            "read-orientation-inward" => sub { $self->{read_orientation_outward} = 0; },
            "insert-size-mean=i" => sub { $self->{insert_size_mean} = $_[1]; },
            "insert-size-stdev=i" => sub { $self->{insert_size_stdev} = $_[1]; },
            $self->{uploader}->file_options(),
        );
}

=head3 _pairedLib

    $reader->_pairedLib($fileName);

This method processes a file specification for a paired-end library.  We expect two of these to come in one at a time.  When the
first one is processed, we add it to the saved-file queue.  When the second one is processed, we create a parameter specification
for the two libraries and save it in C<paired_end_libs> list.

=over 4

=item fileName

Name of the file to put in a paired-end library.

=back

=cut

sub _pairedLib {
    my ($self, $fileName) = @_;
    # Verify that the user has not put an option in the file list.
    my $saved = $self->{saved_file};
    if ($saved && substr($fileName, 0, 1) eq '-') {
        die "paired_end_libs requires two parameters, but $fileName found.";
    }
    # Get the uploader and convert the file name.
    my $uploader = $self->{uploader};
    my $wsFile = $uploader->fix_file_name($fileName, 'reads');
    if (! $saved) {
        # Here we have the first file of a pair.
        $self->{saved_file} = $wsFile;
    } else {
        # Here it is the second file. Create the libraries spec.
        my $lib = {
            read1 => $saved,
            read2 => $wsFile,
            interleaved => 0
        };
        # Add the optional parameters.
        $self->_processTweaks ($lib);
        # Queue the library pair.
        push @{$self->{paired_end_libs}}, $lib;
        # Denote we are starting over.
        $self->{saved_file} = undef;
    }
}

=head3 _interleavedLib

    $reader->_interleavedLib($fileName);

Store a file as an interleaved paired-end library.  In this case, only a single library is specified.

=over 4

=item fileName

Name of the file containing interleaved pair-end reads.

=back

=cut

sub _interleavedLib {
    my ($self, $fileName) = @_;
    # Get the uploader and convert the file name.
    my $uploader = $self->{uploader};
    my $wsFile = $uploader->fix_file_name($fileName, 'reads');
    # Create the library specification.
    my $lib = {
        read1 => $wsFile,
        interleaved => 1
    };
    # Add it to the paired-end queue.
    push @{$self->{paired_end_libs}}, $lib;
}

=head3 _singleLib

    $reader->_singleLib($fileName);

Here we have a file name for a single-end read library.  Add it to the single-end queue.

=over 4

=item fileName

Name of the file containing interleaved pair-end reads.

=back

=cut

sub _singleLib {
    my ($self, $fileName) = @_;
    # Get the uploader and convert the file name.
    my $uploader = $self->{uploader};
    my $wsFile = $uploader->fix_file_name($fileName, 'reads');
    # Create the library specification.  Note that the platform is the only tweak allowed.
    my $lib = {
        read => $wsFile,
        platform => $self->{platform}
    };
    # Add it to the single-end queue.
    push @{$self->{single_end_libs}}, $lib;
}

=head3 _srrDownload

    $reader->_srrDownload($srr_id);

Here we have an SRA accession ID and we want to queue a download of the sample from the NCBI.

=over 4

=item srr_id

SRA accession ID for the sample to download.

=back

=cut

sub _srrDownload {
    my ($self, $srr_id) = @_;
    # Add the SRA accession ID to the download queue.
    push @{$self->{srr_ids}}, $srr_id;
}

=head2 Query Methods

=head3 store_libs

    $reader->store_libs($params);

Store the read-library parameters in the specified parameter structure.

=over 4

=item params

Parameter structure into which the read libraries specified on the command line should be stored.

=back

=cut

sub store_libs {
    my ($self, $params) = @_;
    $params->{paired_end_libs} = $self->{paired_end_libs};
    $params->{single_end_libs} = $self->{single_end_libs};
    $params->{srr_ids} = $self->{srr_ids};
}

=head2 Internal Utilities

=head3 _processTweaks

    $reader->_processTweaks($lib);

Add the optional parameters to a library specification.

=over 4

=item lib

Hash reference containing the current library specification.  Optional parameters with values will be added to it.

=cut

sub _processTweaks {
    my ($self, $lib) = @_;
    for my $parm (qw(insert_size_mean insert_size_stdev platform read_orientation_outward)) {
        if ( defined $self->{$parm} ) {
            $lib->{$parm} = $self->{$parm};
        }
    }
}

1;
