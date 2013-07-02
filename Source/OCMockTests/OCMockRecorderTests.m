//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMockRecorderTests.h"
#import <OCMock/OCMockRecorder.h>
#import "OCMReturnValueProvider.h"
#import "OCMExceptionReturnValueProvider.h"
#import "OCMArg.h"


@implementation OCMockRecorderTests


- (NSInvocation *)invocationForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [NSString instanceMethodSignatureForSelector:aSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:aSelector];
    return invocation;
}


- (void)testStoresAndMatchesInvocation
{
    NSString *arg = @"I love mocks.";

    OCMockRecorder *recorder = [[[OCMockRecorder alloc] initWithSignatureResolver:[NSString string]] autorelease];
	[(id)recorder initWithString:arg];

    NSInvocation *testInvocation = [self invocationForSelector:@selector(initWithString:)];
    [testInvocation setArgument:&arg atIndex:2];
	STAssertTrue([recorder matchesInvocation:testInvocation], @"Should match.");
}


- (void)testOnlyMatchesInvocationWithRightArguments
{
    NSString *arg = @"I love mocks.";

    OCMockRecorder *recorder = [[[OCMockRecorder alloc] initWithSignatureResolver:[NSString string]] autorelease];
	[(id)recorder initWithString:@"whatever"];

    NSInvocation *testInvocation = [self invocationForSelector:@selector(initWithString:)];
    [testInvocation setArgument:&arg atIndex:2];
	STAssertFalse([recorder matchesInvocation:testInvocation], @"Should not match.");
}

-(void)testSelectivelyIgnoresNonObjectArguments
{
    NSString *arg1 = @"I (.*) mocks.";
    NSUInteger arg2 = NSRegularExpressionSearch;

    OCMockRecorder *recorder = [[[OCMockRecorder alloc] initWithSignatureResolver:[NSString string]] autorelease];
    [(id)recorder rangeOfString:[OCMArg any] options:0];
    [recorder ignoringNonObjectArgs];

    NSInvocation *testInvocation = [self invocationForSelector:@selector(rangeOfString:options:)];
    [testInvocation setArgument:&arg1 atIndex:2];
    [testInvocation setArgument:&arg2 atIndex:3];
    STAssertTrue([recorder matchesInvocation:testInvocation], @"Should match.");
}


- (void)testAddsReturnValueProvider
{
    OCMockRecorder *recorder = [[[OCMockRecorder alloc] initWithSignatureResolver:[NSString string]] autorelease];
	[recorder andReturn:@"foo"];
    NSArray *handlerList = [recorder invocationHandlers];
	
	STAssertEquals((NSUInteger)1, [handlerList count], @"Should have added one handler.");
	STAssertEqualObjects([OCMReturnValueProvider class], [[handlerList objectAtIndex:0] class], @"Should have added correct handler.");
}

- (void)testAddsExceptionReturnValueProvider
{
    OCMockRecorder *recorder = [[[OCMockRecorder alloc] initWithSignatureResolver:[NSString string]] autorelease];
	[recorder andThrow:[NSException exceptionWithName:@"TestException" reason:@"A reason" userInfo:nil]];
    NSArray *handlerList = [recorder invocationHandlers];

	STAssertEquals((NSUInteger)1, [handlerList count], @"Should have added one handler.");
	STAssertEqualObjects([OCMExceptionReturnValueProvider class], [[handlerList objectAtIndex:0] class], @"Should have added correct handler.");
	
}

@end
