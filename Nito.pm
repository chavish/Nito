package Nito;

use strict;
use warnings;

use IO::Socket;
use IO::Socket::INET;
use LWP::UserAgent;
use Listen;

use Exporter qw( import );
our @EXPORT_OK = qw( :ALL );

our %main_dispatch = 
(
	karl    => \&quote_karl,
	insult  => \&insult_new,
	track   => \&get_track,
	lol     => \&say_lol,
    payday  => \&find_payday,
    slap    => \&slap,
);


sub new
{
	my $class = shift;
	my $self =
	{
		socket => shift,
		nick => shift,
		user => shift,
	};

	bless $self, $class;
	return $self;
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
	my $socket = $self->{socket};
    my %channels = _get_channels();
   
    foreach my $key (keys %channels)
    {
        print $socket "JOIN $key $channels{$key}\r\n";
#        print $socket "PRIVMSG $key :The only solution is extinction: http://bit.ly/1VNBka0\r\n";
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
		# Handle any incoming pings while we wait to identify. 
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

sub sock_read
{
	# Read the socket, wait for a command
	my $self = shift;
	my $socket = $self->{socket}; # Dunno why but print does not like $self->{socket}

	while ( my $input = <$socket> )
	{
        chop $input;
        print "$input\n";
        if ( $input =~ /^PING(.*)$/i )
        {   
                print $socket "PONG $1\r\n";
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
}


sub say_lol
{
	my ($self, $channel) = @_;
	my $socket = $self->{socket};
	my $range = 10;

    my $int_rand = int( rand( $range ) );
    $int_rand++;

    if ( $int_rand == 2 || $int_rand == 8 )
	{
	    print $socket "PRIVMSG " . $channel . " :" . qq/lol\r\n/;
	}
	if ( $int_rand == 7 )
	{
	    print $socket "PRIVMSG " . $channel . " :" . qq/blolol\r\n/;
	}

    sock_read( $self );
}

sub quote_karl
{
	my ($self, $channel) = @_;
	my $socket = $self->{socket};
	my $karlisms_file = './karlisms';
	my $range = '20';

	# get a random number between 1 and $range
	my $rand_quote = int( rand( $range ) );

	open( my $fh_handle, '<', $karlisms_file );
	while( <$fh_handle> )
	{
		if ( $. == $rand_quote )
		{
			my $quote = $_;
			print $socket "PRIVMSG " . $channel . " :" . qq/$_\r\n/;
		}
	}

	close( $fh_handle );
	sock_read( $self );

}

sub insult_new
{
	my ($self, $channel) = @_;
	my $socket = $self->{socket};

	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);

	my $response = $ua->get('http://www.pangloss.com/seidel/Shaker/index.html');
	if ($response->is_success) 
	{
        	my $text = $response->decoded_content;
        	$text =~ s/\r//g;
       		$text =~ s/\n//g;
        	$text =~ m/.*font\ size\=\"\+2\"\>(.*)\<\/font\>/;
        	my $insult = $1;
         	print $socket "PRIVMSG " . $channel . " :" . qq/$insult\r\n/;       
	}    

	sock_read( $self );
}

sub slap
{
    my ($self, $channel, @args) = @_;
    my $socket = $self->{socket};

    if($args[0] !~ m/[a-zA-Z0-9\-\|]/i)
    {
        sock_read($self);
    }
    
    if($args[0] eq 'chavish')
    {
        print $socket "PRIVMSG $channel :\001ACTION [RAUGHS]\r\n";
        sock_read($self);
    }

    if($args[0] eq 'nito')
    {
        sock_read($self);
    }

    print $socket "PRIVMSG $channel :\001ACTION slaps $args[0] around a bit with a large trout.\r\n";
    sock_read($self);
}

sub find_payday
{
    my ($self, $channel) = @_;
    my $socket = $self->{socket};

    my $result = `perl ./payday.pl`;
    print $socket "PRIVMSG " . $channel . " :" . qq/$result\r\n/;
}

sub get_track
{
	# Get a track from reddit
	my ($self, $channel) = @_;
	my $socket = $self->{socket};

	my $track  = Listen::main();
        print $socket "PRIVMSG " . $channel . " :" . qq/$track\r\n/;
	
	sock_read( $self );
}
1;
