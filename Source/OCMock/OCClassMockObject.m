/*
 *  Copyright (c) 2005-2021 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import <objc/runtime.h>
#import "NSMethodSignature+OCMAdditions.h"
#import "NSObject+OCMAdditions.h"
#import "OCClassMockObject.h"
#import "OCMFunctionsPrivate.h"
#import "OCMInvocationStub.h"

@interface NSObject (OCMClassMockingSupport)
+ (BOOL)supportsMocking:(NSString **)reason;
@end


@interface OCClassMockObjectInstanceVars : NSObject
@property (nonatomic) Class mockedClass;
@property (nonatomic) Class originalMetaClass;
@property (nonatomic) Class classCreatedForNewMetaClass;
@end

@implementation OCClassMockObjectInstanceVars
@end

@interface OCClassMockObject ()
@property (nonatomic) Class mockedClass;
@property (nonatomic) Class originalMetaClass;
@property (nonatomic) Class classCreatedForNewMetaClass;
@end

static const char *OCClassMockObjectInstanceVarsKey = "OCClassMockObjectInstanceVarsKey";

@implementation OCClassMockObject

#pragma mark Initialisers, description, accessors, etc.

- (id)initWithClass:(Class)aClass
{
    [self assertClassIsSupported:aClass];
    self = [super init];
    OCClassMockObjectInstanceVars *vars = [[OCClassMockObjectInstanceVars alloc] init];
    objc_setAssociatedObject(self, OCClassMockObjectInstanceVarsKey, vars, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [vars release];

    self.mockedClass = aClass;
    [self prepareClassForClassMethodMocking];
    return self;
}

- (void)dealloc
{
    [self stopMocking];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"OCClassMockObject(%@)", NSStringFromClass(self.mockedClass)];
}

#pragma mark  Setters/Getters

- (OCClassMockObjectInstanceVars *)classMockObjectInstanceVars {
    return objc_getAssociatedObject(self, OCClassMockObjectInstanceVarsKey);
}

- (Class)mockedClass
{
    return self.classMockObjectInstanceVars.mockedClass;
}

- (Class)classCreatedForNewMetaClass
{
    return self.classMockObjectInstanceVars.classCreatedForNewMetaClass;
}

- (Class)originalMetaClass
{
    return self.classMockObjectInstanceVars.originalMetaClass;
}

- (void)setMockedClass:(Class)mockedClass
{
    self.classMockObjectInstanceVars.mockedClass = mockedClass;
}

- (void)setClassCreatedForNewMetaClass:(Class)classCreatedForNewMetaClass
{
    self.classMockObjectInstanceVars.classCreatedForNewMetaClass = classCreatedForNewMetaClass;
}

- (void)setOriginalMetaClass:(Class)originalMetaClass
{
    self.classMockObjectInstanceVars.originalMetaClass = originalMetaClass;
}

- (void)assertClassIsSupported:(Class)aClass
{
    if(aClass == Nil)
        [NSException raise:NSInvalidArgumentException format:@"Class cannot be Nil."];

    if([aClass respondsToSelector:@selector(supportsMocking:)])
    {
        NSString *reason = nil;
        if(![aClass supportsMocking:&reason])
            [NSException raise:NSInvalidArgumentException format:@"Class %@ does not support mocking: %@", aClass, reason];
    }
}

#pragma mark Extending/overriding superclass behaviour

- (void)stopMocking
{
    if(self.originalMetaClass != nil)
    {
        [self stopMockingClassMethods];
    }
    if(self.classCreatedForNewMetaClass != nil)
    {
        OCMDisposeSubclass(self.classCreatedForNewMetaClass);
        self.classCreatedForNewMetaClass = nil;
    }
    [super stopMocking];
}


- (void)stopMockingClassMethods
{
    OCMSetAssociatedMockForClass(nil, self.mockedClass);
    object_setClass(self.mockedClass, self.originalMetaClass);
  self.originalMetaClass = nil;
    /* created meta class will be disposed later because partial mocks create another subclass depending on it */
}


- (void)addStub:(OCMInvocationStub *)aStub
{
    [super addStub:aStub];
    if([aStub recordedAsClassMethod])
        [self setupForwarderForClassMethodSelector:[[aStub recordedInvocation] selector]];
}


#pragma mark Class method mocking

- (void)prepareClassForClassMethodMocking
{
    /* the runtime and OCMock depend on string and array; we don't intercept methods on them to avoid endless loops */
    if([[self.mockedClass class] isSubclassOfClass:[NSString class]] || [[self.mockedClass class] isSubclassOfClass:[NSArray class]])
        return;

    /* trying to replace class methods on NSManagedObject and subclasses of it doesn't work; see #339 */
    if([self.mockedClass isSubclassOfClass:objc_getClass("NSManagedObject")])
        return;

    /* if there is another mock for this exact class, stop it */
    id otherMock = OCMGetAssociatedMockForClass(self.mockedClass, NO);
    if(otherMock != nil)
        [otherMock stopMockingClassMethods];

    OCMSetAssociatedMockForClass(self, self.mockedClass);

    /* dynamically create a subclass and use its meta class as the meta class for the mocked class */
    self.classCreatedForNewMetaClass = OCMCreateSubclass(self.mockedClass, self.mockedClass);
  self.originalMetaClass = object_getClass(self.mockedClass);
    id newMetaClass = object_getClass(self.classCreatedForNewMetaClass);

    /* create a dummy initialize method */
    Method myDummyInitializeMethod = class_getInstanceMethod([self mockObjectClass], @selector(initializeForClassObject));
    const char *initializeTypes = method_getTypeEncoding(myDummyInitializeMethod);
    IMP myDummyInitializeIMP = method_getImplementation(myDummyInitializeMethod);
    class_addMethod(newMetaClass, @selector(initialize), myDummyInitializeIMP, initializeTypes);

    object_setClass(self.mockedClass, newMetaClass); // only after dummy initialize is installed (iOS9)

    /* point forwardInvocation: of the object to the implementation in the mock */
    Method myForwardMethod = class_getInstanceMethod([self mockObjectClass], @selector(forwardInvocationForClassObject:));
    IMP myForwardIMP = method_getImplementation(myForwardMethod);
    class_addMethod(newMetaClass, @selector(forwardInvocation:), myForwardIMP, method_getTypeEncoding(myForwardMethod));

    /* adding forwarder for most class methods (instance methods on meta class) to allow for verify after run */
    NSArray *methodBlackList = @[
        @"class", @"forwardingTargetForSelector:", @"methodSignatureForSelector:", @"forwardInvocation:", @"isBlock",
        @"instanceMethodForwarderForSelector:", @"instanceMethodSignatureForSelector:", @"resolveClassMethod:"
    ];
    void (^setupForwarderFiltered)(Class, SEL) = ^(Class cls, SEL sel) {
        if((cls == object_getClass([NSObject class])) || (cls == [NSObject class]) || (cls == object_getClass(cls)))
            return;
        if(OCMIsApplePrivateMethod(cls, sel))
            return;
        if([methodBlackList containsObject:NSStringFromSelector(sel)])
            return;
        @try
        {
            [self setupForwarderForClassMethodSelector:sel];
        }
        @catch(NSException *e)
        {
            // ignore for now
        }
    };
    [NSObject enumerateMethodsInClass:self.originalMetaClass usingBlock:setupForwarderFiltered];
}


- (void)setupForwarderForClassMethodSelector:(SEL)selector
{
    SEL aliasSelector = OCMAliasForOriginalSelector(selector);
    if(class_getClassMethod(self.mockedClass, aliasSelector) != NULL)
        return;

    Method originalMethod = class_getClassMethod(self.mockedClass, selector);
    IMP originalIMP = method_getImplementation(originalMethod);
    const char *types = method_getTypeEncoding(originalMethod);

    Class metaClass = object_getClass(self.mockedClass);
    IMP forwarderIMP = [self.originalMetaClass instanceMethodForwarderForSelector:selector];
    class_addMethod(metaClass, aliasSelector, originalIMP, types);
    class_replaceMethod(metaClass, selector, forwarderIMP, types);
}


- (void)forwardInvocationForClassObject:(NSInvocation *)anInvocation
{
    // in here "self" is a reference to the real class, not the mock
    OCClassMockObject *mock = OCMGetAssociatedMockForClass((Class)self, YES);
    if(mock == nil)
    {
        [NSException raise:NSInternalInconsistencyException format:@"No mock for class %@", NSStringFromClass((Class)self)];
    }
    if([mock handleInvocation:anInvocation] == NO)
    {
        [anInvocation setSelector:OCMAliasForOriginalSelector([anInvocation selector])];
        [anInvocation invoke];
    }
}

- (void)initializeForClassObject
{
    // we really just want to have an implementation so that the superclass's is not called
}


#pragma mark Proxy API

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [self.mockedClass instanceMethodSignatureForSelector:aSelector];
    if(signature == nil)
    {
        signature = [NSMethodSignature signatureForDynamicPropertyAccessedWithSelector:aSelector inClass:self.mockedClass];
    }
    return signature;
}

- (Class)mockObjectClass
{
    return [super class];
}

- (Class)class
{
    return self.mockedClass;
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return [self.mockedClass instancesRespondToSelector:selector];
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return [self.mockedClass isSubclassOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    Class clazz = self.mockedClass;
    while(clazz != nil)
    {
        if (class_conformsToProtocol(clazz, aProtocol))
        {
            return YES;
        }
        clazz = class_getSuperclass(clazz);
    }
    return NO;
}

@end


#pragma mark -

/*
 taken from:
 `class-dump -f isNS /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk/System/Library/Frameworks/CoreFoundation.framework`
 
 @ interface NSObject (__NSIsKinds)
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
    return [self.mockedClass isSubclassOfClass:[NSValue class]];
}

- (BOOL)isNSTimeZone__
{
    return [self.mockedClass isSubclassOfClass:[NSTimeZone class]];
}

- (BOOL)isNSSet__
{
    return [self.mockedClass isSubclassOfClass:[NSSet class]];
}

- (BOOL)isNSOrderedSet__
{
    return [self.mockedClass isSubclassOfClass:[NSOrderedSet class]];
}

- (BOOL)isNSNumber__
{
    return [self.mockedClass isSubclassOfClass:[NSNumber class]];
}

- (BOOL)isNSDate__
{
    return [self.mockedClass isSubclassOfClass:[NSDate class]];
}

- (BOOL)isNSString__
{
    return [self.mockedClass isSubclassOfClass:[NSString class]];
}

- (BOOL)isNSDictionary__
{
    return [self.mockedClass isSubclassOfClass:[NSDictionary class]];
}

- (BOOL)isNSData__
{
    return [self.mockedClass isSubclassOfClass:[NSData class]];
}

- (BOOL)isNSArray__
{
    return [self.mockedClass isSubclassOfClass:[NSArray class]];
}

@end
