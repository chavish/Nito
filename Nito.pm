#!/usr/bin/perl
package Nito;

use strict;
use warnings;

use IO::Socket;
use IO::Socket::INET;
use LWP::UserAgent;
use Listen;

use Exporter qw( import );
our @EXPORT_OK = qw( :ALL );

our $ua = LWP::UserAgent->new(
    requests_redirectable => [ 'GET', 'HEAD', 'POST' ],
);
$ua->timeout(10);

our %opts = load_config();

our %main_dispatch = 
(
	karl    => \&quote_karl,
	insult  => \&insult_new,
	track   => \&get_track,
	lol     => \&say_lol,
    payday  => \&find_payday,
    slap    => \&slap,
    say     => \&rainbow_say,
    wiki    => \&get_a_wiki_page,
);

sub new
{
	my $class = shift;
	my $self =
	{
		socket  => shift    || _get_a_socket(),
		nick    => shift    || $opts{nick} || 'nito',
		user    => shift    || $opts{user} || 'gravelord_nito 8 * :Gravelord Nito',
	};

	bless $self, $class;
	return $self;
}

sub _get_a_socket
{
    my $socket = IO::Socket::INET->new(
        PeerAddr => $opts{server},
        PeerPort => $opts{port},
        Proto => 'tcp')
        or die "Can't connect to $opts{server}:$opts{port}! $!.\n";

    return $socket;
}

sub run
{
    my ($self) = @_;

    irc_ident($self);
    join_chan($self);
    read_socket($self);
}

sub _legal_key
{
    my ( $key ) = @_;
    return scalar grep { $key eq $_ } qw/nick user server port/;
}

sub load_config
{
    my $config_file = './nito_config';
    my %config = (
        server => 'irc.paraphysics.net',
        port => '6667',
        nick => "nito",
        user => 'gravelord_nito 8 * :Gravelord Nito',
    );
   
    %config = _read_configs( $config_file );
    foreach my $key (keys %config)
    {
        die "Unrecognized key: $key in $config_file!\n" unless _legal_key( $key );
    }

    return %config;
}

sub _read_configs
{
    my ($config_file) = @_;
    my %config;

    open my $fh, '<', $config_file or die "Could not open file: $config_file:\n $!\n";
    while( <$fh> )
    {
        chomp;
        $_ =~ s/;.*//;
        next if $_ =~ m/^\s*$/;

        my ( $key, $value ) = split /\s*:\s*/, $_, 2;
        $value =~ s/\s+$//g;
        $config{ lc $key } = $value;
    }  

    return %config;
}

sub _get_channels
{
    my $channels_file = './channels';
    my %channels = _read_configs( $channels_file );
    return %channels;
}

sub join_chan 
{
	my ($self) = @_;
    my %channels = _get_channels();
   
    foreach my $key (keys %channels)
    {
        print { $self->{socket} } "JOIN $key $channels{$key}\r\n";
    }

    return $self;
}

sub irc_ident 
{
	# Identify self to IRC server
	my $self = shift;
	my $socket = $self->{socket};

	print $socket "NICK $self->{nick}\r\n";
	print $socket "USER $self->{user}\r\n";
	
	while( my $input = <$socket> )
	{
        	chop $input;
		    # Observed on efnet: Needing to respond to a ping before nick and user are set.
        	if ( $input =~ /^PING(.*)$/i )
        	{   
                	print $socket "PONG $1\r\n";
        	}   
        	if ( $input =~ /004/ ) # 004 Indicates we successfully id'd with the server.
        	{   
		       	last;
        	}   
    
        	if ( $input =~ /433/  )
        	{   
                	die "Nickname is in use!\n";
        	}   
        	
		print "$input\n";

	}
	return $self;
}

sub dispatch_from_sock
{
    my ($self, $input) = @_;

    print "$input\n";

    if ( $input =~ /^PING(.*)$/i )
    {   
            print { $self->{socket} } "PONG $1\r\n";
    }

    if ( $input =~ m/:.*\!.*@.*PRIVMSG (#.*):\.*lol/ )
    {
        my $channel = $1;
        $main_dispatch{'lol'}->( $self, $channel );
    }

    if ( $input =~ m/:.*\!.*@.*PRIVMSG (#.*):\!(.*)$/ )
    {
        my $channel = $1;
        my ($func, @args) = split/\s+/, $2;

        if ( defined $main_dispatch{$func} )
            {
                $main_dispatch{$func}->( $self, $channel, @args );
            }	
    }
}

sub read_socket
{
	my $self = shift;
    my $socket = $self->{socket};

	while ( my $input = <$socket> )
	{
        chop $input;
        dispatch_from_sock($self, $input);
	}
}

sub say_lol
{
	my ($self, $channel) = @_;
	my $range = 10;

    my $int_rand = int( rand( $range ) );
    $int_rand++;

    if ( $int_rand == 2 || $int_rand == 8 )
	{
        sock_print($self, $channel, 'lol');
	}

    if ( $int_rand == 7 )
	{
        sock_print($self, $channel, 'blolol');
	}
}

sub quote_karl
{
	my ($self, $channel) = @_;
	my $karlisms_file = './karlisms';
	my $range = '20';

	my $rand_num = int( rand( $range ) );
    $rand_num++;

	open my $fh_handle, '<', $karlisms_file;
    while( <$fh_handle> )
    {
        if ( $. == $rand_num )
        {
            my $quote = $_;
            sock_print($self, $channel, $quote);
        }
    }
    close( $fh_handle );
}

sub insult_new
{
	my ($self, $channel) = @_;

	my $response = $ua->get('http://www.pangloss.com/seidel/Shaker/index.html');
	if ($response->is_success) 
	{
        	my $text = $response->decoded_content;
        	$text =~ s/\r|\n//g;
        	$text =~ m/.*font\ size\=\"\+2\"\>(.*)\<\/font\>/;
        	my $insult = $1;
         	sock_print($self, $channel, $insult);
	}    
}

sub slap
{
    my ($self, $channel, @args) = @_;

    if($args[0] !~ m/[a-zA-Z0-9\-\|]/i || $args[0] eq 'nito' )
    {
       return; 
    }
    
    my $message = "\001ACTION slaps $args[0] around a bit with a large trout.\001\r\n";
    sock_print($self, $channel, $message);
}

sub rainbow_say
{

    my ($self, $channel, @args) = @_;

    my @colors = qw/4 8 9 10 11 12 13/;
    my $bg_color = '01';
    my $output;
    my $string;

    if($args[0] eq 'blink')
    {
        shift @args;
        $string = join(' ', @args) || "Don't be a dick, be a dude.";
        $bg_color = 14;
    }else
    {
        $string = join(' ', @args) || "Don't be a dick, be a dude.";
    }

    my @letters = split//, $string;

    foreach my $i (0..$#letters)
    {
        my $ci = $i % @colors;
        $output .= "\x03$colors[$ci],$bg_color$letters[$i]"; 
    }

    $output .= "\x03";
    sock_print($self, $channel, $output);
}

sub find_payday
{
    my ($self, $channel) = @_;
    my $result = `perl ./payday.pl`;
    sock_print($self, $channel, $result);
}

sub get_track
{
	# Get a track from reddit
	my ($self, $channel) = @_;
    sock_print($self, $channel, Listen::main());
}

sub get_a_wiki_page
{
	my ($self, $channel) = @_;
    my $rand_url = 'http://en.wikipedia.org/wiki/Special:Random';

    my $response = $ua->post($rand_url);
    sock_print($self, $channel, $response->{_previous}->{_headers}->{location});

}

sub sock_print
{
	my ($self, $channel, $message) = @_;
    print { $self->{socket} } "PRIVMSG  $channel  :$message\r\n";
}
1;
