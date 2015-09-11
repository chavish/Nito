package Listen;

use strict;
use warnings;

use LWP::UserAgent;
use JSON;

use Exporter qw( import );
our @EXPORT_OK = qw( :ALL );

our $tracklist = './tracks';

sub main
{
	my $epoch_day = '86400'; # Represents number of seconds in one day
    my $list_age = _check_list_mtime();

	if( -e $tracklist && $list_age <= $epoch_day)#&& !-z $tracklist )
	{
            my $num_of_tracks = _get_number_of_tracks_in_list();
            my $track = send_a_track( $num_of_tracks );
            return $track;
	}else{
            get_new_tracks();
            my $num_of_tracks = _get_number_of_tracks_in_list();
            my $track = send_a_track( $num_of_tracks );
            return $track;
        }
}
sub get_new_tracks
{
    unlink $tracklist;
    open my $fh_tracklist, '>', $tracklist or print "Could not open $tracklist: $!\n";
	my $ua = LWP::UserAgent->new();
	$ua->timeout(10);
	my $requests = 50;
	
	my $response = $ua->get("http://www.reddit.com/r/listentothis/hot.json?limit=$requests");
	if ($response->is_success)
	{
		for( my $i = 0; $i <= $requests; $i++ )
		{
			my $container = from_json($response->content);
			if ( $container->{data}->{children}->[$i]->{data}->{title} && $container->{data}->{children}->[$i]->{data}->{secure_media}->{oembed}->{url} )
			{
				print $fh_tracklist "$container->{data}->{children}->[$i]->{data}->{title}: " . "$container->{data}->{children}->[$i]->{data}->{secure_media}->{oembed}->{url}\n";
			}
		}
	}else
	{
		print "$response->status_line\n";
		close( $fh_tracklist );
		return 1;
	}
	return 0;
}

sub send_a_track
{
	open( my $fh_tracklist, '<', $tracklist );	
	my $num_of_tracks = _get_number_of_tracks_in_list();

	my $int_rand = int( rand( $num_of_tracks ) );
	while( <$fh_tracklist> )
	{
		if ( $. == $int_rand )
		{
			my $track = $_;
			close $fh_tracklist;
			return $track;
		}
	}
	
	return "Something went wrong! $!\n";
}

sub _check_list_mtime
{
    open my $fh_tracklist, '<', $tracklist or print "Could not open $tracklist: $!\n";

    my $current_time = time();
    my $file_mtime = (stat( $fh_tracklist ) )[9];
	my $time_diff = $current_time - $file_mtime;

    close $fh_tracklist;
	return $time_diff; 
}

sub _get_number_of_tracks_in_list
{
	open( my $fh_tracklist, '<', $tracklist );	

	while( <$fh_tracklist>) {}
	my $number = $.;
	close $fh_tracklist;
	return $number;
} 
1;
