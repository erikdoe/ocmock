//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2005-2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import "OCClassMockObject.h"


@implementation OCClassMockObject

#pragma mark  Mock table

static NSMutableDictionary *mockTable;

+ (void)initialize
{
	if(self == [OCClassMockObject class])
		mockTable = [[NSMutableDictionary alloc] init];
}

+ (void)rememberMock:(OCClassMockObject *)mock forClass:(Class)aClass
{
    @synchronized(mockTable)
    {
        [mockTable setObject:[NSValue valueWithNonretainedObject:mock] forKey:[NSValue valueWithNonretainedObject:aClass]];
    }
}

+ (void)forgetMockForClass:(Class)aClass
{
    @synchronized(mockTable)
    {
        [mockTable removeObjectForKey:[NSValue valueWithNonretainedObject:aClass]];
    }
}

+ (OCClassMockObject *)existingMockForClass:(Class)aClass
{
    @synchronized(mockTable)
    {
        OCClassMockObject *mock = [[mockTable objectForKey:[NSValue valueWithNonretainedObject:aClass]] nonretainedObjectValue];
        if(mock == nil)
            [NSException raise:NSInternalInconsistencyException format:@"No mock for class %p", aClass];
        return mock;
    }
}

#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithClass:(Class)aClass
{
	[super init];
	mockedClass = aClass;
	return self;
}

- (void)dealloc
{
	if(replacedClassMethods != nil)
    {
		[self stopMocking];
        [[self class] forgetMockForClass:mockedClass];
        [replacedClassMethods release];
    }
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


#pragma mark  Class method mocking

- (void)setupClassForClassMethodMocking
{
    if(replacedClassMethods != nil)
        return;

    replacedClassMethods = [[NSMutableDictionary alloc] init];
    [[self class] rememberMock:self forClass:mockedClass];
    
	Method myForwardInvocationMethod = class_getInstanceMethod([self class], @selector(forwardInvocationForClassObject:));
	IMP myForwardInvocationImp = method_getImplementation(myForwardInvocationMethod);
	const char *forwardInvocationTypes = method_getTypeEncoding(myForwardInvocationMethod);
	Class metaClass = objc_getMetaClass(class_getName(mockedClass));
    
	IMP replacedForwardInvocationImp = class_replaceMethod(metaClass, @selector(forwardInvocation:), myForwardInvocationImp, forwardInvocationTypes);
    
	[replacedClassMethods setObject:[NSValue valueWithPointer:replacedForwardInvocationImp] forKey:NSStringFromSelector(@selector(forwardInvocation:))];
}

- (void)setupForwarderForClassMethodSelector:(SEL)selector
{
	Method originalMethod = class_getClassMethod(mockedClass, selector);
	Class metaClass = objc_getMetaClass(class_getName(mockedClass));
	
	IMP forwarderImp = [metaClass instanceMethodForSelector:@selector(aMethodThatMustNotExist)];
	IMP replacedMethod = class_replaceMethod(metaClass, method_getName(originalMethod), forwarderImp, method_getTypeEncoding(originalMethod));
    
	[replacedClassMethods setObject:[NSValue valueWithPointer:replacedMethod] forKey:NSStringFromSelector(selector)];
}

- (void)removeForwarderForClassMethodSelector:(SEL)selector
{
	Class metaClass = objc_getMetaClass(class_getName(mockedClass));
    NSValue *originalMethodPointer = [replacedClassMethods objectForKey:NSStringFromSelector(selector)];
	IMP originalMethod = [originalMethodPointer pointerValue];
	if(originalMethod) {
		class_replaceMethod(metaClass, selector, originalMethod, 0);
	} else {
		IMP forwarderImp = [metaClass instanceMethodForSelector:@selector(aMethodThatMustNotExist)];
		class_replaceMethod(metaClass, selector, forwarderImp, 0);
    }
}

- (void)forwardInvocationForClassObject:(NSInvocation *)anInvocation
{
	// in here "self" is a reference to the real class, not the mock
	OCClassMockObject *mock = [OCClassMockObject existingMockForClass:(Class)self];
	if([mock handleInvocation:anInvocation] == NO)
    {
        // if mock doesn't want to handle the invocation, maybe all expects have occurred, we remove the forwarder and try again
        [mock removeForwarderForClassMethodSelector:[anInvocation selector]];
        [anInvocation invoke];
    }
}

- (void)stopMocking
{
	for(NSString *replacedMethod in replacedClassMethods)
        [self removeForwarderForClassMethodSelector:NSSelectorFromString(replacedMethod)];
}


#pragma mark  Proxy API

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [mockedClass instanceMethodSignatureForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return [mockedClass instancesRespondToSelector:selector];
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return [mockedClass isSubclassOfClass:aClass];
}

@end
