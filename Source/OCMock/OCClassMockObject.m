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
    [[self class] rememberMock:self forClass:mockedClass];
    replacedClassMethods = [[NSMutableDictionary alloc] init];
    
	Method myForwardInvocationMethod = class_getInstanceMethod([self class], @selector(forwardInvocationForRealObject:));
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

- (void)forwardInvocationForRealObject:(NSInvocation *)anInvocation
{
	// in here "self" is a reference to the real class, not the mock
	OCClassMockObject *mock = [OCClassMockObject existingMockForClass:(Class)self];
	if([mock handleInvocation:anInvocation] == NO)
		[NSException raise:NSInternalInconsistencyException format:@"Ended up in subclass forwarder for %@ with unstubbed method %@",
		 [self class], NSStringFromSelector([anInvocation selector])];
}

- (void)stopMocking
{
	Class metaClass = objc_getMetaClass(class_getName(mockedClass));
    
	for (NSString *replacedMethod in replacedClassMethods) {
		NSValue *originalMethodPointer = [replacedClassMethods objectForKey:replacedMethod];
		IMP originalMethod = [originalMethodPointer pointerValue];
		if (originalMethod) {
			class_replaceMethod(metaClass, NSSelectorFromString(replacedMethod), originalMethod, 0);
		} else {
			IMP forwarderImp = [metaClass instanceMethodForSelector:@selector(aMethodThatMustNotExist)];
			class_replaceMethod(metaClass, NSSelectorFromString(replacedMethod), forwarderImp, 0);
		}
	}
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

@end
