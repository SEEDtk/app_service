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


package Bio::KBase::AppService::CommonSpec;

    use strict;
    use warnings;
    use Pod::Usage;

=head1 Common Options for Command-Line Scripts

This object processes options common to all command-line scripts.  Use L</options> to include these options in the
L<Getopt::Long/GetOptions> parameter list. Currently, C<--dry-run> and C<--help> are included.

=head2 Special Methods

=head3 new

    my $commoner = Bio::KBase::AppService::CommonSpec->new();

Create the common-options object.

=cut

sub new {
    my ($class) = @_;
    my $retVal = { dry => 0 };
    bless $retVal, $class;
    return $retVal;
}

=head3 options

    my @options = $commoner->option();

Return the options list for the common options.

=cut

sub options {
    my ($self) = @_;
    return ("dry-run" => sub { $self->{dry} = 1; },
            "help|h" => sub { print pod2usage(-verbose => 99, -exitVal => 0); });
}

=head3 check_dry_run

    $commoner->check_dry_run($param);

If this is a dry run, outputs the JSON and exits.

=over 4

=item param

Parameter object built for execution.

=cut

sub check_dry_run {
    my ($self, $param) = @_;
    if ($self->{dry}) {
        print "Data submitted would be:\n\n";
        print JSON::XS->new->pretty(1)->encode($param);
        exit(0);
    }
}

1;


