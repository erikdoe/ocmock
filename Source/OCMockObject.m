//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMockObject.h"
#import "OCMockRecorder.h"


@implementation OCMockObject

//---------------------------------------------------------------------------------------
//  factory methods
//---------------------------------------------------------------------------------------

+ (id)mockForClass:(Class)aClass
{
	return [[[[self class] alloc] initWithClass:aClass] autorelease];
}


//---------------------------------------------------------------------------------------
//  init and dealloc
//---------------------------------------------------------------------------------------

- (id)initWithClass:(Class)aClass
{
	mockedClass = aClass;
	recordedInvocations = [[NSMutableArray alloc] init];
	expectedInvocations = [[NSMutableSet alloc] init];
	return self;
}

- (void)dealloc
{
	[recordedInvocations release];
	[expectedInvocations release];
	[super dealloc];
}


//---------------------------------------------------------------------------------------
//  public api
//---------------------------------------------------------------------------------------

- (id)stub
{
	OCMockRecorder *recorder = [[[OCMockRecorder alloc] initWithClass:mockedClass] autorelease];
	[recordedInvocations addObject:recorder];
	return recorder;
}


- (id)expect
{
	OCMockRecorder *recorder = [self stub];
	[expectedInvocations addObject:recorder];
	return recorder;
}


- (void)verify
{
	if([expectedInvocations count] == 1)
	{
		[NSException raise:NSInternalInconsistencyException format:@"Did not call expected method [OCMockObject{%@} %@]", NSStringFromClass(mockedClass), expectedInvocations];
	}
	else if([expectedInvocations count] > 1)
	{
		[NSException raise:NSInternalInconsistencyException format:@"Did not call %d expected methods", [expectedInvocations count]];
	}
}


//---------------------------------------------------------------------------------------
//  proxy api
//---------------------------------------------------------------------------------------

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [mockedClass instanceMethodSignatureForSelector:aSelector];
}


- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	OCMockRecorder *stubbedInvocation;
	int			   i;

	for(i = 0; i < [recordedInvocations count]; i++)
	{
		stubbedInvocation = [recordedInvocations objectAtIndex:i];
		if([stubbedInvocation matchesInvocation:anInvocation])
		{
			[expectedInvocations removeObject:stubbedInvocation];
			[stubbedInvocation setUpReturnValue:anInvocation];
			return;
		}
	}
	
	[NSException raise:NSInternalInconsistencyException format:@"Unexpected method or arguments [OCMockObject{%@} %@]", NSStringFromClass(mockedClass), NSStringFromSelector([anInvocation selector])];
}


@end
