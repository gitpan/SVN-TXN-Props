# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SVN-TXN-Props.t'

#########################

use strict;
use warnings;
use Test::More tests => 34;
use Test::MockClass qw(SVN::Core SVN::Fs SVN::Repos);
BEGIN { use_ok('SVN::TXN::Props', qw(get_txn_props)) };

#########################

my $repos = './repo';
my $txn = 'txn-1';

my %changed_props;
my $test_props = { 'svn:prop' => 'value' };
my $mockSVNTxnClass = Test::MockClass->new('MockSVNTxn');
$mockSVNTxnClass->defaultConstructor();
$mockSVNTxnClass->setReturnValues('proplist', 'always', $test_props);
$mockSVNTxnClass->addMethod('change_prop',
	sub {
		$changed_props{$_[1]} = $_[2];
	});

my $mockSVNFsClass = Test::MockClass->new('SVN::Fs');
$mockSVNFsClass->defaultConstructor();
$mockSVNFsClass->addMethod('open_txn',
	sub { 
		my $mockTxn = $mockSVNTxnClass->create();
		$mockTxn->{args} = @_;
		return $mockTxn;
	});

my $mockSVNReposClass = Test::MockClass->new('SVN::Repos');
$mockSVNReposClass->noTracking();
$mockSVNReposClass->defaultConstructor();
$mockSVNReposClass->addMethod('open',
	sub { 
		my $mockRepos = $mockSVNReposClass->create();
		$mockRepos->{args} = @_;
		return $mockRepos;
	});
$mockSVNReposClass->addMethod('fs',
	sub { 
		my $mockFs = $mockSVNFsClass->create();
		$mockFs->{args} = @_;
		return $mockFs;
	});


my $props = get_txn_props($repos, $txn);
ok(ref($props) eq 'HASH');
is(scalar keys %$props, 1);
is($props->{'svn:prop'}, 'value');
is(scalar keys %changed_props, 0);

$props->{'svn:newprop'} = 'newvalue';
is(scalar keys %$props, 2);
is($props->{'svn:newprop'}, 'newvalue');
is(scalar keys %changed_props, 1);
is($changed_props{'svn:newprop'}, 'newvalue');

$props->{'svn:prop'} = 'othervalue';
is(scalar keys %$props, 2);
is($props->{'svn:prop'}, 'othervalue');
is($props->{'svn:newprop'}, 'newvalue');
is(scalar keys %changed_props, 2);
is($changed_props{'svn:prop'}, 'othervalue');
is($changed_props{'svn:newprop'}, 'newvalue');

delete $props->{'svn:prop'};
is(scalar keys %$props, 1);
is(scalar keys %changed_props, 2);
ok(exists $changed_props{'svn:prop'});
is($changed_props{'svn:prop'}, undef);
is($changed_props{'svn:newprop'}, 'newvalue');

$props->{'svn:prop'} = 'othervalue';
is(scalar keys %$props, 2);
is($props->{'svn:prop'}, 'othervalue');
is($props->{'svn:newprop'}, 'newvalue');
is(scalar keys %changed_props, 2);
is($changed_props{'svn:prop'}, 'othervalue');
is($changed_props{'svn:newprop'}, 'newvalue');

%$props = ();
is(scalar keys %$props, 0);
is(scalar keys %changed_props, 2);
ok(exists $changed_props{'svn:prop'});
ok(exists $changed_props{'svn:newprop'});
is($changed_props{'svn:prop'}, undef);
is($changed_props{'svn:newprop'}, undef);

eval {
	get_txn_props($repos, undef);
	fail("should have croaked");
};
ok(defined $@);

eval {
	get_txn_props(undef, $txn);
	fail("should have croaked");
};
ok(defined $@);

1;
