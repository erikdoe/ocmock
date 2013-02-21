//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import <OCMock/OCMockRecorder.h>
#import <OCMock/OCMArg.h>
#import <OCMock/OCMConstraint.h>
#import <OCMock/OCChainTampolineProxy.h>
#import <OCMock/OCMockObject.h>
#import "OCMPassByRefSetter.h"
#import "OCMReturnValueProvider.h"
#import "OCMBoxedReturnValueProvider.h"
#import "OCMExceptionReturnValueProvider.h"
#import "OCMIndirectReturnValueProvider.h"
#import "OCMNotificationPoster.h"
#import "OCMBlockCaller.h"
#import "NSInvocation+OCMAdditions.h"

@interface NSObject(HCMatcherDummy)
- (BOOL)matches:(id)item;
@end

#pragma mark  -

@interface OCMockRecorder ()
@property (retain) NSArray *invocationHandlers;
@end

@implementation OCMockRecorder
@synthesize invocationHandlers;

#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithSignatureResolver:(id)anObject
{
	signatureResolver = anObject;
	invocationHandlers = [[NSMutableArray alloc] init];
	return self;
}

- (void)dealloc
{
	[recordedInvocation release];
	[invocationHandlers release];
	[super dealloc];
}

- (NSString *)description
{
	return [recordedInvocation invocationDescription];
}

- (void)releaseInvocation
{
	[recordedInvocation release];
	recordedInvocation = nil;
}


#pragma mark  Recording invocation handlers

- (id)andReturn:(id)anObject
{
	[invocationHandlers addObject:[[[OCMReturnValueProvider alloc] initWithValue:anObject] autorelease]];
	return self;
}

- (id)andReturnValue:(NSValue *)aValue
{
	[invocationHandlers addObject:[[[OCMBoxedReturnValueProvider alloc] initWithValue:aValue] autorelease]];
	return self;
}

- (id)andThrow:(NSException *)anException
{
	[invocationHandlers addObject:[[[OCMExceptionReturnValueProvider alloc] initWithValue:anException] autorelease]];
	return self;
}

- (id)andPost:(NSNotification *)aNotification
{
	[invocationHandlers addObject:[[[OCMNotificationPoster alloc] initWithNotification:aNotification] autorelease]];
	return self;
}

- (id)andCall:(SEL)selector onObject:(id)anObject
{
	[invocationHandlers addObject:[[[OCMIndirectReturnValueProvider alloc] initWithProvider:anObject andSelector:selector] autorelease]];
	return self;
}

#if NS_BLOCKS_AVAILABLE

- (id)andDo:(void (^)(NSInvocation *))aBlock 
{
	[invocationHandlers addObject:[[[OCMBlockCaller alloc] initWithCallBlock:aBlock] autorelease]];
	return self;
}

#endif

- (id)andForwardToRealObject
{
	[NSException raise:NSInternalInconsistencyException format:@"Method %@ can only be used with partial mocks.",
	 NSStringFromSelector(_cmd)];
	return self; // keep compiler happy
}

- (void)setInvocationHandlers:(NSArray *)invocationHandlersNew
{
    [invocationHandlersNew retain];
    [invocationHandlers release];
    invocationHandlers = [[NSMutableArray alloc] initWithArray:invocationHandlersNew];
    [invocationHandlersNew release];
}

- (NSArray *)invocationHandlers
{
	return invocationHandlers;
}


#pragma mark  Recording the actual invocation

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [signatureResolver methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	if(recordedInvocation != nil)
		[NSException raise:NSInternalInconsistencyException format:@"Recorder received two methods to record."];
	[anInvocation setTarget:nil];
	[anInvocation retainArguments];
	recordedInvocation = [anInvocation retain];
}

#pragma mark

- (id)chainedPropertyWithPath:(NSString*)keyPath terminalObjectClass:(Class) klass
{
    if (keyPath.length) {
        static NSString *const pathSeparator = @".";
        
        NSMutableArray *components  = [NSMutableArray arrayWithArray:[keyPath componentsSeparatedByString:pathSeparator]];
        NSMutableArray *stack = [NSMutableArray arrayWithCapacity:components.count];
        
        // last path component is the "real" expectation
        NSString *lastPath = components.lastObject;
        [components removeLastObject];
        
        id mock = nil;
        NSString *path = nil;
        
        for (NSUInteger i = components.count; i --> 0; ) {
            
            path = [components objectAtIndex:i];
            
            // Last object in chain - real mock returns actual value
            if (i == components.count - 1) {
                id realMock = [OCMockObject mockForClass:klass];
                
                // return value
                OCMockRecorder *recorder = [realMock stub];
                recorder.invocationHandlers = [invocationHandlers retain];
                self.invocationHandlers = nil;
                
                // invocation for the mock
                SEL sel = NSSelectorFromString(lastPath);
                NSMethodSignature *sig = [klass instanceMethodSignatureForSelector:sel];
                NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
                inv.selector = sel;
                [recorder forwardInvocation:inv];
                
                // now need a placeholder to return this...
                mock = [OCChainTampolineProxy placeholderReturningObject:realMock
                                                             forSelector:NSSelectorFromString(path)];
            }
            else if (i > 0) {
                // Mid in chain = placeholder object
                mock = [OCChainTampolineProxy placeholderReturningObject:[stack lastObject]
                                                             forSelector:NSSelectorFromString(path)];
            } else {
                // First in chain
                mock = [stack lastObject];
            }
            
            [stack addObject:mock];
        }
        
        // self returns the last mock for the last path
        invocationHandlers = [[NSMutableArray alloc] init];
        [self andReturn:mock];
        
        // the recorded invocation
        SEL sel = NSSelectorFromString(path);
        NSMethodSignature *sig = [signatureResolver methodSignatureForSelector:sel];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        inv.selector = sel;
        [self forwardInvocation:inv];
    }
    
    return self;
}

#pragma mark  Checking the invocation

- (BOOL)matchesInvocation:(NSInvocation *)anInvocation
{
	id  recordedArg, passedArg;
	int i, n;
	
	if([anInvocation selector] != [recordedInvocation selector])
		return NO;
	
	n = (int)[[recordedInvocation methodSignature] numberOfArguments];
	for(i = 2; i < n; i++)
	{
		recordedArg = [recordedInvocation getArgumentAtIndexAsObject:i];
		passedArg = [anInvocation getArgumentAtIndexAsObject:i];

		if([recordedArg isProxy])
		{
			if(![recordedArg isEqual:passedArg])
				return NO;
			continue;
		}
		
		if([recordedArg isKindOfClass:[NSValue class]])
			recordedArg = [OCMArg resolveSpecialValues:recordedArg];
		
		if([recordedArg isKindOfClass:[OCMConstraint class]])
		{	
			if([recordedArg evaluate:passedArg] == NO)
				return NO;
		}
		else if([recordedArg isKindOfClass:[OCMPassByRefSetter class]])
		{
            id valueToSet = [(OCMPassByRefSetter *)recordedArg value];
			// side effect but easier to do here than in handleInvocation
            if(![valueToSet isKindOfClass:[NSValue class]])
                *(id *)[passedArg pointerValue] = valueToSet;
            else
                [(NSValue *)valueToSet getValue:[passedArg pointerValue]];
		}
		else if([recordedArg conformsToProtocol:objc_getProtocol("HCMatcher")])
		{
			if([recordedArg matches:passedArg] == NO)
				return NO;
		}
		else
		{
			if(([recordedArg class] == [NSNumber class]) && 
				([(NSNumber*)recordedArg compare:(NSNumber*)passedArg] != NSOrderedSame))
				return NO;
			if(([recordedArg isEqual:passedArg] == NO) &&
				!((recordedArg == nil) && (passedArg == nil)))
				return NO;
		}
	}
	return YES;
}




@end
