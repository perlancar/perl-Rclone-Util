package Rclone::Util;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       parse_rclone_config
               );

our %SPEC;

our %argspecs_common = (
    rclone_config_filenames => {
        schema => ['array*', of=>'filename*'],
        tags => ['category:configuration'],
    },
    rclone_config_dirs => {
        schema => ['array*', of=>'dirname*'],
        tags => ['category:configuration'],
    },
);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utility routines related to rclone',
};

$SPEC{parse_rclone_config} = {
    v => 1.1,
    summary => 'Read and parse rclone configuration file(s)',
    description => <<'_',

By default will search these paths for `rclone.conf`:

All found files will be read, parsed, and merged.

Returns the merged config hash.

_
    args => {
        %argspecs_common,
    },
};
sub parse_rclone_config {
    my %args = @_;

    my @dirs      = @{ $args{rclone_config_dirs} // ["$ENV{HOME}/.config/rclone", "/etc/rclone", "/etc"] }; # XXX on windows?
    my @filenames = @{ $args{rclone_config_filenames} // ["rclone.conf"] };

    my @paths;
    for my $dir (@dirs) {
        for my $filename (@filenames) {
            my $path = "$dir/$filename";
            next unless -f $path;
            push @paths, $path;
        }
    }
    unless (@paths) {
        return [412, "No config paths found/specified"];
    }

    require Config::IOD::Reader;
    my $reader = Config::IOD::Reader->new;
    my $merged_config_hash;
    for my $path (@paths) {
        my $config_hash;
        eval { $config_hash = $reader->read_file($path) };
        return [500, "Error in parsing config file $path: $@"] if $@;
        for my $section (keys %$config_hash) {
            my $hash = $config_hash->{$section};
            for my $param (keys %$hash) {
                $merged_config_hash->{$section}{$param} = $hash->{$param};
            }
        }
    }
    [200, "OK", $merged_config_hash];
}

1;
# ABSTRACT:

=for Pod::Coverage .+

=head1 SEE ALSO

L<https://rclone.org>
