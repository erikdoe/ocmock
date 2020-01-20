/*
 *  Copyright (c) 016 Erik Doernenburg and contributors
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
#import <OCMock/OCMock.h>
#import "OCMQuantifier.h"


@interface TestClassForQuantifiers : NSObject

- (void)doStuff;

@end

@implementation TestClassForQuantifiers

- (void)doStuff
{
}

@end


@interface OCMQuantifierTests : XCTestCase
{
    BOOL    expectFailure;
    BOOL    didRecordFailure;
}

@end


@implementation OCMQuantifierTests

- (void)setUp
{
    expectFailure = NO;
}

- (void)recordFailureWithDescription:(NSString *)description inFile:(NSString *)file atLine:(NSUInteger)line expected:(BOOL)expected
{
    if(expectFailure)
    {
        didRecordFailure = YES;
    }
    else
    {
        [super recordFailureWithDescription:description inFile:file atLine:line expected:expected];
    }
}


- (void)testAtLeastThrowsWhenMinimumCountIsNotReached
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    
    [mock doStuff];
    
    XCTAssertThrows([[[mock verify] withQuantifier:[OCMQuantifier atLeast:2]] doStuff]);
}

- (void)testAtLeastMatchesMinimumCount
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    
    [mock doStuff];
    [mock doStuff];
    
    [[[mock verify] withQuantifier:[OCMQuantifier atLeast:2]] doStuff];
}

- (void)testAtLeastMatchesMoreThanMinimumCount
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    
    [mock doStuff];
    [mock doStuff];
    [mock doStuff];
    
    [[[mock verify] withQuantifier:[OCMQuantifier atLeast:2]] doStuff];
}

- (void)testAtMostMatchesUpToMaximumCount
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    
    [mock doStuff];

    [[[mock verify] withQuantifier:[OCMQuantifier atMost:1]] doStuff];
}

- (void)testAtMostThrowsWhenMaximumCountIsExceeded
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    
    [mock doStuff];
    [mock doStuff];
    
    XCTAssertThrows([[[mock verify] withQuantifier:[OCMQuantifier atMost:1]] doStuff]);
}

- (void)testNeverThrowsWhenInvocationsOccurred
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    
    [mock doStuff];

    XCTAssertThrows([[[mock verify] withQuantifier:[OCMQuantifier never]] doStuff]);
}


- (void)testQuantifierMacro
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);

    [mock doStuff];

    _OCMVerifyWithQuantifier([OCMQnt atLeastOnce], [mock doStuff]);
}

- (void)testQuantifierMacroAtLeast
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    [mock doStuff];
    [mock doStuff];
    OCMVerifyAtLeast(2, [mock doStuff]);
}

- (void)testQuantifierMacroAtLeastFailure
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    [mock doStuff];
    [mock doStuff];
    expectFailure = YES;
    OCMVerifyAtLeast(3, [mock doStuff]);
    expectFailure = NO;
    XCTAssertTrue(didRecordFailure);
}

- (void)testQuantifierMacroAtLeastOnce
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    [mock doStuff];
    [mock doStuff];
    OCMVerifyAtLeastOnce([mock doStuff]);
}


- (void)testQuantifierMacroAtMost
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    [mock doStuff];
    [mock doStuff];
    OCMVerifyAtMost(2, [mock doStuff]);
}

- (void)testQuantifierMacroAtMostFailure
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    [mock doStuff];
    [mock doStuff];
    expectFailure = YES;
    OCMVerifyAtMost(1, [mock doStuff]);
    expectFailure = NO;
    XCTAssertTrue(didRecordFailure);
}

- (void)testQuantifierMacroNever
{
    id mock = OCMClassMock([TestClassForQuantifiers class]);
    OCMVerifyNever([mock doStuff]);
}


@end

