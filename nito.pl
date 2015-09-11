#!/usr/bin/perl
# Nito: A Simple Bot Written in Perl
# Source: http://oreilly.com/pub/h/1964

use strict;
use Nito;
use IO::Socket::INET;

print "Gravelord Nito bot ver. 0.5\n";

my %opts = Nito::load_config();

my $socket = IO::Socket::INET->new(
	PeerAddr => $opts{server},
	PeerPort => $opts{port},
	Proto => 'tcp')
		or die "Can't connect to $opts{server}:$opts{port}! $!.\n";

my $nito = Nito->new( $socket, $opts{nick}, $opts{user} );

$nito->irc_ident();
print "Identified!\n";
$nito->join_chan();
$nito->sock_read();
