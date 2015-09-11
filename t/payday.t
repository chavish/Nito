#! /usr/local/cpanel/3rdparty/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';
use DateTime;

require './payday.pl';

my $dt = DateTime->today;

my %test_values = (
    mon_10    => { dt=>{ year => 2015, month => 8, day => 10 }, payday => 1, holiday => 0, offset => 2, expected_day => 6, },
    mon_25    => { year => 2015, month => 5, day => 25 },
    sat_10    => { year => 2015, month => 1, day => 10 },
    sat_25    => { year => 2015, month => 7, day => 25 },
    sun_10    => { year => 2015, month => 5, day => 10 },
    sun_25    => { year => 2015, month => 1, day => 25 },
    tue_xmas  => { year => 2018, month => 12, day => 25 },
    wed_xmas  => { year => 2019, month => 12, day => 25 },
    thu_xmas  => { year => 2014, month => 12, day => 25 },
    fri_xmas  => { year => 2020, month => 12, day => 25 },
#    thu_thx   => { year => 2021, month => 11, day => 25 },
#    fri_thx   => { year => 2022, month => 11, day => 25 },
    
);

foreach my $key (keys %test_values)
{
    my $dt = DateTime->new(%{ $test_values{$key}->{dt} });
    my $result = adjust_for_dayoff($dt);
    my ($day, $date) = split/_/, $key;
    dispatch_ok($day, $date, $result);
}

sub dispatch_ok
{
    my ($day, $date, $result) = @_;

    if($day eq 'mon')
    {
        _ok_mon($date, $result);
    }
    if($day eq 'sat')
    {
        _ok_sat($date, $result);
    }
    if($day eq 'sun')
    {
        _ok_sun($date, $result);
    }
    if($date eq 'xmas')
    {
        _ok_xmas($day, $result);
    }
    if($date eq 'thx')
    {
        _ok_thx($day, $result);
    }

}

sub _ok_xmas
{
    my ($day, $result) = @_;
    my $date = 25;
    my $days_past = 1;
    my @days = qw/mon tue wed thu fri sat sun/;
    ($day) = grep { $days[$_] eq $day } 0..$#days;
    $day++;

    my $actual_date = $date - $days_past;
    my $actual_day = $day - $days_past;

    is($result->day_of_week, $actual_day, "Day of the week matched $actual_day.");
    is($result->day, $actual_date, "$date converts to $actual_date.");
}


sub _ok_thx
{
    my ($day, $result) = @_;
    my $days_past;
    my $date = 25;

    if($day eq 'thu')
    {
        $days_past = 1;
        $day = 4;
    }elsif($day eq 'fri')
    {
        $days_past = 2;
        $day = 5;
    }else{
        print "Something went very wrong!!!\n";
    }

    my $actual_date = $date - $days_past;

    is($result->day_of_week, $day, "Found DAY: $day in thxgvng.");
    is($result->day, $actual_date, "$date converts to $actual_date.");
}


sub _ok_mon
{
    my ($date, $result) = @_;
    my $days_past = 2;
    my $actual_date = $date - $days_past;

    is($result->day_of_week, 6, "Monday converts Saturday.");
    is($result->day, $actual_date, "$date converts to $actual_date.");
}

sub _ok_sat
{
    my ($date, $result) = @_;
    my $days_past = 1;
    my $actual_date = $date - $days_past;

    is($result->day_of_week, 5, "Saturday converts to Friday.");
    is($result->day, $actual_date, "$date converts to $actual_date.");
}

sub _ok_sun
{
    my ($date, $result) = @_;
    my $days_past = 2;
    my $actual_date = $date - $days_past;

    is($result->day_of_week, 5, "Sunday converts Friday.");
    is($result->day, $actual_date, "$date converts to $actual_date.");
}
