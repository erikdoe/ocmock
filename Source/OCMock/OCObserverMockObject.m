//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCObserverMockObject.h"
#import "OCMObserverRecorder.h"
#import "NSException+OCMAdditions.h"
#import <OCMock/OCMFailureHandler.h>


@implementation OCObserverMockObject

#pragma mark  Initialisers, description, accessors, etc.

- (id)init
{
	self = [super init];
	failureHandler = nil;
	recorders = [[NSMutableArray alloc] init];
	return self;
}

- (void)dealloc
{
	[failureHandler release];
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

- (void)setFailureHandler:(id<OCMFailureHandler>)handler {
	if(handler != failureHandler)
	{
		[failureHandler release];
		failureHandler = [handler retain];
	}
}


#pragma mark  Public API

- (id)expectInFile:(NSString *)filename atLine:(int)lineNumber
{
	OCMObserverRecorder *recorder = [[[OCMObserverRecorder alloc] init] autorelease];
	recorder.file = filename;
	recorder.line = lineNumber;
	[recorders addObject:recorder];
	return recorder;
}

- (void)verify
{
	if(!failureHandler)
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
	else
	{
		for(OCMObserverRecorder *recorder in recorders)
		{
			[failureHandler failWithException:[NSException failureInObserverRecorder:recorder withDescription:@"%@: expected notification was not observed: %@",
											   [self description], [recorder description]]];
		}
	}
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
