/*
 *  Copyright (c) 2009-2021 Erik Doernenburg and contributors
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
#import "NSInvocation+OCMAdditions.h"
#import "NSMethodSignature+OCMAdditions.h"
#import "NSObject+OCMAdditions.h"
#import "OCPartialMockObject.h"
#import "OCMFunctionsPrivate.h"
#import "OCMInvocationStub.h"

@interface OCPartialMockObjectInstanceVars : NSObject
@property (nonatomic, assign) NSObject *realObject;
@property (nonatomic, assign) NSInvocation *invocationFromMock;
@end

@implementation OCPartialMockObjectInstanceVars
@end

static const char *OCPartialMockObjectInstanceVarsKey = "OCPartialMockObjectInstanceVarsKey";

@interface OCPartialMockObject ()
@property (nonatomic) NSObject *realObject;
@property (nonatomic) NSInvocation *invocationFromMock;
@end

@implementation OCPartialMockObject

#pragma mark Initialisers, description, accessors, etc.

- (id)initWithObject:(NSObject *)anObject
{
    if(anObject == nil)
        [NSException raise:NSInvalidArgumentException format:@"Object cannot be nil."];
    Class const class = [self classToSubclassForObject:anObject];
    [self assertClassIsSupported:class];
    self = [super initWithClass:class];
    OCPartialMockObjectInstanceVars *vars = [[OCPartialMockObjectInstanceVars alloc] init];
    objc_setAssociatedObject(self, OCPartialMockObjectInstanceVarsKey, vars, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [vars release];
    self.realObject = [anObject retain];
    [self prepareObjectForInstanceMethodMocking];
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"OCPartialMockObject(%@)", NSStringFromClass(self.mockedClass)];
}

#pragma mark  Setters/Getters

- (OCPartialMockObjectInstanceVars *)partialMockObjectInstanceVars {
    return objc_getAssociatedObject(self, OCPartialMockObjectInstanceVarsKey);
}

- (NSObject *)realObject
{
    return self.partialMockObjectInstanceVars.realObject;
}

- (void)setRealObject:(NSObject *)realObject
{
    self.partialMockObjectInstanceVars.realObject = realObject;
}

- (NSInvocation *)invocationFromMock
{
    return self.partialMockObjectInstanceVars.invocationFromMock;
}

- (void)setInvocationFromMock:(NSInvocation *)invocationFromMock
{
    self.partialMockObjectInstanceVars.invocationFromMock = invocationFromMock;
}

#pragma mark  Helper methods

- (void)assertClassIsSupported:(Class)class
{
    [super assertClassIsSupported:class];
    NSString *classname = NSStringFromClass(class);
    NSString *reason = nil;
    if([classname hasPrefix:@"__NSTagged"] || [classname hasPrefix:@"NSTagged"])
        reason = [NSString stringWithFormat:@"OCMock does not support partially mocking tagged classes; got %@", classname];
    else if([classname hasPrefix:@"__NSCF"])
        reason = [NSString stringWithFormat:@"OCMock does not support partially mocking toll-free bridged classes; got %@", classname];

    if(reason != nil)
        [[NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil] raise];
}

- (Class)classToSubclassForObject:(id)object
{
    if([object observationInfo] != NULL)
    {
        // Special treatment for objects that are observed with KVO. The KVO implementation sets
        // a subclass for such objects and it overrides the -class method to return the original
        // class. If we base our subclass on the KVO subclass, as returned by object_getClass(),
        // crashes will occur. So, we take the real class instead. Unfortunately, this removes
        // any observers set up before.
        NSLog(@"Warning: Creating a partial mock for %@. This object has observers, which will now stop receiving KVO notifications. If you want to receive KVO notifications, create the partial mock first, and then register the observer.", object);
        return [object class];
    }

    return object_getClass(object);
}

#pragma mark Extending/overriding superclass behaviour

- (void)stopMocking
{
    if(self.realObject != nil)
    {
        Class partialMockClass = object_getClass(self.realObject);
        OCMSetAssociatedMockForObject(nil, self.realObject);
        object_setClass(self.realObject, self.mockedClass);
        [self.realObject release];
        self.realObject = nil;
        OCMDisposeSubclass(partialMockClass);
    }
    [super stopMocking];
}

- (void)addStub:(OCMInvocationStub *)aStub
{
    [super addStub:aStub];
    if(![aStub recordedAsClassMethod])
        [self setupForwarderForSelector:[[aStub recordedInvocation] selector]];
}

- (void)addInvocation:(NSInvocation *)anInvocation
{
    // If the mock invokes a method on the real object we end up here a second time, but because
    // the mock has added the invocation already we do not want to add it again.
	if((self.invocationFromMock == nil) || ([anInvocation selector] != [self.invocationFromMock selector]))
        [super addInvocation:anInvocation];
}

- (void)handleUnRecordedInvocation:(NSInvocation *)anInvocation
{
    // In the case of an init that is called on a mock we must return the mock instance and
    // not the realObject if the underlying init returns the realObject because at the call site
    // ARC will have retained the target and the release/retain count must balance. If we return
    // the realObject, then realObject will be over released and the mock will leak. Equally if
    // we are called on the realObject we need to make sure not to return the mock.
    id targetReceivingInit = nil;
    if([anInvocation methodIsInInitFamily])
    {
        targetReceivingInit = [anInvocation target];
        [self.realObject retain];
    }

    self.invocationFromMock = anInvocation;
    [anInvocation invokeWithTarget:self.realObject];
    self.invocationFromMock = nil;

    if(targetReceivingInit)
    {
        id returnVal;
        [anInvocation getReturnValue:&returnVal];
        if(returnVal == self.realObject)
        {
            [anInvocation setReturnValue:&self];
            [self.realObject release];
            [self retain];
        }
        [targetReceivingInit release];
    }
}


#pragma mark Subclass management

- (void)prepareObjectForInstanceMethodMocking
{
    OCMSetAssociatedMockForObject(self, self.realObject);

    /* dynamically create a subclass and set it as the class of the object */
    Class subclass = OCMCreateSubclass(self.mockedClass, self.realObject);
    object_setClass(self.realObject, subclass);

    /* point forwardInvocation: of the object to the implementation in the mock */
    Method myForwardMethod = class_getInstanceMethod([self mockObjectClass], @selector(forwardInvocationForRealObject:));
    IMP myForwardIMP = method_getImplementation(myForwardMethod);
    class_addMethod(subclass, @selector(forwardInvocation:), myForwardIMP, method_getTypeEncoding(myForwardMethod));

    /* do the same for forwardingTargetForSelector, remember existing imp with alias selector */
    Method myForwardingTargetMethod = class_getInstanceMethod([self mockObjectClass], @selector(forwardingTargetForSelectorForRealObject:));
    IMP myForwardingTargetIMP = method_getImplementation(myForwardingTargetMethod);
    IMP originalForwardingTargetIMP = [self.mockedClass instanceMethodForSelector:@selector(forwardingTargetForSelector:)];
    class_addMethod(subclass, @selector(forwardingTargetForSelector:), myForwardingTargetIMP, method_getTypeEncoding(myForwardingTargetMethod));
    class_addMethod(subclass, @selector(ocmock_replaced_forwardingTargetForSelector:), originalForwardingTargetIMP, method_getTypeEncoding(myForwardingTargetMethod));

    /* We also override the -class method to return the original class */
    Method myObjectClassMethod = class_getInstanceMethod([self mockObjectClass], @selector(classForRealObject));
    const char *objectClassTypes = method_getTypeEncoding(myObjectClassMethod);
    IMP myObjectClassImp = method_getImplementation(myObjectClassMethod);
    class_addMethod(subclass, @selector(class), myObjectClassImp, objectClassTypes);

    /* Adding forwarder for most instance methods to allow for verify after run */
    NSArray *methodBlackList = @[ @"class", @"forwardingTargetForSelector:", @"methodSignatureForSelector:", @"forwardInvocation:",
        @"allowsWeakReference", @"retainWeakReference", @"isBlock", @"retainCount", @"retain", @"release", @"autorelease" ];
    void (^setupForwarderFiltered)(Class, SEL) = ^(Class cls, SEL sel) {
        if(OCMIsAppleBaseClass(cls) || OCMIsApplePrivateMethod(cls, sel))
            return;
        if([methodBlackList containsObject:NSStringFromSelector(sel)])
            return;
        @try
        {
            [self setupForwarderForSelector:sel];
        }
        @catch(NSException *e)
        {
            // ignore for now
        }
    };
    [NSObject enumerateMethodsInClass:self.mockedClass usingBlock:setupForwarderFiltered];
}

- (void)setupForwarderForSelector:(SEL)sel
{
    SEL aliasSelector = OCMAliasForOriginalSelector(sel);
    if(class_getInstanceMethod(object_getClass(self.realObject), aliasSelector) != NULL)
        return;

    Method originalMethod = class_getInstanceMethod(self.mockedClass, sel);
    /* Might be NULL if the selector is forwarded to another class */
    IMP originalIMP = (originalMethod != NULL) ? method_getImplementation(originalMethod) : NULL;
    const char *types = (originalMethod != NULL) ? method_getTypeEncoding(originalMethod) : NULL;
    // TODO: check the fallback implementation is actually sufficient
    if(types == NULL)
        types = ([[self.mockedClass instanceMethodSignatureForSelector:sel] fullObjCTypes]);

    Class subclass = object_getClass([self realObject]);
    IMP forwarderIMP = [self.mockedClass instanceMethodForwarderForSelector:sel];
    class_replaceMethod(subclass, sel, forwarderIMP, types);
    class_addMethod(subclass, aliasSelector, originalIMP, types);
}


// Implementation of the -class method; return the Class that was reported with [realObject class] prior to mocking
- (Class)classForRealObject
{
    // in here "self" is a reference to the real object, not the mock
    OCPartialMockObject *mock = OCMGetAssociatedMockForObject(self);
    if(mock == nil)
        [NSException raise:NSInternalInconsistencyException format:@"No partial mock for object %p", self];
    return [mock mockedClass];
}


- (id)forwardingTargetForSelectorForRealObject:(SEL)sel
{
    // in here "self" is a reference to the real object, not the mock
    OCPartialMockObject *mock = OCMGetAssociatedMockForObject(self);
    if(mock == nil)
        [NSException raise:NSInternalInconsistencyException format:@"No partial mock for object %p", self];
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
    if(mock == nil)
        [NSException raise:NSInternalInconsistencyException format:@"No partial mock for object %p", self];

    if([mock handleInvocation:anInvocation] == NO)
    {
        [anInvocation setSelector:OCMAliasForOriginalSelector([anInvocation selector])];
        [anInvocation invoke];
    }
}


#pragma mark Verification handling

- (NSString *)descriptionForVerificationFailureWithMatcher:(OCMInvocationMatcher *)matcher quantifier:(OCMQuantifier *)quantifier invocationCount:(NSUInteger)count
{
    SEL matcherSel = [[matcher recordedInvocation] selector];
    __block BOOL stubbingMightHelp = NO;
    [NSObject enumerateMethodsInClass:self.mockedClass usingBlock:^(Class cls, SEL sel) {
        if(sel == matcherSel)
            stubbingMightHelp = OCMIsAppleBaseClass(cls) || OCMIsApplePrivateMethod(cls, sel);
    }];

    NSString *description = [super descriptionForVerificationFailureWithMatcher:matcher quantifier:quantifier invocationCount:count];
    if(stubbingMightHelp)
    {
        description = [description stringByAppendingFormat:@" Adding a stub for the method may resolve the issue, e.g. `OCMStub([mockObject %@]).andForwardToRealObject()`", [matcher description]];
    }
    return description;
}


@end
