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
    OCMSetAssociatedMockForObject(self, anObject);
	[self setupSubclassForObject:realObject];
	return self;
}

- (void)dealloc
{
	if(realObject != nil)
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
	object_setClass(realObject, [self mockedClass]);
	[realObject release];
    OCMSetAssociatedMockForObject(nil, realObject);
	realObject = nil;
    
    [super stopMocking];
}

- (void)handleUnRecordedInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:realObject];
}


#pragma mark  Subclass management

- (void)setupSubclassForObject:(id)anObject
{
	Class realClass = [anObject class];
	double timestamp = [NSDate timeIntervalSinceReferenceDate];
	const char *className = [[NSString stringWithFormat:@"%@-%p-%f", NSStringFromClass(realClass), anObject, timestamp] UTF8String];
	Class subclass = objc_allocateClassPair(realClass, className, 0);
	objc_registerClassPair(subclass);
	object_setClass(anObject, subclass);

	Method myForwardInvocationMethod = class_getInstanceMethod([self mockObjectClass], @selector(forwardInvocationForRealObject:));
	IMP myForwardInvocationImp = method_getImplementation(myForwardInvocationMethod);
	const char *forwardInvocationTypes = method_getTypeEncoding(myForwardInvocationMethod);
	class_addMethod(subclass, @selector(forwardInvocation:), myForwardInvocationImp, forwardInvocationTypes);

    Method myForwardingTargetForSelectorMethod = class_getInstanceMethod([self mockObjectClass], @selector(forwardingTargetForSelectorForRealObject:));
    IMP myForwardingTargetForSelectorImp = method_getImplementation(myForwardingTargetForSelectorMethod);
    const char *forwardingTargetForSelectorTypes = method_getTypeEncoding(myForwardingTargetForSelectorMethod);
    IMP originalForwardingTargetForSelectorImp = [realClass instanceMethodForSelector:@selector(forwardingTargetForSelector:)];
    class_addMethod(subclass, @selector(forwardingTargetForSelector:), myForwardingTargetForSelectorImp, forwardingTargetForSelectorTypes);
    class_addMethod(subclass, @selector(forwardingTargetForSelector_Original:), originalForwardingTargetForSelectorImp, forwardingTargetForSelectorTypes);
    
    /* We also override the -class method to return the original class */
    Method myObjectClassMethod = class_getInstanceMethod([self mockObjectClass], @selector(classForRealObject));
    const char *objectClassTypes = method_getTypeEncoding(myObjectClassMethod);
    IMP myObjectClassImp = method_getImplementation(myObjectClassMethod);
    IMP originalClassImp = [realClass instanceMethodForSelector:@selector(class)];
    
    class_addMethod(subclass, @selector(class), myObjectClassImp, objectClassTypes);
    class_addMethod(subclass, @selector(class_Original), originalClassImp, objectClassTypes);

    /* Adding forwarder for all instance methods to allow for verify after run */
    NSSet *whitelist = [NSSet setWithObjects:
            @"class",
            @"forwardingTargetForSelector:",
            @"methodSignatureForSelector:",
            @"forwardInvocation:", nil
    ];
    for(Class cls = realClass; cls != nil; cls = class_getSuperclass(cls))
    {
        Method *methodList = class_copyMethodList(cls, NULL);
        if(methodList == NULL)
            continue;
        for(Method *mPtr = methodList; *mPtr != NULL; mPtr++)
        {
            SEL selector = method_getName(*mPtr);
            if(![whitelist containsObject:NSStringFromSelector(selector)])
                [self setupForwarderForSelector:selector];
        }
        free(methodList);
    }
}

- (void)setupForwarderForSelector:(SEL)selector
{
	Class subclass = object_getClass([self realObject]);
	Method originalMethod = class_getInstanceMethod([self mockedClass], selector);
	IMP originalImp = method_getImplementation(originalMethod);
    IMP forwarderImp = [[self mockedClass] instanceMethodForwarderForSelector:selector];

	const char *types = method_getTypeEncoding(originalMethod);
	/* Might be NULL if the selector is forwarded to another class */
    // TODO: check the fallback implementation is actually sufficient
    if(types == NULL)
        types = ([[[self mockedClass] instanceMethodSignatureForSelector:selector] fullObjCTypes]);
	class_addMethod(subclass, selector, forwarderImp, types);

	SEL aliasSelector = OCMAliasForOriginalSelector(selector);
	class_addMethod(subclass, aliasSelector, originalImp, types);
}

- (void)removeForwarderForSelector:(SEL)selector
{
    Class subclass = object_getClass([self realObject]);
    SEL aliasSelector = OCMAliasForOriginalSelector(selector);
    Method originalMethod = class_getInstanceMethod([self mockedClass], aliasSelector);
  	IMP originalImp = method_getImplementation(originalMethod);
    class_replaceMethod(subclass, selector, originalImp, method_getTypeEncoding(originalMethod));
}

//  Make the compiler happy in -forwardingTargetForSelectorForRealObject: because it can't find the message…
- (id)forwardingTargetForSelector_Original:(SEL)sel
{
    return nil;
}

- (id)forwardingTargetForSelectorForRealObject:(SEL)sel
{
	// in here "self" is a reference to the real object, not the mock
    OCPartialMockObject *mock = OCMGetAssociatedMockForObject(self);
    if([mock handleSelector:sel])
        return self;

    return [self forwardingTargetForSelector_Original:sel];
}

- (void)forwardInvocationForRealObject:(NSInvocation *)anInvocation
{
	// in here "self" is a reference to the real object, not the mock
    OCPartialMockObject *mock = OCMGetAssociatedMockForObject(self);
	if([mock handleInvocation:anInvocation] == NO)
    {
        // if mock doesn't want to handle the invocation, maybe all expects have occurred, we forward to real object
        [anInvocation setSelector:OCMAliasForOriginalSelector([anInvocation selector])];
        [anInvocation invoke];
    }
}

// Make the compiler happy; we add a method with this name to the real class
- (Class)class_Original
{
    return nil;
}

// Implementation of the -class method; return the Class that was reported with [realObject class] prior to mocking
- (Class)classForRealObject
{
    // "self" is the real object, not the mock
    OCPartialMockObject *mock = OCMGetAssociatedMockForObject(self);
    if (mock != nil)
        return [mock mockedClass];

    return [self class_Original];
}


@end
