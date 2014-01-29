//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class OCMockObserver;


@interface NSNotificationCenter(OCMAdditions)

/**
 adds a mock observer for the given notification
 @discussion This method is a convenience for setting up a mock observer by telling the notification center to call a certain selector on the mock.
 @param notificationObserver the mock observer to register
 @param notificationName the notification to observe
 @param notificationSender the sender to observe
 */
- (void)addMockObserver:(OCMockObserver *)notificationObserver name:(NSString *)notificationName object:(id)notificationSender;

@end
