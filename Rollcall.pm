package Rollcall; 

use strict;
use warnings;

use Exporter qw( import );
our @EXPORT_OK = qw( :ALL );

our $rollcall = './rollcall';
our %honklers;

sub main
{
   my ($command, $user) = @_;

   if(!$command)
   {
        report_honklers();
   }elsif($command eq 'add' && $user)
   {
        add_honkler($user);
   }else
   {
        report_honklers();
   }

}

sub add_honkler 
{
    my ($user) = @_;

    my $epoch_day = '86400'; # Represents number of seconds in one day
    my $list_age = _check_list_mtime();

	if( -e $rollcall && $list_age <= $epoch_day )
	{
        $honklers{$user}++;
        return report_honklers();
	}else
    {
        # Touch the file and add the user 
        open my $fh_rollcall, '>', $rollcall or print "Could not open $rollcall: $!\n";
        close $fh_rollcall;
        %honklers = {};
        $honklers{$user}++;
        return report_honklers(); 
    }

}

sub report_honklers
{
    
    if(!%honklers)
    {
        return "No honklerbros for today. :(";
    }

    my $string = "Current honklebros: ";

    foreach my $key (keys %honklers)
    {
        $string .= "$key ";
    }

    return $string;
}

sub _check_list_mtime
{
    open my $fh_rollcall, '<', $rollcall or print "Could not open $rollcall: $!\n";

    my $current_time = time();
    my $file_mtime = (stat( $fh_rollcall ) )[9];
	my $time_diff = $current_time - $file_mtime;

    close $fh_rollcall;
	return $time_diff; 
}

1;