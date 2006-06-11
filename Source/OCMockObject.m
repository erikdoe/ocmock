//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004,2005 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMockObject.h"
#import "OCClassMockObject.h"
#import "OCProtocolMockObject.h"
#import "OCMockRecorder.h"
#import "NSInvocation+OCMAdditions.h"

@interface OCMockObject(Private)
- (NSString *)_recorderDescriptions:(BOOL)onlyExpectations;
@end

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
		[NSException raise:NSInternalInconsistencyException format:@"%@: expected method was not invoked: %@", 
			[self description], [[expectations anyObject] description]];
	}
	else if([expectations count] > 0)
	{
		[NSException raise:NSInternalInconsistencyException format:@"%@ : %d expected methods were not invoked: %@", 
			[self description], [expectations count], [self _recorderDescriptions:YES]];
	}
}


//---------------------------------------------------------------------------------------
//  proxy api
//---------------------------------------------------------------------------------------

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	OCMockRecorder *recorder;
	int			   i;

	NSMutableArray *mutableRecorders = [[NSMutableArray alloc] initWithArray:recorders];
	
	for(i = 0; i < [mutableRecorders count]; i++)
	{
		recorder = [mutableRecorders objectAtIndex:i];

		if(![recorder matchesInvocation:anInvocation])
			continue;

		// If there's a matching expectation... remove it and the corresponding recorder (as it's not a stub)
		if ([expectations containsObject:recorder])
		{
			[expectations removeObject:recorder];
			[mutableRecorders removeObjectAtIndex:i];
		}

		// Also remove the recorder (for expectations and stubs)
		[recorder setUpReturnValue:anInvocation];
		
		[recorders release];
		recorders = [[NSArray alloc] initWithArray:mutableRecorders];
		[mutableRecorders release];
		
		return;
	}

	[NSException raise:NSInternalInconsistencyException format:@"%@: unexpected method invoked: %@ %@", 
		[self description], [anInvocation invocationDescription], [self _recorderDescriptions:NO]];
}


//---------------------------------------------------------------------------------------
//  descriptions
//---------------------------------------------------------------------------------------

- (NSString *)_recorderDescriptions:(BOOL)onlyExpectations
{
	NSMutableString *outputString = [NSMutableString string];
	
	OCMockRecorder *currentObject;
	NSEnumerator *recorderEnumerator = [recorders objectEnumerator];
	while(currentObject = [recorderEnumerator nextObject])
	{
		NSString *prefix;
		
		if(onlyExpectations)
		{
			if(![expectations containsObject:currentObject])
				continue;
			prefix = @" ";
		}
		else
		{
			if ([expectations containsObject:currentObject])
				prefix = @"expected: ";
			else
				prefix = @"stubbed: ";
		}
		[outputString appendFormat:@"\n\t%@\t%@", prefix, [currentObject description]];
	}
	
	return outputString;
}


@end
