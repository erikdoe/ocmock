/*
 *  Copyright (c) 2004-2020 Erik Doernenburg and contributors
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

#import "OCMockObject.h"
#import "OCClassMockObject.h"
#import "OCProtocolMockObject.h"
#import "OCPartialMockObject.h"
#import "OCObserverMockObject.h"
#import "OCMExceptionReturnValueProvider.h"
#import "OCMExpectationRecorder.h"
#import "OCMInvocationExpectation.h"
#import "OCMLocation.h"
#import "OCMMacroState.h"
#import "OCMQuantifier.h"
#import "OCMVerifier.h"
#import "OCMFunctionsPrivate.h"
#import "NSInvocation+OCMAdditions.h"

@class XCTestCase;
@class XCTest;

// gMocksToStopRecorders is a stack of recorders that gets added to and removed from
// as we enter test suite/case scopes.
// Controlled by OCMockXCTestObserver.
static NSMutableArray<NSHashTable<OCMockObject *> *> *gMocksToStopRecorders;

// Flag that controls whether we should be asserting after stopmocking is called.
// Controlled by OCMockXCTestObserver.
static BOOL gAssertOnCallsAfterStopMocking;

// Flag that tracks if we are stopping the mocks.
static BOOL gStoppingMocks = NO;

@implementation OCMockObject

#pragma mark  Class initialisation

+ (void)initialize
{
    if([[NSInvocation class] instanceMethodSignatureForSelector:@selector(getArgumentAtIndexAsObject:)] == NULL)
    {
        [NSException raise:NSInternalInconsistencyException format:@"** Expected method not present; the method getArgumentAtIndexAsObject: is not implemented by NSInvocation. If you see this exception it is likely that you are using the static library version of OCMock and your project is not configured correctly to load categories from static libraries. Did you forget to add the -ObjC linker flag?"];
    }
}

#pragma mark  Mock cleanup recording

+ (void)recordAMockToStop:(OCMockObject *)mock
{
  @synchronized(self)
  {
    if(gStoppingMocks)
    {
      [NSException raise:NSInternalInconsistencyException format:@"Attempting to add a mock while mocks are being stopped."];
    }
    [[gMocksToStopRecorders lastObject] addObject:mock];
  }
}

+ (void)removeAMockToStop:(OCMockObject *)mock
{
  @synchronized(self)
  {
    if(gStoppingMocks)
    {
      [NSException raise:NSInternalInconsistencyException format:@"Attempting to remove a mock while mocks are being stopped."];
    }
    [[gMocksToStopRecorders lastObject] removeObject:mock];
  }
}

+ (void)stopAllCurrentMocks
{
  @synchronized(self)
  {
    gStoppingMocks = YES;
    NSHashTable<OCMockObject *> *recorder = [gMocksToStopRecorders lastObject];
    for (OCMockObject *mock in recorder)
    {
      [mock stopMocking];
    }
    [recorder removeAllObjects];
    gStoppingMocks = NO;
  }
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
    // check if we are called from inside a macro
    OCMRecorder *recorder = [[OCMMacroState globalState] recorder];
    if(recorder != nil)
    {
        [recorder setMockObject:self];
        return (id)[recorder init];
    }

	// skip initialisation when init is called again, which can happen when stubbing alloc/init
    if(stubs != nil)
    {
        return self;
    }

    if([self class] == [OCMockObject class])
    {
        [NSException raise:NSInternalInconsistencyException format:@"*** Cannot create instances of OCMockObject. Please use one of the subclasses."];
    }

	// no [super init], we're inheriting from NSProxy
	expectationOrderMatters = NO;
	stubs = [[NSMutableArray alloc] init];
	expectations = [[NSMutableArray alloc] init];
	exceptions = [[NSMutableArray alloc] init];
    invocations = [[NSMutableArray alloc] init];
    [OCMockObject recordAMockToStop:self];
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
    [self assertInvocationsArrayIsPresent];
    @synchronized(stubs)
    {
        [stubs addObject:aStub];
    }
}

- (OCMInvocationStub *)stubForInvocation:(NSInvocation *)anInvocation
{
    @synchronized(stubs)
    {
        for(OCMInvocationStub *stub in stubs)
            if([stub matchesInvocation:anInvocation])
                return stub;
        return nil;
    }
}

- (void)addExpectation:(OCMInvocationExpectation *)anExpectation
{
    @synchronized(expectations)
    {
        [expectations addObject:anExpectation];
    }
}

- (void)assertInvocationsArrayIsPresent
{
    if(invocations == nil)
    {
        [OCMockObject logMatcherIssue:@"** Cannot use mock object %@ at %p. This error usually occurs when a mock object is used after stopMocking has been called on it. In most cases it is not necessary to call stopMocking. If you know you have to, please make sure that the mock object is not used afterwards.", [self description], (void *)self];
    }
}

- (void)addInvocation:(NSInvocation *)anInvocation
{
    @synchronized(invocations)
    {
        // We can't do a normal retain arguments on anInvocation because its target/arguments/return
        // value could be self. That would produce a retain cycle self->invocations->anInvocation->self.
        // However we need to retain everything on anInvocation that isn't self because we expect them to
        // stick around after this method returns. Use our special method to retain just what's needed.
        // This still doesn't completely prevent retain cycles since any of the arguments could have a
        // strong reference to self. Those will have to be broken with manual calls to -stopMocking.
        [anInvocation retainObjectArgumentsExcludingObject:self];
        [invocations addObject:anInvocation];
    }
}

+ (void)logMatcherIssue:(NSString *)format, ...
{
    if(gAssertOnCallsAfterStopMocking)
    {
        va_list args;
        va_start(args, format);
        [NSException raise:NSInternalInconsistencyException format:format arguments:args];
        va_end(args);
    }
}

#pragma mark  Public API

- (void)setExpectationOrderMatters:(BOOL)flag
{
    expectationOrderMatters = flag;
}

- (void)stopMocking
{
    // invocations can contain objects that clients expect to be deallocated by now,
    // and they can also have a strong reference to self, creating a retain cycle. Get
    // rid of all of the invocations to hopefully let their objects deallocate, and to
    // break any retain cycles involving self.
    @synchronized(invocations)
    {
        [invocations removeAllObjects];
        [invocations autorelease];
        invocations = nil;
    }
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
    @synchronized(expectations)
    {
        for(OCMInvocationExpectation *e in expectations)
        {
            if(![e isSatisfied])
                [unsatisfiedExpectations addObject:e];
        }
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

    OCMInvocationExpectation *firstException = nil;
    @synchronized(exceptions)
    {
        firstException = [exceptions.firstObject retain];
    }
    if(firstException)
	{
        NSString *description = [NSString stringWithFormat:@"%@: %@ (This is a strict mock failure that was ignored when it actually occurred.)",
         [self description], [firstException description]];
        OCMReportFailure(location, description);
	}
    [firstException release];

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
        @synchronized(expectations)
        {
            BOOL allExpectationsAreMatchAndReject = YES;
            for(OCMInvocationExpectation *expectation in expectations)
            {
                if(![expectation isMatchAndReject])
                {
                    allExpectationsAreMatchAndReject = NO;
                    break;
                }
            }
            if(allExpectationsAreMatchAndReject)
                break;
        }
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:MIN(step, delay)]];
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
    [self verifyInvocation:matcher withQuantifier:nil atLocation:location];
}

- (void)verifyInvocation:(OCMInvocationMatcher *)matcher withQuantifier:(OCMQuantifier *)quantifier atLocation:(OCMLocation *)location
{
    NSUInteger count = 0;
    [self assertInvocationsArrayIsPresent];
    @synchronized(invocations)
    {
        for(NSInvocation *invocation in invocations)
        {
            if([matcher matchesInvocation:invocation])
                count += 1;
        }
    }
    if(quantifier == nil)
        quantifier = [OCMQuantifier atLeast:1];
    if(![quantifier isValidCount:count])
    {
        NSString *description = [self descriptionForVerificationFailureWithMatcher:matcher quantifier:quantifier invocationCount:count];
        OCMReportFailure(location, description);
    }
}

- (NSString *)descriptionForVerificationFailureWithMatcher:(OCMInvocationMatcher *)matcher quantifier:(OCMQuantifier *)quantifier invocationCount:(NSUInteger)count
{
    NSString *actualDescription = nil;
    switch(count)
    {
        case 0:  actualDescription = @"not invoked";  break;
        case 1:  actualDescription = @"invoked once"; break;
        default: actualDescription = [NSString stringWithFormat:@"invoked %lu times", (unsigned long)count]; break;
    }

    return [NSString stringWithFormat:@"%@: Method `%@` was %@; but was expected %@.",
            [self description], [matcher description], actualDescription, [quantifier description]];
}


#pragma mark  Handling invocations

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if([OCMMacroState globalState] != nil)
    {
        OCMRecorder *recorder = [[OCMMacroState globalState] recorder];
        [recorder setMockObject:self];
        // In order for ARC to work correctly, the recorder has to set up return values for
        // methods in the init family of methods. If the mock forwards a method to the recorder
        // that it will record, i.e. a method that the recorder does not implement, then the
        // recorder must set the mock as the return value. Otherwise it must use itself.
        [recorder setShouldReturnMockFromInit:(class_getInstanceMethod(object_getClass(recorder), aSelector) == NO)];
        return recorder;
    }
    return nil;
}


- (BOOL)handleSelector:(SEL)sel
{
    @synchronized(stubs)
    {
        for(OCMInvocationStub *recorder in stubs)
            if([recorder matchesSelector:sel])
                return YES;
    }
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
        if([[e name] isEqualToString:OCMStubbedException])
        {
            e = [[e userInfo] objectForKey:@"exception"];
        }
        else
        {
            // add non-stubbed method to list of exceptions to be re-raised in verify
            @synchronized(exceptions)
            {
                [exceptions addObject:e];
            }
        }
        [e raise];
    }
}

- (BOOL)handleInvocation:(NSInvocation *)anInvocation
{
    [self assertInvocationsArrayIsPresent];
    [self addInvocation:anInvocation];

    OCMInvocationStub *stub = [self stubForInvocation:anInvocation];
    if(stub == nil)
        return NO;

    // Retain the stub in case it ends up being removed because we still need it at the end for handleInvocation:
    [stub retain];

    BOOL removeStub = NO;
    @synchronized(expectations)
    {
        if([expectations containsObject:stub])
        {
            OCMInvocationExpectation *expectation = [self _nextExpectedInvocation];
            if(expectationOrderMatters && (expectation != stub))
            {
                [NSException raise:NSInternalInconsistencyException format:@"%@: unexpected method invoked: %@\n\texpected:\t%@",
                             [self description], [stub description], [[expectations objectAtIndex:0] description]];
            }

            // We can't check isSatisfied yet, since the stub won't be satisfied until we call
            // handleInvocation: since we'll still have the current expectation in the expectations array, which
            // will cause an exception if expectationOrderMatters is YES and we're not ready for any future
            // expected methods to be called yet
            if(![(OCMInvocationExpectation *)stub isMatchAndReject])
            {
                [expectations removeObject:stub];
                removeStub = YES;
            }
        }
    }
    if(removeStub)
    {
        @synchronized(stubs)
        {
            [stubs removeObject:stub];
        }
    }

    @try
    {
        [stub handleInvocation:anInvocation];
    }
    @finally
    {
        [stub release];
    }

    return YES;
}

// Must be synchronized on expectations when calling this method.
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
		  [OCMockObject logMatcherIssue:@"%@: unexpected method invoked: %@ %@",
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
    NSArray *stubsCopy = nil;
    @synchronized(stubs)
    {
        stubsCopy = [stubs copy];
    }
    for(OCMStubRecorder *stub in stubsCopy)
    {
        BOOL expectationsContainStub = NO;
        @synchronized(expectations)
        {
            expectationsContainStub = [expectations containsObject:stub];
        }

		NSString *prefix = @"";

		if(onlyExpectations)
		{
			if(expectationsContainStub == NO)
				continue;
		}
		else
		{
			if(expectationsContainStub)
				prefix = @"expected:\t";
			else
				prefix = @"stubbed:\t";
		}
		[outputString appendFormat:@"\n\t%@%@", prefix, [stub description]];
	}
    [stubsCopy release];
	return outputString;
}


@end

/**
 * The observer gets installed the first time a mock object is created (see +[OCMockObject initialize]
 * It stops all the mocks that are still active when the testcase has finished.
 * In many cases this should break a lot of retain loops and allow mocks to be freed.
 * More importantly this will remove mocks that have mocked a class method and persist across testcases.
 * It intentionally turns off the assert that fires when calling a mock after stopMocking has been
 * called on it, because when we are doing cleanup there are cases in dealloc methods where a mock
 * may be called. We allow the "assert off" state to persist beyond the end of -testCaseDidFinish
 * because objects may be destroyed by the autoreleasepool that wraps the entire test and this may
 * cause  mocks to be called. The state is global (instead of per mock) because we want to be able
 * to catch the case where a mock is trapped by some global state (e.g. a non-mock singleton) and
 * then that singleton is used in a later test and attempts to call a stopped mock.
 **/
@interface OCMockXCTestObserver : NSObject
@end

// "Fake" Protocol so we can avoid having to link to XCTest, but not get warnings about
// methods not being declared.
@protocol OCMockXCTestObservation
+ (id)sharedTestObservationCenter;
- (void)addTestObserver:(id)observer;
@end

@implementation OCMockXCTestObserver

+ (void)load
{
    gMocksToStopRecorders = [[NSMutableArray alloc] init];
    gAssertOnCallsAfterStopMocking = YES;
    Class xctest = NSClassFromString(@"XCTestObservationCenter");
    if (xctest)
    {
        // If XCTest is available, we set up an observer to stop our mocks for us.
        [[xctest sharedTestObservationCenter] addTestObserver:[[OCMockXCTestObserver alloc] init]];
    }
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    // This allows us to avoid linking XCTest into OCMock.
    return strcmp(protocol_getName(aProtocol), "XCTestObservation") == 0;
}

- (void)addRecorder
{
    gAssertOnCallsAfterStopMocking = YES;
    NSHashTable<OCMockObject *> *recorder = [NSHashTable weakObjectsHashTable];
    [gMocksToStopRecorders addObject:recorder];
}

- (void)finalizeRecorder
{
    gAssertOnCallsAfterStopMocking = NO;
    [OCMockObject stopAllCurrentMocks];
    [gMocksToStopRecorders removeLastObject];
}

- (void)testSuiteWillStart:(XCTestCase *)testCase
{
    [self addRecorder];
}

- (void)testSuiteDidFinish:(XCTestCase *)testCase
{
    [self finalizeRecorder];
}

- (void)testCaseWillStart:(XCTestCase *)testCase
{
    [self addRecorder];
}

- (void)testCaseDidFinish:(XCTestCase *)testCase
{
    [self finalizeRecorder];
}

@end
