//
//  Utils.m
//  GCDTutorial
//
//  Created by A Magical Unicorn on A Sunday Night.
//  Copyright (c) 2014 Derek Selander. All rights reserved.
//

#import "Utils.h"
#import <UIKit/UIKit.h>
NSString *const kPhotoManagerAddedContentNotification = @"com.selander.GooglyPuff.PhotoManagerAddedContent";
NSString *const kPhotoManagerContentUpdateNotification = @"com.selander.GooglyPuff.PhotoMangerContentUpdate";
NSString *const kOverlyAttachedGirlfriendURLString = @"http://img31.mtime.cn/pi/2013/11/12/161435.75516336_1000X1000.jpg";
NSString *const kSuccessKidURLString = @"http://img31.mtime.cn/pi/2013/11/12/161434.21194159_1000X1000.jpg";
NSString *const kLotsOfFacesURLString = @"http://img31.mtime.cn/pi/2013/11/12/161433.15986377_1000X1000.jpg";

typedef void (^PhotoDownloadingProgressBlock)(NSUInteger completed, NSUInteger total);
@implementation Utils

+ (UIColor *)defaultBackgroundColor
{
    return [UIColor colorWithRed:236.0f/255.0f
                           green:254.0f/255.0f
                            blue:255.0f/255.0f
                           alpha:1.0f];
}

BOOL isIpad()
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return NO;
}

//*****************************************************************************/
#pragma mark - One shot Profiling
//*****************************************************************************/

static NSDate *getSharedStartDate(BOOL shouldReset) {
    static NSDate *shareStartDate = nil;
    if (shouldReset) {
        shareStartDate = [NSDate date];
    }
    return shareStartDate;
}
+ (void)startTimeProfiling
{
    getSharedStartDate(YES);
}

+ (void)stopTimeProfiling
{
    NSArray *frames = [NSThread callStackSymbols];
    NSTimeInterval totalTime = [[NSDate date] timeIntervalSinceDate:getSharedStartDate(NO)];
    NSLog(@"%@, \n**************************** total time: %@", frames[1], @(totalTime));
}

@end
