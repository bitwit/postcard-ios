//
// Created by Kyle Newsome on 2013-06-11.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

//


#import "NSDate+RelativeTime.h"


@implementation NSDate (RelativeTime)

- (NSString *)relativeDateString
{
    const int SECOND = 1;
    const int MINUTE = 60 * SECOND;
    const int HOUR = 60 * MINUTE;
    const int DAY = 24 * HOUR;
    const int MONTH = 30 * DAY;

    NSDate *now = [NSDate date];
    NSTimeInterval delta = [self timeIntervalSinceDate:now] * -1.0;

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger units = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit);
    NSDateComponents *components = [calendar components:units fromDate:self toDate:now options:0];

    NSString *relativeString;

    if (delta < 0) {
        relativeString = NSLocalizedString(@"In the future", nil);
    } else if (delta < 1 * MINUTE) {
        relativeString = (components.second == 1) ? NSLocalizedString(@"1 second ago", nil) : [NSString stringWithFormat:NSLocalizedString(@"%d seconds ago", @"{{number}} seconds ago"), components.second];
    } else if (delta < 2 * MINUTE) {
        relativeString =  NSLocalizedString(@"1 minute ago", nil);
    } else if (delta < 45 * MINUTE) {
        relativeString = [NSString stringWithFormat:NSLocalizedString(@"%d minutes ago", @"{{number}} minutes ago"),components.minute];
    } else if (delta < 90 * MINUTE) {
        relativeString = NSLocalizedString(@"1 hour ago", nil);
    } else if (delta < 24 * HOUR) {
        relativeString = [NSString stringWithFormat:NSLocalizedString(@"%d hours ago", @"{{number}} hours ago"),components.hour];
    } else if (delta < 48 * HOUR) {
        relativeString = NSLocalizedString(@"yesterday", nil);
    } else if (delta < 30 * DAY) {
        relativeString = [NSString stringWithFormat:NSLocalizedString(@"%d days ago", @"{{number}} days ago"), components.day];
    } else if (delta < 12 * MONTH) {
        relativeString = (components.month <= 1) ? NSLocalizedString(@"1 month ago", nil) : [NSString stringWithFormat:NSLocalizedString(@"%d months ago", @"{{number}} months ago"), components.month];
    } else {
        relativeString = (components.year <= 1) ? NSLocalizedString(@"1 year ago", nil) : [NSString stringWithFormat:NSLocalizedString(@"%d years ago", @"{{number}} years ago"), components.year];
    }
    return relativeString;
}

@end