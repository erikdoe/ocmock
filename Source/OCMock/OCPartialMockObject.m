//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import "OCPartialMockRecorder.h"
#import "OCPartialMockObject.h"


@interface OCPartialMockObject (Private)
- (void)forwardInvocationForRealObject:(NSInvocation *)anInvocation;
@end 


NSString *OCMRealMethodAliasPrefix = @"ocmock_replaced_";

@implementation OCPartialMockObject


#pragma mark  Mock table

static NSMutableDictionary *mockTable;

+ (void)initialize
{
	if(self == [OCPartialMockObject class])
		mockTable = [[NSMutableDictionary alloc] init];
}

+ (void)rememberPartialMock:(OCPartialMockObject *)mock forObject:(id)anObject
{
    @synchronized(mockTable)
    {
        [mockTable setObject:[NSValue valueWithNonretainedObject:mock] forKey:[NSValue valueWithNonretainedObject:anObject]];
    }
}

+ (void)forgetPartialMockForObject:(id)anObject
{
    @synchronized(mockTable)
    {
        [mockTable removeObjectForKey:[NSValue valueWithNonretainedObject:anObject]];
    }
}

+ (OCPartialMockObject *)existingPartialMockForObject:(id)anObject
{
    @synchronized(mockTable)
    {
        OCPartialMockObject *mock = [[mockTable objectForKey:[NSValue valueWithNonretainedObject:anObject]] nonretainedObjectValue];
        if(mock == nil)
            [NSException raise:NSInternalInconsistencyException format:@"No partial mock for object %p", anObject];
        return mock;
    }
}



#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithObject:(NSObject *)anObject
{
	[super initWithClass:[anObject class]];
	realObject = [anObject retain];
	[[self class] rememberPartialMock:self forObject:anObject];
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

- (void)stopMocking
{
	object_setClass(realObject, [self mockedClass]);
	[realObject release];
	[[self class] forgetPartialMockForObject:realObject];
	realObject = nil;
}


#pragma mark  Subclass management

- (void)setupSubclassForObject:(id)anObject
{
	Class realClass = [anObject class];
	double timestamp = [NSDate timeIntervalSinceReferenceDate];
	const char *className = [[NSString stringWithFormat:@"%@-%p-%f", realClass, anObject, timestamp] UTF8String];
	Class subclass = objc_allocateClassPair(realClass, className, 0);
	objc_registerClassPair(subclass);
	object_setClass(anObject, subclass);

	Method myForwardInvocationMethod = class_getInstanceMethod([self class], @selector(forwardInvocationForRealObject:));
	IMP myForwardInvocationImp = method_getImplementation(myForwardInvocationMethod);
	const char *forwardInvocationTypes = method_getTypeEncoding(myForwardInvocationMethod);
	class_addMethod(subclass, @selector(forwardInvocation:), myForwardInvocationImp, forwardInvocationTypes);


    Method myForwardingTargetForSelectorMethod = class_getInstanceMethod([self class], @selector(forwardingTargetForSelectorForRealObject:));
    IMP myForwardingTargetForSelectorImp = method_getImplementation(myForwardingTargetForSelectorMethod);
    const char *forwardingTargetForSelectorTypes = method_getTypeEncoding(myForwardingTargetForSelectorMethod);

    IMP originalForwardingTargetForSelectorImp = [realClass instanceMethodForSelector:@selector(forwardingTargetForSelector:)];

    class_addMethod(subclass, @selector(forwardingTargetForSelector:), myForwardingTargetForSelectorImp, forwardingTargetForSelectorTypes);
    class_addMethod(subclass, @selector(forwardingTargetForSelector_Original:), originalForwardingTargetForSelectorImp, forwardingTargetForSelectorTypes);
}

- (void)setupForwarderForSelector:(SEL)selector
{
	Class subclass = [[self realObject] class];
	Method originalMethod = class_getInstanceMethod([subclass superclass], selector);
	IMP originalImp = method_getImplementation(originalMethod);

	IMP forwarderImp = [subclass instanceMethodForSelector:@selector(aMethodThatMustNotExist)];
	class_addMethod(subclass, method_getName(originalMethod), forwarderImp, method_getTypeEncoding(originalMethod));

	SEL aliasSelector = NSSelectorFromString([OCMRealMethodAliasPrefix stringByAppendingString:NSStringFromSelector(selector)]);
	class_addMethod(subclass, aliasSelector, originalImp, method_getTypeEncoding(originalMethod));
}

- (void)removeForwarderForSelector:(SEL)selector
{
    Class subclass = [[self realObject] class];
    SEL aliasSelector = NSSelectorFromString([OCMRealMethodAliasPrefix stringByAppendingString:NSStringFromSelector(selector)]);
    Method originalMethod = class_getInstanceMethod([subclass superclass], aliasSelector);
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
    OCPartialMockObject *mock = [OCPartialMockObject existingPartialMockForObject:self];
    if ([mock handleSelector:sel])
        return self;

    return [self forwardingTargetForSelector_Original:sel];
}

- (void)forwardInvocationForRealObject:(NSInvocation *)anInvocation
{
	// in here "self" is a reference to the real object, not the mock
	OCPartialMockObject *mock = [OCPartialMockObject existingPartialMockForObject:self];
	if([mock handleInvocation:anInvocation] == NO)
    {
        // if mock doesn't want to handle the invocation, maybe all expects have occurred, we forward to real object
        SEL aliasSelector = NSSelectorFromString([OCMRealMethodAliasPrefix stringByAppendingString:NSStringFromSelector([anInvocation selector])]);
        [anInvocation setSelector:aliasSelector];
        [anInvocation invoke];
    }
}



#pragma mark  Overrides

- (id)getNewRecorder
{
	return [[[OCPartialMockRecorder alloc] initWithSignatureResolver:self] autorelease];
}

- (void)handleUnRecordedInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:realObject];
}


@end
