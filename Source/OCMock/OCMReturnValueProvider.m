//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "NSMethodSignature+OCMAdditions.h"
#import "OCMReturnValueProvider.h"


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
	const char *returnType = [[anInvocation methodSignature] methodReturnTypeWithoutQualifiers];
	if(strcmp(returnType, @encode(id)) != 0) {
        // if the returnType is a typedef to an object, it has the form ^{OriginalClass=#}
        NSString *regexString= @"^\\^\\{(.*)=#\\}";
        NSError *error= nil;
        NSRegularExpression *regex= [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:&error];
        NSString *type= [NSString stringWithCString:returnType encoding:NSASCIIStringEncoding];
        NSUInteger match= [regex numberOfMatchesInString:type options:0 range:NSMakeRange(0, type.length)];
        if(!match) {
            // it's no typedef to an class and no class itself
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Expected invocation with object return type. Did you mean to use andReturnValue: instead?" userInfo:nil];
        }
    }
	[anInvocation setReturnValue:&returnValue];
}

@end
