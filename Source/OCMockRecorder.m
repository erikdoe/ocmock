//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMockRecorder.h"


@implementation OCMockRecorder

//---------------------------------------------------------------------------------------
//  factory methods
//---------------------------------------------------------------------------------------

+ (id)anyArgument
{
	return @"ANY";  // we're testing for pointer equality so anything unique will do
}


//---------------------------------------------------------------------------------------
//  init and dealloc
//---------------------------------------------------------------------------------------

- (id)initWithSignatureResolver:(NSObject *)anObject
{
	signatureResolver = anObject;
	return self;
}


- (void)dealloc
{
	[recordedInvocation release];
	[returnValue release];
	[super dealloc];
}


//---------------------------------------------------------------------------------------
//  description
//---------------------------------------------------------------------------------------

- (NSString *)description
{
	return NSStringFromSelector([recordedInvocation selector]);
}


//---------------------------------------------------------------------------------------
//  recording
//---------------------------------------------------------------------------------------

- (id)andReturn:(id)anObject
{
	returnValue = [anObject retain];
	return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [signatureResolver methodSignatureForSelector:aSelector];
}


- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	if(recordedInvocation != nil)
		[NSException raise:NSInternalInconsistencyException format:@"Recorder received two methods to record."];
	[anInvocation retainArguments];
	recordedInvocation = [anInvocation retain];
}


//---------------------------------------------------------------------------------------
//  verification and return values
//---------------------------------------------------------------------------------------

- (void)_assertIsObject:(const char *)aType
{
	if(strcmp(aType, @encode(id)) != 0)
		[NSException raise:NSInvalidArgumentException format:@"Can only handle object arguments."];
}


- (BOOL)matchesInvocation:(NSInvocation *)anInvocation
{
	id  recordedArg, passedArg;
	int i, n;
	
	if([anInvocation selector] != [recordedInvocation selector])
		return NO;
	
	n = [[recordedInvocation methodSignature] numberOfArguments];
	for(i = 2; i < n; i++)
	{
		[self _assertIsObject:[[recordedInvocation methodSignature] getArgumentTypeAtIndex:i]];
		[recordedInvocation getArgument:&recordedArg atIndex:i];
		if(recordedArg != OCMOCK_ANY)
		{
			[self _assertIsObject:[[anInvocation methodSignature] getArgumentTypeAtIndex:i]];
			[anInvocation getArgument:&passedArg atIndex:i];
			if([recordedArg isEqual:passedArg] == NO)
				return NO;
		}
	}
	return YES;
}


- (void)setUpReturnValue:(NSInvocation *)anInvocation
{
	if(strcmp([[anInvocation methodSignature] methodReturnType], @encode(id)) == 0)
		[anInvocation setReturnValue:&returnValue];	
}

@end
