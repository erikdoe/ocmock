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

- (id)_extractArgument: (NSInvocation*)anInvocation atIndex:(int)index
{
	const char* argType;
	
	argType = [[anInvocation methodSignature] getArgumentTypeAtIndex:index];
	if(strlen(argType) > 1) 
		[NSException raise:NSInvalidArgumentException format:@"Can only handle object and simple scalar arguments."];
	
	switch (argType[0]) 
	{
		case '#':
		case ':':
		case '@': 
		{
			id value;
			[anInvocation getArgument:&value atIndex:index];
			return value;
		}
		case 'i': 
		{
			int value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithInt:value];
		}	
		case 's':
		{
			short value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithShort:value];
		}	
		case 'l':
		{
			long value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithLong:value];
		}	
		case 'q':
		{
			long long value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithLongLong:value];
		}	
		case 'c':
		{
			char value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithChar:value];
		}	
		case 'C':
		{
			unsigned char value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithUnsignedChar:value];
		}	
		case 'I':
		{
			unsigned int value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithUnsignedInt:value];
		}	
		case 'S':
		{
			unsigned short value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithUnsignedShort:value];
		}	
		case 'L':
		{
			unsigned long value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithUnsignedLong:value];
		}	
		case 'Q':
		{
			unsigned long long value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithUnsignedLongLong:value];
		}	
		case 'f':
		{
			float value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithFloat:value];
		}	
		case 'd':
		{
			double value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithDouble:value];
		}	
		case 'B':
		{
			bool value;
			[anInvocation getArgument:&value atIndex:index];
			return [NSNumber numberWithBool:value];
		}
	}
	[NSException raise:NSInvalidArgumentException format:@"Argument type '%s' not supported", argType];
	return nil;
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
		recordedArg = [self _extractArgument:recordedInvocation atIndex:i];
		if(recordedArg != OCMOCK_ANY)
		{
			passedArg = [self _extractArgument:anInvocation atIndex:i];
			if([recordedArg class] != [passedArg class])
				return NO;
			if(([recordedArg class] == [NSNumber class]) && 
				([(NSNumber*)recordedArg compare:(NSNumber*)passedArg] != NSOrderedSame))
				return NO;
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
