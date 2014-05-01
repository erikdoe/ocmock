//---------------------------------------------------------------------------------------
//  Copyright (c) 20014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMVerifier.h"
#import "OCMockObject.h"
#import "OCMInvocationMatcher.h"


@implementation OCMVerifier

- (id)initWithMockObject:(OCMockObject *)aMockObject
{
    // no super, we're inheriting from NSProxy
    mockObject = aMockObject;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [mockObject methodSignatureForSelector:aSelector];
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation setTarget:nil];
    OCMInvocationMatcher *matcher = [[[OCMInvocationMatcher alloc] init] autorelease];
    [matcher setInvocation:anInvocation];
    [mockObject verifyInvocation:matcher];
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    [NSException raise:NSInvalidArgumentException format:@"%@: cannot stub or expect method '%@' because no such method exists in the mocked class.", mockObject, NSStringFromSelector(aSelector)];
}



@end
