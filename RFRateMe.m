//
//  RFRateMe.m
//  RFRateMeDemo
//
//  Created by Ricardo Funk on 1/2/14.
//  Copyright (c) 2014 Ricardo Funk. All rights reserved.
//

#import "RFRateMe.h"
#import "UIAlertView+NSCookbook.h"

#define kNumberOfDaysUntilShowAgain 3
#define kAppStoreAddress @"https://itunes.apple.com/us/app/postcard-write-once-share/id589678038?ls=1&mt=8"
#define kAppName @"Postcard"

@implementation RFRateMe

+(void)showRateAlert {

    //If rate was completed, we just return if True
    BOOL rateCompleted = [[NSUserDefaults standardUserDefaults] boolForKey:@"RateCompleted"];
    if (rateCompleted) {
        BWLog(@"Rate completed or dismissed for good");
        return;
    }

    //Check if the user asked not to be prompted again for 3 days (remind me later)
    BOOL remindMeLater = [[NSUserDefaults standardUserDefaults] boolForKey:@"RemindMeLater"];

    if (remindMeLater) {

        NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
        [DateFormatter setDateFormat:@"yyyy-MM-dd"];

        NSString *start = [[NSUserDefaults standardUserDefaults] objectForKey:@"StartDate"];
        NSString *end = [DateFormatter stringFromDate:[NSDate date]];

        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        [f setDateFormat:@"yyyy-MM-dd"];
        NSDate *startDate = [f dateFromString:start];
        NSDate *endDate = [f dateFromString:end];

        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [gregorianCalendar components:NSDayCalendarUnit
                                                            fromDate:startDate
                                                              toDate:endDate
                                                             options:0];

        if ((long)[components day] <= kNumberOfDaysUntilShowAgain){
            BWLog(@"Reminding user to rate later...");
            return;
        }

    }

    //Show rate alert
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Please rate %@", kAppName]
                                                        message:[NSString stringWithFormat:@"If you enjoy %@, would you mind taking one minute to rate it? Thanks for your support!", kAppName]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Never ask me again", @"")
                                              otherButtonTitles:NSLocalizedString(@"Rate it now", @""),NSLocalizedString(@"Remind me later",@""), nil];

    [alertView showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {

        switch (buttonIndex) {
            case 0:

                NSLog(@"No, thanks");
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"RateCompleted"];
                [[NSUserDefaults standardUserDefaults] synchronize];

                break;
            case 1:

                NSLog(@"Rate it now");
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"RateCompleted"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kAppStoreAddress]];

                break;
            case 2:

                NSLog(@"Remind me later");
                NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd"];
                NSDate *now = [NSDate date];
                [[NSUserDefaults standardUserDefaults] setObject:[dateFormatter stringFromDate:now] forKey:@"StartDate"];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"RemindMeLater"];
                [[NSUserDefaults standardUserDefaults] synchronize];

                break;
        }
    }];
}

@end