//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009-2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import "OCMockObject.h"
#import "OCPartialMockObject.h"
#import "NSMethodSignature+OCMAdditions.h"
#import "NSObject+OCMAdditions.h"
#import "OCMFunctions.h"


@implementation OCPartialMockObject

#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithObject:(NSObject *)anObject
{
    [self assertClassIsSupported:[anObject class]];
	[super initWithClass:[anObject class]];
	realObject = [anObject retain];
    [self prepareObjectForInstanceMethodMocking];
	return self;
}

- (void)dealloc
{
	[self stopMocking];
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"OCPartialMockObject[%@]", NSStringFromClass(mockedClass)];
}

- (NSObject *)realObject
{
	return realObject;
}

#pragma mark  Helper methods

- (void)assertClassIsSupported:(Class)class
{
    NSString *classname = NSStringFromClass(class);
    NSString *reason = nil;
    if([classname hasPrefix:@"__NSTagged"])
        reason = [NSString stringWithFormat:@"OCMock does not support partially mocking tagged classes; got %@", classname];
    else if([classname hasPrefix:@"__NSCF"])
        reason = [NSString stringWithFormat:@"OCMock does not support partially mocking toll-free bridged classes; got %@", classname];

    if(reason != nil)
        [[NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil] raise];
}


#pragma mark  Extending/overriding superclass behaviour

- (void)stopMocking
{
    if(realObject != nil)
    {
        OCMSetAssociatedMockForObject(nil, realObject);
        object_setClass(realObject, [self mockedClass]);
        [realObject release];
        realObject = nil;
    }
    [super stopMocking];
}

- (void)handleUnRecordedInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:realObject];
}


#pragma mark  Subclass management

- (void)prepareObjectForInstanceMethodMocking
{
    OCMSetAssociatedMockForObject(self, realObject);

    /* dynamically create a subclass and set it as the class of the object */
    Class subclass = OCMCreateSubclass(mockedClass, realObject);
	object_setClass(realObject, subclass);

    /* point forwardInvocation: of the object to the implementation in the mock */
	Method myForwardMethod = class_getInstanceMethod([self mockObjectClass], @selector(forwardInvocationForRealObject:));
	IMP myForwardIMP = method_getImplementation(myForwardMethod);
    class_addMethod(subclass, @selector(forwardInvocation:), myForwardIMP, method_getTypeEncoding(myForwardMethod));

    /* do the same for forwardingTargetForSelector, remember existing imp with alias selector */
    Method myForwardingTargetMethod = class_getInstanceMethod([self mockObjectClass], @selector(forwardingTargetForSelectorForRealObject:));
    IMP myForwardingTargetIMP = method_getImplementation(myForwardingTargetMethod);
    IMP originalForwardingTargetIMP = [mockedClass instanceMethodForSelector:@selector(forwardingTargetForSelector:)];
    class_addMethod(subclass, @selector(forwardingTargetForSelector:), myForwardingTargetIMP, method_getTypeEncoding(myForwardingTargetMethod));
    class_addMethod(subclass, @selector(ocmock_replaced_forwardingTargetForSelector:), originalForwardingTargetIMP, method_getTypeEncoding(myForwardingTargetMethod));

    /* We also override the -class method to return the original class */
    Method myObjectClassMethod = class_getInstanceMethod([self mockObjectClass], @selector(classForRealObject));
    const char *objectClassTypes = method_getTypeEncoding(myObjectClassMethod);
    IMP myObjectClassImp = method_getImplementation(myObjectClassMethod);
    class_addMethod(subclass, @selector(class), myObjectClassImp, objectClassTypes);

    /* Adding forwarder for all instance methods to allow for verify after run */
    NSArray *whiteList = @[@"class", @"forwardingTargetForSelector:", @"methodSignatureForSelector:", @"forwardInvocation:"];
    [NSObject enumerateMethodsInClass:mockedClass usingBlock:^(SEL selector) {
        if(![whiteList containsObject:NSStringFromSelector(selector)])
            [self setupForwarderForSelector:selector];
    }];
}

- (void)setupForwarderForSelector:(SEL)selector
{
    Method originalMethod = class_getInstanceMethod(mockedClass, selector);
	IMP originalIMP = method_getImplementation(originalMethod);
    const char *types = method_getTypeEncoding(originalMethod);
    /* Might be NULL if the selector is forwarded to another class */
    // TODO: check the fallback implementation is actually sufficient
    if(types == NULL)
        types = ([[mockedClass instanceMethodSignatureForSelector:selector] fullObjCTypes]);

    Class subclass = object_getClass([self realObject]);
    IMP forwarderIMP = [subclass instanceMethodForwarderForSelector:selector];
    class_replaceMethod(subclass, selector, forwarderIMP, types);
	SEL aliasSelector = OCMAliasForOriginalSelector(selector);
	class_addMethod(subclass, aliasSelector, originalIMP, types);
}


// Implementation of the -class method; return the Class that was reported with [realObject class] prior to mocking
- (Class)classForRealObject
{
    // in here "self" is a reference to the real object, not the mock
    OCPartialMockObject *mock = OCMGetAssociatedMockForObject(self);
    return [mock mockedClass];
}


- (id)forwardingTargetForSelectorForRealObject:(SEL)sel
{
	// in here "self" is a reference to the real object, not the mock
    OCPartialMockObject *mock = OCMGetAssociatedMockForObject(self);
    if([mock handleSelector:sel])
        return self;

    return [self ocmock_replaced_forwardingTargetForSelector:sel];
}

//  Make the compiler happy in -forwardingTargetForSelectorForRealObject: because it can't find the message…
- (id)ocmock_replaced_forwardingTargetForSelector:(SEL)sel
{
    return nil;
}


- (void)forwardInvocationForRealObject:(NSInvocation *)anInvocation
{
	// in here "self" is a reference to the real object, not the mock
    OCPartialMockObject *mock = OCMGetAssociatedMockForObject(self);
	if([mock handleInvocation:anInvocation] == NO)
    {
        [anInvocation setSelector:OCMAliasForOriginalSelector([anInvocation selector])];
        [anInvocation invoke];
    }
}


@end
