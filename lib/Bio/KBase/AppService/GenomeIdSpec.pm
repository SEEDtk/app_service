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


package Bio::KBase::AppService::GenomeIdSpec;

    use strict;
    use warnings;
    use P3DataAPI;
    use P3Utils;

=head1 Service Module for Genome ID Lists

This module provides methods for validation PATRIC genome IDs.  It makes sure the genome is found in PATRIC.  This is important
when submitting long-running jobs where an error detected after several hours is really annoying.

=head2 Special Methods

=sub validate_genomes

    my $okFlag = Bio::KBase::AppService::GenomeIdSpec::validate_genomes($ids);

=over 4

=item ids

Either a single genome ID, a local file name, or a comma-delimited list of genome IDs.

=item RETURN

The list of IDs if it is valid, else C<undef>, indicating an error.

=back

=cut

sub validate_genomes {
    my ($ids) = @_;
    my $retVal;
    # Insure if we have input.
    if (! defined $ids) {
        print "No genome IDs specified.\n";
    } else {
        # First, check for a local file.
        if (-s $ids) {
            open(my $ih, '<', $ids) || die "Could not open genome ID file $ids: $!";
            # Skip the header line.
            my $line = <$ih>;
            $retVal = P3Utils::get_col($ih, 0);
            close $ih;
        } else {
            # Split the IDs using a comma.
            $retVal = [split /,/, $ids];
        }
        # Get rid of the badly-formatted IDs.
        my @bads = grep { $_ !~ /^\d+\.\d+$/ } @$retVal;
        if (scalar @bads) {
            print "Invalid genome ID strings specified: " . join(", ", map { "\"$_\"" } @bads) . "\n";
            undef $retVal;
        } else {
            # Ask PATRIC about the genome IDs.
            my $p3 = P3DataAPI->new();
            my @rows = $p3->query(genome => ['select', 'genome_id', 'domain'], ['in', 'genome_id', "(" . join(",", @$retVal) . ")"]);
            # This will hold all the genome IDs we haven't found yet.
            my %missing = map { $_ => 1 } @$retVal;
            for my $row (@rows) {
                if ($row->{genome_id}) {
                    $missing{$row->{genome_id}} = 0;
                }
            }
            # Output the missing genome IDs.
            for my $genome (sort keys %missing) {
                if ($missing{$genome}) {
                    print "Could not find genome ID $genome in PATRIC.\n";
                    undef $retVal;
                }
            }
        }
    }
    return $retVal;
}


1;


