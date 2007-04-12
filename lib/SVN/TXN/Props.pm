package SVN::TXN::Props;

use 5.008007;
use strict;
use warnings;
use Tie::Hash;
use SVN::Core;
use SVN::Fs;
use SVN::Repos;
use Carp;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter Tie::ExtraHash);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SVN::TXN::Props ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	get_txn_props
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '1.00';

sub get_txn_props {
	my ($repository_path, $txn_name, $hash) = @_;
	$hash ||= {};
	tie %$hash, 'SVN::TXN::Props', $repository_path, $txn_name;
	return $hash;
}

sub TIEHASH ($$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my ($repository_path, $txn_name) = @_;
	defined $repository_path and defined $txn_name or
		croak "repository_path and txn_name arguments are required";

	my $repos = SVN::Repos::open($repository_path);
	my $txn = $repos->fs->open_txn($txn_name);

	my $self = bless [ $txn->proplist(), $txn ];
	return $self;
}

sub STORE ($$$) {
	my $self = shift;
	my ($key, $value) = @_;
	$self->[1]->change_prop($key, $value);
	$self->SUPER::STORE(@_);
}

sub DELETE ($$) {
	my $self = shift;
	my ($key) = @_;
	$self->[1]->change_prop($key, undef);
	$self->SUPER::DELETE(@_);
}

sub CLEAR ($) {
	my $self = shift;
	foreach my $key (keys %{$self->[0]}) {
		$self->[1]->change_prop($key, undef);
	}
	$self->SUPER::CLEAR(@_);
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
=head1 NAME

SVN::TXN::Props - Provides a hash interface to Subversion transaction properties

=head1 SYNOPSIS

  use SVN::TXN::Props qw(get_txn_props);
  my $props = get_txn_props('/svnrepo', '1-0');
  $props->{'svn:author'} = 'nobody';

=head1 DESCRIPTION

Maps properties from a subversion transaction to a hash.  This allows for
reading and manipulating properties of active subversion transactions before
the transaction is commited, for example during a pre-commit hook script.

This module provides a tied hash interface, allowing it to be used with the
perl tie function, eg:

  use SVN::TXN::Props;
  tie %props, 'SVN::TXN::Props', $repository_path, $txn_name;
  $props{'svn:author'} = 'nobody';

Alternatively, the function get_txn_props can be imported, which will
returned an already tied hash reference, eg:

  use SVN::TXN::Props qw(get_txn_props);
  my $props = get_txn_props($repository_path, $txn_name);
  $props->{'svn:author'} = 'nobody';

=head1 SEE ALSO

SVN::Repo, SVN::Fs

=head1 AUTHOR

Chris Leishman, E<lt>chris@leishman.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Chris Leishman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
