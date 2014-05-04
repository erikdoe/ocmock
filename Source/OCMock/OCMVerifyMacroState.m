//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMVerifyMacroState.h"
#import "OCMInvocationMatcher.h"
#import "OCMLocation.h"
#import "OCMockObject.h"


@implementation OCMVerifyMacroState

- (id)initWithLocation:(OCMLocation *)aLocation
{
    self = [super init];
    location = aLocation;
    return self;
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
    OCMockObject *mock = [anInvocation target];
    [anInvocation setTarget:nil];
    OCMInvocationMatcher *matcher = [[[OCMInvocationMatcher alloc] init] autorelease];
    [matcher setInvocation:anInvocation];
    [mock verifyInvocation:matcher atLocation:location];
}

@end
