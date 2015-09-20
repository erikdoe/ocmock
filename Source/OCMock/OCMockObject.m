/*
 *  Copyright (c) 2004-2015 Erik Doernenburg and contributors
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

#import <OCMock/OCMockObject.h>
#import "OCClassMockObject.h"
#import "OCProtocolMockObject.h"
#import "OCPartialMockObject.h"
#import "OCObserverMockObject.h"
#import "OCMStubRecorder.h"
#import <OCMock/OCMLocation.h>
#import "NSInvocation+OCMAdditions.h"
#import "OCMInvocationMatcher.h"
#import "OCMMacroState.h"
#import "OCMFunctionsPrivate.h"
#import "OCMVerifier.h"
#import "OCMInvocationExpectation.h"
#import "OCMExpectationRecorder.h"


@implementation OCMockObject

#pragma mark  Class initialisation

+ (void)initialize
{
	if([[NSInvocation class] instanceMethodSignatureForSelector:@selector(getArgumentAtIndexAsObject:)] == NULL)
		[NSException raise:NSInternalInconsistencyException format:@"** Expected method not present; the method getArgumentAtIndexAsObject: is not implemented by NSInvocation. If you see this exception it is likely that you are using the static library version of OCMock and your project is not configured correctly to load categories from static libraries. Did you forget to add the -ObjC linker flag?"];
}


#pragma mark  Factory methods

+ (id)mockForClass:(Class)aClass
{
	return [[[OCClassMockObject alloc] initWithClass:aClass] autorelease];
}

+ (id)mockForProtocol:(Protocol *)aProtocol
{
	return [[[OCProtocolMockObject alloc] initWithProtocol:aProtocol] autorelease];
}

+ (id)partialMockForObject:(NSObject *)anObject
{
	return [[[OCPartialMockObject alloc] initWithObject:anObject] autorelease];
}


+ (id)niceMockForClass:(Class)aClass
{
	return [self _makeNice:[self mockForClass:aClass]];
}

+ (id)niceMockForProtocol:(Protocol *)aProtocol
{
	return [self _makeNice:[self mockForProtocol:aProtocol]];
}


+ (id)_makeNice:(OCMockObject *)mock
{
	mock->isNice = YES;
	return mock;
}


+ (id)observerMock
{
	return [[[OCObserverMockObject alloc] init] autorelease];
}


#pragma mark  Initialisers, description, accessors, etc.

- (instancetype)init
{
	// no [super init], we're inheriting from NSProxy
	expectationOrderMatters = NO;
	expectationOrderMattersThrowsException = YES;
	stubs = [[NSMutableArray alloc] init];
	expectations = [[NSMutableArray alloc] init];
	exceptions = [[NSMutableArray alloc] init];
    invocations = [[NSMutableArray alloc] init];
    return self;
}

- (void)dealloc
{
	[stubs release];
	[expectations release];
	[exceptions release];
    [invocations release];
	[super dealloc];
}

- (NSString *)description
{
	return @"OCMockObject";
}

- (void)addStub:(OCMInvocationStub *)aStub
{
    [stubs addObject:aStub];
}

- (void)addExpectation:(OCMInvocationExpectation *)anExpectation
{
    [expectations addObject:anExpectation];
}


#pragma mark  Public API

- (void)setExpectationOrderMatters:(BOOL)flag
{
    expectationOrderMatters = flag;
}

- (void)setExpectationOrderMattersThrowsException:(BOOL)flag
{
    expectationOrderMattersThrowsException = flag;
}

- (void)stopMocking
{
    // no-op for mock objects that are not class object or partial mocks
}


- (id)stub
{
	return [[[OCMStubRecorder alloc] initWithMockObject:self] autorelease];
}

- (id)expect
{
    return [[[OCMExpectationRecorder alloc] initWithMockObject:self] autorelease];
}

- (id)reject
{
	return [[self expect] never];
}


- (id)verify
{
    return [self verifyAtLocation:nil];
}

- (id)verifyAtLocation:(OCMLocation *)location
{
    NSMutableArray *unsatisfiedExpectations = [NSMutableArray array];
    for(OCMInvocationExpectation *e in expectations)
    {
        if(![e isSatisfied])
            [unsatisfiedExpectations addObject:e];
    }

	if([unsatisfiedExpectations count] == 1)
	{
        NSString *description = [NSString stringWithFormat:@"%@: expected method was not invoked: %@",
         [self description], [[unsatisfiedExpectations objectAtIndex:0] description]];
        OCMReportFailure(location, description);
	}
	else if([unsatisfiedExpectations count] > 0)
	{
		NSString *description = [NSString stringWithFormat:@"%@: %@ expected methods were not invoked: %@",
         [self description], @([unsatisfiedExpectations count]), [self _stubDescriptions:YES]];
        OCMReportFailure(location, description);
	}

	if([exceptions count] > 0)
	{
        NSString *description = [NSString stringWithFormat:@"%@: %@ (This is a strict mock failure that was ignored when it actually occured.)",
         [self description], [[exceptions objectAtIndex:0] description]];
        OCMReportFailure(location, description);
	}

    return [[[OCMVerifier alloc] initWithMockObject:self] autorelease];
}


- (void)verifyWithDelay:(NSTimeInterval)delay
{
    [self verifyWithDelay:delay atLocation:nil];
}

- (void)verifyWithDelay:(NSTimeInterval)delay atLocation:(OCMLocation *)location
{
    NSTimeInterval step = 0.01;
    while(delay > 0)
    {
        if([expectations count] == 0)
            break;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:step]];
        delay -= step;
        step *= 2;
    }
    [self verifyAtLocation:location];
}


#pragma mark Verify after running

- (void)verifyInvocation:(OCMInvocationMatcher *)matcher
{
    [self verifyInvocation:matcher atLocation:nil];
}

- (void)verifyInvocation:(OCMInvocationMatcher *)matcher atLocation:(OCMLocation *)location
{
    for(NSInvocation *invocation in invocations)
    {
        if([matcher matchesInvocation:invocation])
            return;
    }
    NSString *description = [NSString stringWithFormat:@"%@: Method %@ was not invoked.",
     [self description], [matcher description]];

    OCMReportFailure(location, description);
}


#pragma mark  Handling invocations

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if([OCMMacroState globalState] != nil)
    {
        OCMRecorder *recorder = [[OCMMacroState globalState] recorder];
        [recorder setMockObject:self];
        return recorder;
    }
    return nil;
}


- (BOOL)handleSelector:(SEL)sel
{
    for(OCMInvocationStub *recorder in stubs)
        if([recorder matchesSelector:sel])
            return YES;

    return NO;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    @try
    {
        if([self handleInvocation:anInvocation] == NO)
            [self handleUnRecordedInvocation:anInvocation];
    }
    @catch(NSException *e)
    {
        [exceptions addObject:e];
        if(expectationOrderMattersThrowsException)
            [e raise];
    }
}

- (BOOL)handleInvocation:(NSInvocation *)anInvocation
{
    [invocations addObject:anInvocation];

    OCMInvocationStub *stub = nil;
    for(stub in stubs)
    {
        // If the stub forwards its invocation to the real object, then we don't want to do handleInvocation: yet, since forwarding the invocation to the real object could call a method that is expected to happen after this one, which is bad if expectationOrderMatters is YES
        if([stub matchesInvocation:anInvocation])
            break;
    }
    // Retain the stub in case it ends up being removed from stubs and expectations, since we still have to call handleInvocation on the stub at the end
    [stub retain];
    if(stub == nil)
        return NO;

     if([expectations containsObject:stub])
     {
          OCMInvocationExpectation *expectation = [self _nextExpectedInvocation];
          if(expectationOrderMatters && (expectation != stub))
          {
               [NSException raise:NSInternalInconsistencyException format:@"%@: unexpected method invoked: %@\n\texpected:\t%@",
                            [self description], [stub description], [[expectations objectAtIndex:0] description]];
          }

          // We can't check isSatisfied yet, since the stub won't be satisfied until we call handleInvocation:, and we don't want to call handleInvocation: yes for the reason in the comment above, since we'll still have the current expectation in the expectations array, which will cause an exception if expectationOrderMatters is YES and we're not ready for any future expected methods to be called yet
          if(![(OCMInvocationExpectation *)stub isMatchAndReject])
          {
               [expectations removeObject:stub];
               [stubs removeObject:stub];
          }
     }
     [stub handleInvocation:anInvocation];
     [stub release];

     return YES;
}


- (OCMInvocationExpectation *)_nextExpectedInvocation
{
    for(OCMInvocationExpectation *expectation in expectations)
        if(![expectation isMatchAndReject])
            return expectation;
    return nil;
}

- (void)handleUnRecordedInvocation:(NSInvocation *)anInvocation
{
	if(isNice == NO)
	{
		[NSException raise:NSInternalInconsistencyException format:@"%@: unexpected method invoked: %@ %@",
                        [self description], [anInvocation invocationDescription], [self _stubDescriptions:NO]];
	}
}

- (void)doesNotRecognizeSelector:(SEL)aSelector __unused
{
    if([OCMMacroState globalState] != nil)
    {
        // we can't do anything clever with the macro state because we must raise an exception here
        [NSException raise:NSInvalidArgumentException format:@"%@: Cannot stub/expect/verify method '%@' because no such method exists in the mocked class.",
                        [self description], NSStringFromSelector(aSelector)];
    }
    else
    {
        [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: unrecognized selector sent to instance %p",
                        [self description], NSStringFromSelector(aSelector), (void *)self];
    }
}


#pragma mark  Helper methods

- (NSString *)_stubDescriptions:(BOOL)onlyExpectations
{
	NSMutableString *outputString = [NSMutableString string];
    for(OCMStubRecorder *stub in stubs)
    {
		NSString *prefix = @"";
		
		if(onlyExpectations)
		{
			if([expectations containsObject:stub] == NO)
				continue;
		}
		else
		{
			if([expectations containsObject:stub])
				prefix = @"expected:\t";
			else
				prefix = @"stubbed:\t";
		}
		[outputString appendFormat:@"\n\t%@%@", prefix, [stub description]];
	}
	return outputString;
}


@end
