//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004,2005 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMockObject.h"
#import "OCClassMockObject.h"
#import "OCProtocolMockObject.h"
#import "OCMockRecorder.h"


@implementation OCMockObject

//---------------------------------------------------------------------------------------
//  factory methods
//---------------------------------------------------------------------------------------

+ (id)mockForClass:(Class)aClass
{
	return [[[OCClassMockObject alloc] initWithClass:aClass] autorelease];
}


+ (id)mockForProtocol:(Protocol *)aProtocol
{
	return [[[OCProtocolMockObject alloc] initWithProtocol:aProtocol] autorelease];
}


//---------------------------------------------------------------------------------------
//  init and dealloc
//---------------------------------------------------------------------------------------

- (id)init
{
	recorders = [[NSMutableArray alloc] init];
	expectations = [[NSMutableSet alloc] init];
	return self;
}

- (void)dealloc
{
	[recorders release];
	[expectations release];
	[super dealloc];
}

//---------------------------------------------------------------------------------------
// description override
//---------------------------------------------------------------------------------------

- (NSString *)description
{
	return @"OCMockObject";
}


//---------------------------------------------------------------------------------------
//  public api
//---------------------------------------------------------------------------------------

- (id)stub
{
	OCMockRecorder *recorder = [[[OCMockRecorder alloc] initWithSignatureResolver:self] autorelease];
	[recorders addObject:recorder];
	return recorder;
}


- (id)expect
{
	OCMockRecorder *recorder = [self stub];
	[expectations addObject:recorder];
	return recorder;
}


- (void)verify
{
	if([expectations count] == 1)
	{
		[NSException raise:NSInternalInconsistencyException format:@"Did not call expected method [%@ %@]", [self description], [[expectations anyObject] description]];
	}
	else if([expectations count] > 1)
	{
		[NSException raise:NSInternalInconsistencyException format:@"Did not call %d expected methods on %@", [expectations count], [self description]];
	}
}


//---------------------------------------------------------------------------------------
//  proxy api
//---------------------------------------------------------------------------------------

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	OCMockRecorder *recorder;
	int			   i;

	for(i = 0; i < [recorders count]; i++)
	{
		recorder = [recorders objectAtIndex:i];
		if([recorder matchesInvocation:anInvocation])
		{
			[expectations removeObject:recorder];
			[recorder setUpReturnValue:anInvocation];
			return;
		}
	}
	
	[NSException raise:NSInternalInconsistencyException format:@"Unexpected method or arguments [%@ %@]", [self description], NSStringFromSelector([anInvocation selector])];
}


@end
