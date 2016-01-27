#!/usr/bin/perl

use warnings;
use strict;

use DateTime;

main() unless caller;

sub main
{
    my $today = DateTime->today;
    my $message = is_today_payday($today);

    if($message)
    {
        print $message;
        exit;
    }

    my $dt = find_nominal_payday($today);
    $dt = adjust_for_dayoff($dt);

    my $duration = $dt->subtract_datetime($today);
    my $days_until = $duration->in_units('days');
    my $date_paid = $dt->mdy('/');
    my $weekday = $dt->day_name;

    print "Payday is $days_until day(s) away on $weekday, $date_paid\n";
}
sub adjust_for_dayoff
{
    my ($dt) = @_;

    if($dt->day_of_week == 6)
    {
        # Adjust for Sat. Paid on Fri.
        $dt->subtract(days => 1);
    }elsif($dt->day_of_week == 7)
    {
        # Adjust for Sun. Paid on Fri.
        $dt->subtract(days => 2); 
    }elsif($dt->day_of_week == 1)
    {
       # Adjust for Mon. Paid on Sat.
       $dt->subtract(days => 2); 
    }elsif($dt->month == 12 && $dt->day == 25)
    {
        # Adjust for Christmas
        $dt->subtract(days => 1); # Probably
    }elsif($dt->month == 11 && $dt->week_of_month == 4)
    {
        # Adjust for Thanksgiving 
       if($dt->day_of_week == 4)
       {
            $dt->subtract(days => 1);
       }elsif($dt->day_of_week == 5)
       {
            $dt->subtract(days => 2);
       }
    }

    return $dt;
}

sub find_nominal_payday
{
    my ($dt) = @_;

    if($dt->day < 10)
    {
        return DateTime->new(
        year  => $dt->year,
        month => $dt->month,
        day   => 10,
        );
    }elsif($dt->day < 25)
    {
        return DateTime->new(
        year  => $dt->year,
        month => $dt->month,
        day   => 25,
        );
    }else{
        return DateTime->new(
        year  => $dt->year,
        month => $dt->month,
        day   => 10,
        )->add(months => 1);
    }
}

sub is_today_payday
{
    my ($today) = @_;

    if( $today->day == 10 || $today->day == 25 )
    {
        if( 
            $today->day_of_week != 1 && 
            $today->day_of_week != 5 && 
            $today->day_of_week != 6 
        )
        {
            return "\x0313,14Today is payday!\x03";
        }
    }   

    return 0;
}
