package CpHolidays;


sub is_cp_holiday
{
    my ($dt) = @_;

    return 0 unless is_holiday_month($dt);

    return 1 if $dt->month == 12 and $dt->day == 25; 
    
    if($dt->month == 5)
    {
        # Memorial Day
        return 0 unless $dt->day_of_week == 1;
        return 1 if $dt->week_of_month >= 4;
        return 0;
    }

    if($dt->month == 11)
    {
        return 0 unless $dt->week_of_month == 4;
        return 1 if $dt->day_of_week == 4 || $dt->day_of_week == 5;
        return 0;

    }
    
    return 0;
}


sub is_holiday_month
{
    my ($dt) = @_;

    return 1 if $dt->month == 5; 
    return 1 if $dt->month == 11; 
    return 1 if $dt->month == 12;

    return 0;
}


1;
