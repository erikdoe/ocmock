/*
 *  Copyright (c) 2004-2021 Erik Doernenburg and contributors
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

#import <XCTest/XCTest.h>
#import "OCMConstraint.h"

@interface TestEqualityFake : NSObject
@property BOOL isValueEqual;
@end

@implementation TestEqualityFake

- (BOOL)isEqual:(id)object
{
  return self.isValueEqual;
}

@end

@interface OCMConstraintTests : XCTestCase
{
    BOOL didCallCustomConstraint;
}

@end


@implementation OCMConstraintTests

- (void)setUp
{
    didCallCustomConstraint = NO;
}

- (void)testAnyAcceptsAnything
{
    OCMConstraint *constraint = [[OCMAnyConstraint alloc] init];
    XCTAssertTrue([constraint evaluate:@"foo"], @"Should have accepted a value.");
    XCTAssertTrue([constraint evaluate:@"bar"], @"Should have accepted another value.");
    XCTAssertTrue([constraint evaluate:nil], @"Should have accepted nil.");
}

- (void)testIsNilAcceptsOnlyNil
{
    OCMConstraint *constraint = [[OCMIsNilConstraint alloc] init];

    XCTAssertFalse([constraint evaluate:@"foo"], @"Should not have accepted a value.");
    XCTAssertTrue([constraint evaluate:nil], @"Should have accepted nil.");
}

- (void)testIsNotNilAcceptsAnythingButNil
{
    OCMConstraint *constraint = [[OCMIsNotNilConstraint alloc] init];

    XCTAssertTrue([constraint evaluate:@"foo"], @"Should have accepted a value.");
    XCTAssertFalse([constraint evaluate:nil], @"Should not have accepted nil.");
}

- (void)testNotEqualAcceptsAnythingButValue
{
    OCMIsNotEqualConstraint *constraint = [[OCMIsNotEqualConstraint alloc] initWithTestValue:@"foo"];

    XCTAssertFalse([constraint evaluate:@"foo"], @"Should not have accepted value.");
    XCTAssertTrue([constraint evaluate:@"bar"], @"Should have accepted other value.");
    XCTAssertTrue([constraint evaluate:nil], @"Should have accepted nil.");

    constraint = [[OCMIsNotEqualConstraint alloc] initWithTestValue:nil];

    XCTAssertTrue([constraint evaluate:@"foo"], @"Should have accepted value.");
    XCTAssertFalse([constraint evaluate:nil], @"Should not have accepted nil.");
}

- (void)testEqualUsesTestValuesDefinitionOfEquality
{
    TestEqualityFake *testValue = [[TestEqualityFake alloc] init];
    testValue.isValueEqual = YES;

    TestEqualityFake *value = [[TestEqualityFake alloc] init];
    value.isValueEqual = NO;

    OCMIsEqualConstraint *constraint = [[OCMIsEqualConstraint alloc] initWithTestValue:testValue];
    XCTAssertTrue([constraint evaluate:value]);
}

- (void)testNotEqualUsesTestValuesDefinitionOfEquality
{
    TestEqualityFake *testValue = [[TestEqualityFake alloc] init];
    testValue.isValueEqual = NO;

    TestEqualityFake *value = [[TestEqualityFake alloc] init];
    value.isValueEqual = YES;

    OCMIsNotEqualConstraint *constraint = [[OCMIsNotEqualConstraint alloc] initWithTestValue:testValue];
    XCTAssertTrue([constraint evaluate:value]);
}

- (void)testEqualAcceptsNothingButValue
{
    OCMIsEqualConstraint *constraint = [[OCMIsEqualConstraint alloc] initWithTestValue:@"foo"];

    XCTAssertTrue([constraint evaluate:@"foo"], @"Should have accepted value.");
    XCTAssertFalse([constraint evaluate:@"bar"], @"Should not have accepted other value.");
    XCTAssertFalse([constraint evaluate:nil], @"Should not have accepted nil.");

    constraint = [[OCMIsEqualConstraint alloc] initWithTestValue:nil];

    XCTAssertFalse([constraint evaluate:@"foo"], @"Should not have accepted other value.");
    XCTAssertTrue([constraint evaluate:nil], @"Should have accepted nil.");
}


- (BOOL)checkArg:(id)theArg
{
    didCallCustomConstraint = YES;
    return [theArg isEqualToString:@"foo"];
}

- (void)testUsesPlainMethod
{
    OCMConstraint *constraint = CONSTRAINT(@selector(checkArg:));

    XCTAssertTrue([constraint evaluate:@"foo"], @"Should have accepted foo.");
    XCTAssertTrue(didCallCustomConstraint, @"Should have used custom method.");
    XCTAssertFalse([constraint evaluate:@"bar"], @"Should not have accepted bar.");
}


- (BOOL)checkArg:(id)theArg withValue:(id)value
{
    didCallCustomConstraint = YES;
    return [theArg isEqual:value];
}

- (void)testUsesMethodWithValue
{
    OCMConstraint *constraint = CONSTRAINTV(@selector(checkArg:withValue:), @"foo");

    XCTAssertTrue([constraint evaluate:@"foo"], @"Should have accepted foo.");
    XCTAssertTrue(didCallCustomConstraint, @"Should have used custom method.");
    XCTAssertFalse([constraint evaluate:@"bar"], @"Should not have accepted bar.");
}


- (void)testRaisesExceptionWhenConstraintMethodDoesNotTakeArgument
{
    XCTAssertThrows(CONSTRAINTV(@selector(checkArg:), @"bar"), @"Should have thrown for invalid constraint method.");
}


- (void)testRaisesExceptionOnUnknownSelector
{
    // We use a selector that this test does not implement
    XCTAssertThrows(CONSTRAINTV(@selector(arrayWithArray:), @"bar"), @"Should have thrown for unknown constraint method.");
}


- (void)testUsesBlock
{
    BOOL (^checkForFooBlock)(id) = ^(id value) {
        return [value isEqualToString:@"foo"];
    };

    OCMBlockConstraint *constraint = [[OCMBlockConstraint alloc] initWithConstraintBlock:checkForFooBlock];

    XCTAssertTrue([constraint evaluate:@"foo"], @"Should have accepted foo.");
    XCTAssertFalse([constraint evaluate:@"bar"], @"Should not have accepted bar.");
}

- (void)testBlockConstraintCanCaptureArgument
{
    __block NSString *captured;
    BOOL (^captureArgBlock)(id) = ^(id value) {
        captured = value;
        return YES;
    };

    OCMBlockConstraint *constraint = [[OCMBlockConstraint alloc] initWithConstraintBlock:captureArgBlock];

    [constraint evaluate:@"foo"];
    XCTAssertEqualObjects(@"foo", captured, @"Should have captured value from last invocation.");
    [constraint evaluate:@"bar"];
    XCTAssertEqualObjects(@"bar", captured, @"Should have captured value from last invocation.");
}

- (void)testEvaluateNilBlockReturnsNo
{
    OCMBlockConstraint *constraint = [[OCMBlockConstraint alloc] initWithConstraintBlock:nil];

    XCTAssertFalse([constraint evaluate:@"foo"]);
}

- (void)testEvaluateInvocationRetainsInvocation
{
  OCMInvocationConstraint *constraint;
  @autoreleasepool {
    SEL selector = @selector(checkArg:);
    NSInvocation *anInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
    [anInvocation setTarget:self];
    [anInvocation setSelector:selector];
    constraint = [[OCMInvocationConstraint alloc] initWithInvocation:anInvocation];
  }
  XCTAssertTrue([constraint evaluate:@"foo"]);
}

- (BOOL)methodWithNoArgs
{
  return YES;
}

- (void)testEvaluateInvocationThrowsForInvocationForMethodWithoutArgument
{
  SEL selector = @selector(methodWithNoArgs);
  NSInvocation *anInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
  [anInvocation setTarget:self];
  [anInvocation setSelector:selector];
  XCTAssertThrowsSpecificNamed([[OCMInvocationConstraint alloc] initWithInvocation:anInvocation], NSException, NSInvalidArgumentException);
}

- (BOOL)aMethodWithInt:(int)anInt
{
  return YES;
}

- (void)testEvaluateInvocationThrowsForInvocationForMethodWithoutObjectArgument
{
  SEL selector = @selector(aMethodWithInt:);
  NSInvocation *anInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
  [anInvocation setTarget:self];
  [anInvocation setSelector:selector];
  XCTAssertThrowsSpecificNamed([[OCMInvocationConstraint alloc] initWithInvocation:anInvocation], NSException, NSInvalidArgumentException);
}

- (void)aMethodThatDoesNotReturnBool:(id)anArg
{
}

- (void)testEvaluateInvocationThrowsForInvocationThatDoesNotReturnBool
{
  SEL selector = @selector(aMethodThatDoesNotReturnBool:);
  NSInvocation *anInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
  [anInvocation setTarget:self];
  [anInvocation setSelector:selector];
  XCTAssertThrowsSpecificNamed([[OCMInvocationConstraint alloc] initWithInvocation:anInvocation], NSException, NSInvalidArgumentException);
}

@end
