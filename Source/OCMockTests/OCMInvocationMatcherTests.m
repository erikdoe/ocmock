//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import <OCMock/OCMArg.h>
#import "OCMInvocationMatcher.h"

@interface TestClassForRecorder : NSObject

- (void)methodWithInt:(int)i andObject:(id)o;

@end

@implementation TestClassForRecorder

- (void)methodWithInt:(int)i andObject:(id)o
{
}

@end

@interface OCMInvocationMatcherTests : XCTestCase

@end

@implementation OCMInvocationMatcherTests


- (NSInvocation *)invocationForTargetClass:(Class)aClass selector:(SEL)aSelector
{
    NSMethodSignature *signature = [aClass instanceMethodSignatureForSelector:aSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:aSelector];
    return invocation;
}

- (void)testOnlyMatchesInvocationWithRightArguments
{
    NSString *recorded = @"recorded";
    NSString *actual = @"actual";

    OCMInvocationMatcher *matcher = [[[OCMInvocationMatcher alloc] init] autorelease];
    NSInvocation *recordedInvocation = [self invocationForTargetClass:[NSString class] selector:@selector(initWithString:)];
    [recordedInvocation setArgument:&recorded atIndex:2];
    [matcher setInvocation:recordedInvocation];

    NSInvocation *testInvocation = [self invocationForTargetClass:[NSString class] selector:@selector(initWithString:)];
    [testInvocation setArgument:&actual atIndex:2];
    XCTAssertFalse([matcher matchesInvocation:testInvocation], @"Should not match.");
}

-(void)testSelectivelyIgnoresNonObjectArguments
{
    id any = [OCMArg any];
    NSUInteger zero = 0;
    NSString *arg1 = @"I (.*) mocks.";
    NSUInteger arg2 = NSRegularExpressionSearch;

    OCMInvocationMatcher *matcher = [[[OCMInvocationMatcher alloc] init] autorelease];
    NSInvocation *recordedInvocation = [self invocationForTargetClass:[NSString class] selector:@selector(rangeOfString:options:)];
    [recordedInvocation setArgument:&any atIndex:2];
    [recordedInvocation setArgument:&zero atIndex:3];
    [matcher setInvocation:recordedInvocation];
    [matcher setIngoreNonObjectArgs:YES];

    NSInvocation *testInvocation = [self invocationForTargetClass:[NSString class] selector:@selector(rangeOfString:options:)];
    [testInvocation setArgument:&arg1 atIndex:2];
    [testInvocation setArgument:&arg2 atIndex:3];
    XCTAssertTrue([matcher matchesInvocation:testInvocation], @"Should match.");
}

-(void)testSelectivelyIgnoresNonObjectArgumentsAndStillFailsWhenFollowingObjectArgsDontMatch
{
    int arg1 = 17;
    NSString *recorded = @"recorded";
    NSString *actual = @"actual";

    OCMInvocationMatcher *matcher = [[[OCMInvocationMatcher alloc] init] autorelease];
    NSInvocation *recordedInvocation = [self invocationForTargetClass:[TestClassForRecorder class] selector:@selector(methodWithInt:andObject:)];
    [recordedInvocation setArgument:&arg1 atIndex:2];
    [recordedInvocation setArgument:&recorded atIndex:3];
    [matcher setInvocation:recordedInvocation];
    [matcher setIngoreNonObjectArgs:YES];

    NSInvocation *testInvocation = [self invocationForTargetClass:[TestClassForRecorder class] selector:@selector(methodWithInt:andObject:)];
    [testInvocation setArgument:&arg1 atIndex:2];
    [testInvocation setArgument:&actual atIndex:3];
    XCTAssertFalse([matcher matchesInvocation:testInvocation], @"Should not match.");
}

@end
