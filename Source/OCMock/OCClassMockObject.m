//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2005-2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import "OCClassMockObject.h"
#import "NSObject+OCMAdditions.h"
#import "OCMFunctions.h"


@implementation OCClassMockObject

#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithClass:(Class)aClass
{
	[super init];
	mockedClass = aClass;
    [self setupClassForClassMethodMocking];
	return self;
}

- (void)dealloc
{
	[self stopMocking];
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"OCMockObject[%@]", NSStringFromClass(mockedClass)];
}

- (Class)mockedClass
{
	return mockedClass;
}

#pragma mark  Extending/overriding superclass behaviour

- (void)stopMocking
{
    if(originalMetaClass != nil)
    {
        OCMSetAssociatedMockForClass(nil, mockedClass);
        OCMSetIsa(mockedClass, originalMetaClass);
        originalMetaClass = nil;
    }
    [super stopMocking];
}

- (void)prepareForMockingClassMethod:(SEL)aSelector
{
    [super prepareForMockingClassMethod:aSelector];
    [self setupForwarderForClassMethodSelector:aSelector];
}


#pragma mark  Class method mocking

- (void)setupClassForClassMethodMocking
{
    OCMSetAssociatedMockForClass(self, mockedClass);

    /* dynamically create a subclass and use its meta class as the meta class for the mocked class */
    /* TODO: this will go badly wrong with tagged pointers */
    double timestamp = [NSDate timeIntervalSinceReferenceDate];
    const char *className = [[NSString stringWithFormat:@"%@-%p-%f", NSStringFromClass(mockedClass), mockedClass, timestamp] UTF8String];
    Class subclass = objc_allocateClassPair(mockedClass, className, 0);
    objc_registerClassPair(subclass);
    originalMetaClass = object_getClass(mockedClass);
    id newMetaClass = object_getClass(subclass);
    OCMSetIsa(mockedClass, OCMGetIsa(subclass));

    /* point forwardInvocation: of the object to the implementation in the mock */
    Method myForwardMethod = class_getInstanceMethod([self mockObjectClass], @selector(forwardInvocationForClassObject:));
    IMP myForwardIMP = method_getImplementation(myForwardMethod);
    class_addMethod(newMetaClass, @selector(forwardInvocation:), myForwardIMP, method_getTypeEncoding(myForwardMethod));
}


- (void)setupForwarderForClassMethodSelector:(SEL)selector
{
    Method method = class_getClassMethod(mockedClass, selector);
    IMP originalIMP = method_getImplementation(method);

    Class metaClass = object_getClass(mockedClass);
    IMP forwarderIMP = [metaClass instanceMethodForwarderForSelector:selector];
    class_replaceMethod(metaClass, selector, forwarderIMP, method_getTypeEncoding(method));
    
    SEL aliasSelector = OCMAliasForOriginalSelector(selector);
    class_addMethod(metaClass, aliasSelector, originalIMP, method_getTypeEncoding(method));
}


- (void)forwardInvocationForClassObject:(NSInvocation *)anInvocation
{
	// in here "self" is a reference to the real class, not the mock
	OCClassMockObject *mock = OCMGetAssociatedMockForClass((Class)self);
	if([mock handleInvocation:anInvocation] == NO)
    {
        // if mock doesn't want to handle the invocation, maybe all expects have occurred, we forward to class
        [anInvocation setSelector:OCMAliasForOriginalSelector([anInvocation selector])];
        [anInvocation invoke];
    }
}


#pragma mark  Proxy API

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [mockedClass instanceMethodSignatureForSelector:aSelector];
}

- (Class)mockObjectClass
{
    return [super class];
}

- (Class)class
{
    return mockedClass;
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return [mockedClass instancesRespondToSelector:selector];
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return [mockedClass isSubclassOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return class_conformsToProtocol(mockedClass, aProtocol);
}

@end


#pragma mark  -

/**
 taken from:
 `class-dump -f isNS /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk/System/Library/Frameworks/CoreFoundation.framework`
 
 @interface NSObject (__NSIsKinds)
 - (_Bool)isNSValue__;
 - (_Bool)isNSTimeZone__;
 - (_Bool)isNSString__;
 - (_Bool)isNSSet__;
 - (_Bool)isNSOrderedSet__;
 - (_Bool)isNSNumber__;
 - (_Bool)isNSDictionary__;
 - (_Bool)isNSDate__;
 - (_Bool)isNSData__;
 - (_Bool)isNSArray__;
 */

@implementation OCClassMockObject(NSIsKindsImplementation)

- (BOOL)isNSValue__
{
    return [mockedClass isKindOfClass:[NSValue class]];
}

- (BOOL)isNSTimeZone__
{
    return [mockedClass isKindOfClass:[NSTimeZone class]];
}

- (BOOL)isNSSet__
{
    return [mockedClass isKindOfClass:[NSSet class]];
}

- (BOOL)isNSOrderedSet__
{
    return [mockedClass isKindOfClass:[NSOrderedSet class]];
}

- (BOOL)isNSNumber__
{
    return [mockedClass isKindOfClass:[NSNumber class]];
}

- (BOOL)isNSDate__
{
    return [mockedClass isKindOfClass:[NSDate class]];
}

- (BOOL)isNSString__
{
    return [mockedClass isKindOfClass:[NSString class]];
}

- (BOOL)isNSDictionary__
{
    return [mockedClass isKindOfClass:[NSDictionary class]];
}

- (BOOL)isNSData__
{
    return [mockedClass isKindOfClass:[NSData class]];
}

- (BOOL)isNSArray__
{
    return [mockedClass isKindOfClass:[NSArray class]];
}

@end
