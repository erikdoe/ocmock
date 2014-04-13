//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import <OCMock/OCMockRecorder.h>
#import <OCMock/OCMArg.h>
#import <OCMock/OCMConstraint.h>
#import "OCClassMockObject.h"
#import "OCMInvocationMatcher.h"
#import "OCMPassByRefSetter.h"
#import "OCMReturnValueProvider.h"
#import "OCMBoxedReturnValueProvider.h"
#import "OCMExceptionReturnValueProvider.h"
#import "OCMIndirectReturnValueProvider.h"
#import "OCMNotificationPoster.h"
#import "OCMBlockCaller.h"
#import "OCMRealObjectForwarder.h"
#import "NSInvocation+OCMAdditions.h"

@interface NSObject(HCMatcherDummy)
- (BOOL)matches:(id)item;
@end

#pragma mark  -


@implementation OCMockRecorder

#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithSignatureResolver:(id)anObject
{
	signatureResolver = anObject;
    invocationMatcher = [[OCMInvocationMatcher alloc] init];
	invocationHandlers = [[NSMutableArray alloc] init];
	return self;
}

- (void)dealloc
{
    [invocationMatcher release];
	[invocationHandlers release];
	[super dealloc];
}

- (NSString *)description
{
    return [invocationMatcher description];
}

- (void)releaseInvocation
{
//	[recordedInvocation release];
//	recordedInvocation = nil;
}


- (OCMInvocationMatcher *)invocationMatcher
{
    return invocationMatcher;
}

- (NSArray *)invocationHandlers
{
    return invocationHandlers;
}


#pragma mark  Recording invocation handlers

- (void)addInvocationHandler:(id)aHandler
{
    [invocationHandlers addObject:aHandler];
}

- (id)andReturn:(id)anObject
{
	[self addInvocationHandler:[[[OCMReturnValueProvider alloc] initWithValue:anObject] autorelease]];
	return self;
}

- (id)andReturnValue:(NSValue *)aValue
{
	[self addInvocationHandler:[[[OCMBoxedReturnValueProvider alloc] initWithValue:aValue] autorelease]];
	return self;
}

- (id)andThrow:(NSException *)anException
{
	[self addInvocationHandler:[[[OCMExceptionReturnValueProvider alloc] initWithValue:anException] autorelease]];
	return self;
}

- (id)andPost:(NSNotification *)aNotification
{
	[self addInvocationHandler:[[[OCMNotificationPoster alloc] initWithNotification:aNotification] autorelease]];
	return self;
}

- (id)andCall:(SEL)selector onObject:(id)anObject
{
	[self addInvocationHandler:[[[OCMIndirectReturnValueProvider alloc] initWithProvider:anObject andSelector:selector] autorelease]];
	return self;
}

#if NS_BLOCKS_AVAILABLE

- (id)andDo:(void (^)(NSInvocation *))aBlock 
{
	[self addInvocationHandler:[[[OCMBlockCaller alloc] initWithCallBlock:aBlock] autorelease]];
	return self;
}

#endif

- (id)andForwardToRealObject
{
    [self addInvocationHandler:[[[OCMRealObjectForwarder alloc] init] autorelease]];
    return self;
}


#pragma mark  Modifying the matcher

- (id)classMethod
{
    [invocationMatcher setRecordedAsClassMethod:YES];
    [signatureResolver setupClassForClassMethodMocking];
    return self;
}

- (id)ignoringNonObjectArgs
{
    [invocationMatcher setIngoreNonObjectArgs:YES];
    return self;
}


#pragma mark  Recording the actual invocation

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if([invocationMatcher recordedAsClassMethod])
        return [[signatureResolver mockedClass] methodSignatureForSelector:aSelector];
    
    NSMethodSignature *signature = [signatureResolver methodSignatureForSelector:aSelector];
    if(signature == nil)
    {
        // if we're a working with a class mock and there is a class method, auto-switch
        if(([object_getClass(signatureResolver) isSubclassOfClass:[OCClassMockObject class]]) &&
           ([[signatureResolver mockedClass] respondsToSelector:aSelector]))
        {
            [self classMethod];
            signature = [self methodSignatureForSelector:aSelector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if([invocationMatcher recordedAsClassMethod])
        [signatureResolver setupForwarderForClassMethodSelector:[anInvocation selector]];
//	if(recordedInvocation != nil)
//		[NSException raise:NSInternalInconsistencyException format:@"Recorder received two methods to record."];
	[anInvocation setTarget:nil];
    [invocationMatcher setInvocation:anInvocation];
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    [NSException raise:NSInvalidArgumentException format:@"%@: cannot stub or expect method '%@' because no such method exists in the mocked class.", signatureResolver, NSStringFromSelector(aSelector)];
}


@end


@implementation OCMockRecorder(Properties)

@dynamic _andReturn;

- (OCMockRecorder *(^)(id))_andReturn
{
    id (^theBlock)(id) = ^ (id aValue)
    {
        return [(OCMockRecorder *)self andReturn:aValue];
    };
    return [[theBlock copy] autorelease];
}


@dynamic _andDo;

- (OCMockRecorder *(^)(void (^)(NSInvocation *)))_andDo
{
    id (^theBlock)(void (^)(NSInvocation *)) = ^ (void (^ blockToCall)(NSInvocation *))
    {
        return [(OCMockRecorder *)self andDo:blockToCall];
    };
    return [[theBlock copy] autorelease];
}


@end
