//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMBoxedReturnValueProvider.h"


@implementation OCMBoxedReturnValueProvider

- (void)handleInvocation:(NSInvocation *)anInvocation
{
	if(strcmp([[anInvocation methodSignature] methodReturnType], [(NSValue *)returnValue objCType]) != 0)
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Return value does not match method signature; signature declares '%s' but value is '%s'.", [[anInvocation methodSignature] methodReturnType], [(NSValue *)returnValue objCType]] userInfo:nil];
	void *buffer = malloc([[anInvocation methodSignature] methodReturnLength]);
	[returnValue getValue:buffer];
	[anInvocation setReturnValue:buffer];
	free(buffer);
}

@end
