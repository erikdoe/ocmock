//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMReturnValueProvider.h"


@implementation OCMReturnValueProvider

- (id)initWithValue:(id)aValue
{
	[super init];
	returnValue = [aValue retain];
	return self;
}

- (void)dealloc
{
	[returnValue release];
	[super dealloc];
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
	const char *returnType = [[anInvocation methodSignature] methodReturnType];
	const char *returnTypeWithoutQualifiers = returnType + (strlen(returnType) - 1);
	if(strcmp(returnTypeWithoutQualifiers, @encode(id)) != 0)
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Expected invocation with object return type." userInfo:nil];
	[anInvocation setReturnValue:&returnValue];	
}

@end
