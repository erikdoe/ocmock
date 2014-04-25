//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009-2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCObserverMockObject.h"
#import "OCMObserverRecorder.h"
#import "OCMLocation.h"
#import "OCMFunctions.h"


@implementation OCObserverMockObject

#pragma mark  Initialisers, description, accessors, etc.

- (id)init
{
	self = [super init];
	recorders = [[NSMutableArray alloc] init];
	centers = [[NSMutableArray alloc] init];
	return self;
}

- (id)retain
{
    return [super retain];
}

- (void)dealloc
{
    for(NSNotificationCenter *c in centers)
        [c removeObserver:self];
    [centers release];
	[recorders release];
	[super dealloc];
}

- (NSString *)description
{
	return @"OCMockObserver";
}

- (void)setExpectationOrderMatters:(BOOL)flag
{
    expectationOrderMatters = flag;
}

- (void)autoRemoveFromCenter:(NSNotificationCenter *)aCenter
{
    [centers addObject:aCenter];
}


#pragma mark  Public API

- (id)expect
{
	OCMObserverRecorder *recorder = [[[OCMObserverRecorder alloc] init] autorelease];
	[recorders addObject:recorder];
	return recorder;
}

- (void)verify
{
	if([recorders count] == 1)
	{
		[NSException raise:NSInternalInconsistencyException format:@"%@: expected notification was not observed: %@",
		 [self description], [[recorders lastObject] description]];
	}
	if([recorders count] > 0)
	{
		[NSException raise:NSInternalInconsistencyException format:@"%@ : %@ expected notifications were not observed.", 
		 [self description], @([recorders count])];
	}
}

- (void)verifyAtLocation:(OCMLocation *)location
{
    if([recorders count] == 1)
    {
        NSString *description = [NSString stringWithFormat:@"%@: expected notification was not observed: %@",
         [self description], [[recorders lastObject] description]];
        OCMReportFailure(location, description);
    }
    else if([recorders count] > 0)
    {
        NSString *description = [NSString stringWithFormat:@"%@ : %@ expected notifications were not observed.",
         [self description], @([recorders count])];
        OCMReportFailure(location, description);
    }
}


#pragma mark  Receiving recording requests via macro

- (void)notificationWithName:(NSString *)name object:(id)sender
{
    [[self expect] notificationWithName:name object:sender];
}


#pragma mark  Receiving notifications

- (void)handleNotification:(NSNotification *)aNotification
{
	NSUInteger i, limit;
	
	limit = expectationOrderMatters ? 1 : [recorders count];
	for(i = 0; i < limit; i++)
	{
		if([[recorders objectAtIndex:i] matchesNotification:aNotification])
		{
			[recorders removeObjectAtIndex:i];
			return;
		}
	}
	[NSException raise:NSInternalInconsistencyException format:@"%@: unexpected notification observed: %@", [self description], 
	  [aNotification description]];
}


@end
