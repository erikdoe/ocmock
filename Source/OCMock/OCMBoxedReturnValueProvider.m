//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMBoxedReturnValueProvider.h"
#import <objc/runtime.h>

@implementation OCMBoxedReturnValueProvider

- (void)handleInvocation:(NSInvocation *)anInvocation
{
	const char *returnType = [[anInvocation methodSignature] methodReturnType];
	const char *valueType = [(NSValue *)returnValue objCType];

	BOOL typesAreNotEqual = strcmp(returnType, valueType) != 0;
	// It's impossible to rely on the implementation of NSNumber, which may internally represent a different type than the given one upon construction.
	BOOL valueIsNotNSNumber = ![returnValue isKindOfClass:[NSNumber class]];

	if(typesAreNotEqual && valueIsNotNSNumber)
	{
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Return value does not match method signature; signature declares '%s' but value is '%s'.", returnType, valueType] userInfo:nil];
	}
	void *buffer = malloc([[anInvocation methodSignature] methodReturnLength]);
	[returnValue getValue:buffer];
	[anInvocation setReturnValue:buffer];
	free(buffer);
}

@end
