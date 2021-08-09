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


package Bio::KBase::AppService::UploadSpec;

    use strict;
    use warnings;
    use File::Basename;
    use Bio::P3::Workspace::WorkspaceClientExt;
    use POSIX;

=head1 Object for Managing Uploads in P3 CLI

This object manages parameters relating to file upload in PATRIC.  When a parameter specifies a file, the file can have a C<ws:> prefix, indicating
it is already in the workspace.  If not, the file must be uploaded.  The parameters relating to this process include the following

=over 4

=item --workspace-path-prefix

Base workspace directory for relative workspace paths.

=item --workspace-upload-path

Name of workspace directory to which local files should be uplaoded.

=item --overwrite

If a file to be uploaded already exists and this parameter is specified, it will be overwritten; otherwise, the script will error out.

=back

=head2 Output Specificiers

The standard positional parameters for submission scripts are the output path and an output folder name.  These can be
processed using the L</output_spec> method.

=head2 Special Methods

=head3 new

    my $uploader = UploadSpec->new($token);

Initialize the uploader.  We pass in the authorization token.

=over 4

=item token

L<P3AuthToken> for authorization.

=back

=cut

sub new {
    my ($class, $token) = @_;
    my $ws = Bio::P3::Workspace::WorkspaceClientExt->new();
    # Create the object.
    my $retVal = { overwrite => 0,
        prefix => undef,
        uploadPath => undef,
        ws => $ws,
        token => $token,
        upload_queue => []
    };
    bless $retVal, $class;
    return $retVal;
}

=head3 file_options

    my @options = $uploader->file_options();

This returns a list of the L<Getopt::Long::Descriptive> entries for file specification.

=cut

sub file_options {
    my ($self) = @_;
    return ("workspace-path-prefix|p=s" => sub { $self->_setPrefix($_[1]); },
            "workspace-upload-path|P=s" => sub { $self->_setPath($_[1]); },
            "overwrite|f" => sub { $self->_setOverwrite(); }
         );
}

=head3 _setPrefix

    $uploader->_setPrefix($prefix);

Set the workspace filename prefix.  This method is called by L<GetOpt::Long/GetOptions>.

=over 4

=item prefix

Prefix to put on relative workspace path names.

=cut

sub _setPrefix {
    my ($self, $prefix) = @_;
    # Insure the prefix ends with a slash.
    $prefix =~ s/\/+$//;
    $prefix .= '/';
    $self->{prefix} = $prefix;
}

=head3 _setPath

    $uploader->_setPath($path);

Specify the workspace upload path.  This method is called by L<GetOpt::Long/GetOptions>.

=over 4

=item path

Path to use for uploading local files.

=back

=cut

sub _setPath {
    my ($self, $path) = @_;
    # Insure the path ends with a slash.
    $path =~ s/\/+$//;
    $path .= '/';
    $self->{uploadPath} = $path;
}

=head3

    $uploader->_setOverwrite();

Denote that overwriting during upload is OK.  This method is called by L<GetOpt::Long/GetOptions>.

=cut

sub _setOverwrite {
    my ($self) = @_;
    $self->{overwrite} = 1;
}

=head2 Query Methods

=head3 output_spec

    my ($outPath, $outName) = $uploader->output_spec($inPath, $inName);

Fix and return the output path and output name parameters from a submission script.  These are usually left in C<@ARGV> after argument
processing with L<GetOpt::Long/GetOptions> is complete, so a typical invocation is

    my ($outPath, $outName) = $uploader->output_spec(@ARGV);

=over 4

=item inPath

Output path name.  This must be a workspace directory name, without the C<ws:> prefix.

=item inName

Output folder name.  This is a simple string that must be a legal job or folder name.  It will be created in the output path
directory.

=item RETURN

Returns a list containing the normalized output path and folder names.

=back

=cut

sub output_spec {
    my ($self, $inPath, $inName) = @_;
    my $outPath = $inPath;
    # Just in case, remove the ws prefix.
    $outPath =~ s/^ws://;
    # Normalize the output name.
    $outPath = $self->normalize($outPath);
    # Verify the folder exists.
    my $ws = $self->{ws};
    my $stat = $ws->stat($outPath);
    if (! $stat || ! S_ISDIR($stat->mode)) {
        die "Output path $outPath does not exist.";
    }
    return ($outPath, $inName);

}

=head3 normalize

    my $realPath = $uploader->normalize($path);

Fix up a path.  If the path is relative, we add the workspace prefix.  If there is no workspace prefix and the path is relative, it is an error.

=over 4

=item path

Path string to normalize.

=item RETURN

Returns the path name with the prefix attached if necessary.

=back

=cut

sub normalize {
    my ($self, $path) = @_;
    my $retVal = $path;
    # Check for a leading "ws:".  This handles the case where we know a file (or folder) is in the workspaces, but the user has added the
    # prefix anyway.
    if ($path =~ /^ws:(.+)/) {
        $retVal = $1;
    }
    if ($retVal !~ /^\//) {
        # No leading slash, so this is a relative path.
        if (! $self->{prefix}) {
            die "No workspace-path-prefix specified, but a relative path name was found: $path.";
        } else {
            $retVal = $self->{prefix} . $retVal;
        }
    }
    return $retVal;
}

=head3 fix_file_name

    my $wsName = $uploader->fix_file_name($inputName, $type);

This method will take a file name parameter, determine if it is local or workspace, and convert it to a workspace file name.  If it is
local, it will be added to the upload queue.

=over 4

=item inputName

Input file name string.

=item type

Type of file (e.g. C<reads> or C<contigs>).

=item RETURN

Returns the absolute name of the file in the PATRIC workspaces.

=back

=cut

sub fix_file_name {
    my ($self, $inputName, $type) = @_;
    my $ws = $self->{ws};
    my $retVal;
    # Parse the input file name.
    if ($inputName =~ /^ws:/) {
        # Here the user has specified a file already in the workspace.
        $retVal = $self->normalize($inputName);
    } else {
        # Here we must upload from the local file system.
        if (! $self->{uploadPath}) {
            die "Local file specified, but no workspace-upload-path provided.";
        } elsif (! -f $inputName) {
            die "Local file $inputName is not found or invalid.";
        }
        my $base = File::Basename::basename($inputName);
        $retVal = $self->normalize($self->{uploadPath} . $base);
        if (! $self->{overwrite} && $ws->stat($retVal)) {
            die "Target path $retVal already exists and --overwrite not specified\n";
        }
        push @{$self->{upload_queue}}, [$inputName, $retVal, $type];
    }
    return $retVal;
}

=head3 process_uploads

    $uploader->process_uploads();

This method uploads all of the files in the upload queue.

=cut

sub process_uploads {
    my ($self) = @_;
    my $queue = $self->{upload_queue};
    my $ws = $self->{ws};
    my $overwriteFlag = $self->{overwrite};
    my $token = $self->{token};
    for my $upload (@$queue) {
        my ($source, $dest, $type) = @$upload;
        # Get the file size for later.
        my $size = -s $source;
        # Now we want to upload $source to $dest.
        eval {
            print "Uploading $source file of type \"$type\" to $dest.\n";
            $ws->save_file_to_file($source, {}, $dest, $type, $overwriteFlag, 1, $token->token());
        };
        # Insure the upload worked.
        if ($@) {
            die "Failure uploading $source to $dest: $@";
        }
        my $stat = $ws->stat($dest);
        if (! $stat) {
            die "Error uploading ($dest was not present after upload).\n";
        } else {
            my $wsSize = $stat->size;
            if ($wsSize != $size) {
                die "Error uploading $source: filesize at workspace ($wsSize) did not match original size $size)."
            }
            print "Done uploading $source to $dest.\n";
        }
    }
}

1;


