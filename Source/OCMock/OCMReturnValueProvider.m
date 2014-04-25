//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "NSMethodSignature+OCMAdditions.h"
#import "OCMReturnValueProvider.h"
#import "OCMFunctions.h"


@implementation OCMReturnValueProvider

- (id)initWithValue:(id)aValue
{
	self = [super init];
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
    if(!OCMIsObjectType([[anInvocation methodSignature] methodReturnType]))
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Expected invocation with object return type. Did you mean to use andReturnValue: instead?" userInfo:nil];
    }
    NSString *sel = NSStringFromSelector([anInvocation selector]);
    if([sel hasPrefix:@"alloc"] || [sel hasPrefix:@"new"] || [sel hasPrefix:@"copy"] || [sel hasPrefix:@"mutableCopy"])
    {
        // methods that "create" an object return it with an extra retain count
        [returnValue retain];
    }
	[anInvocation setReturnValue:&returnValue];
}

@end
