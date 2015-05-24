//
//  Functions.h
//  AppRewardsClub
//
//  Created by Kyle Newsome on 12-03-26.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//#define DEBUG_NETWORK_LOG 1

#ifdef DEBUG
    #define TESTFLIGHT_ENABLED 1
#endif

//#ifdef TESTFLIGHT_ENABLED
//    #import "TestFlight.h"
//    #define BWLog(fmt, ...) TFLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//    #define BWNetLog(fmt, ...) TFLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//#else
    #define BWLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
    //#define BWLog(...);
    #define BWNetLog(...);
//#endif

/*
 iPhone 5+ detection
 */
#define IS_TALL_IPHONE ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) == 0 )

/**
 * boolAsString()
 */
NSString * boolAsString(BOOL var);
