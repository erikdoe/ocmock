//---------------------------------------------------------------------------------------
//  $Id: OCObserverMockObject.m $
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCObserverMockObject.h"
#import "OCMObserverRecorder.h"


@implementation OCObserverMockObject

//---------------------------------------------------------------------------------------
//  init and dealloc
//---------------------------------------------------------------------------------------

- (id)init
{
	[super init];
	recorders = [[NSMutableArray alloc] init];
	return self;
}

- (void)dealloc
{
	[recorders release];
	[super dealloc];
}


//---------------------------------------------------------------------------------------
// description override
//---------------------------------------------------------------------------------------

- (NSString *)description
{
	return @"OCMockObserver";
}


//---------------------------------------------------------------------------------------
//  public api
//---------------------------------------------------------------------------------------

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
		[NSException raise:NSInternalInconsistencyException format:@"%@ : %d expected notifications were not observed.", 
		 [self description], [recorders count]];
	}
}


//---------------------------------------------------------------------------------------
//  receiving notifications
//---------------------------------------------------------------------------------------

- (void)handleNotification:(NSNotification *)aNotification
{
	int i;
	
	for(i = 0; i < [recorders count]; i++)
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
