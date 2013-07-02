//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMockRecorderTests.h"
#import <OCMock/OCMockRecorder.h>
#import "OCMReturnValueProvider.h"
#import "OCMExceptionReturnValueProvider.h"


@implementation OCMockRecorderTests

- (void)setUp
{
	NSMethodSignature *signature = [NSString instanceMethodSignatureForSelector:@selector(initWithString:)];
	testInvocation = [NSInvocation invocationWithMethodSignature:signature];
	[testInvocation setSelector:@selector(initWithString:)];
}


- (void)testStoresAndMatchesInvocation
{
    NSString *arg = @"I love mocks.";
	[testInvocation setArgument:&arg atIndex:2];

    OCMockRecorder *recorder = [[[OCMockRecorder alloc] initWithSignatureResolver:[NSString string]] autorelease];
	[(id)recorder initWithString:arg];

	STAssertTrue([recorder matchesInvocation:testInvocation], @"Should match.");
}


- (void)testOnlyMatchesInvocationWithRightArguments
{
    NSString *arg = @"I love mocks.";
	[testInvocation setArgument:&arg atIndex:2];

    OCMockRecorder *recorder = [[[OCMockRecorder alloc] initWithSignatureResolver:[NSString string]] autorelease];
	[(id)recorder initWithString:@"whatever"];
	
	STAssertFalse([recorder matchesInvocation:testInvocation], @"Should not match.");
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
