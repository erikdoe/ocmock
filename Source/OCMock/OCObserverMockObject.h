//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class OCMLocation;


@interface OCObserverMockObject : NSObject 
{
	BOOL		    expectationOrderMatters;
	NSMutableArray  *recorders;
    NSMutableArray  *centers;
}

- (void)setExpectationOrderMatters:(BOOL)flag;

- (id)expect;

- (void)verify;
- (void)verifyAtLocation:(OCMLocation *)location;

- (void)handleNotification:(NSNotification *)aNotification;

// internal use

- (void)autoRemoveFromCenter:(NSNotificationCenter *)aCenter;
- (void)notificationWithName:(NSString *)name object:(id)sender;

@end
