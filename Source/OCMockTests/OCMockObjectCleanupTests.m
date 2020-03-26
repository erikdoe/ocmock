/*
 *  Copyright (c) 2015-2020 Erik Doernenburg and contributors
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

// Tests for mocks being stopped by the XCTestObserver that we register in OCMockObject.
@interface OCMockObjectCleanupTests : XCTestCase
@end

static id caseMock;
static id suiteMock;
static id crossSuiteMock1;
static id crossSuiteMock2;
static id subSuiteMock;

@implementation OCMockObjectCleanupTests

+ (XCTestSuite *)defaultTestSuite {
    XCTestSuite *suite = [[XCTestSuite alloc] initWithName:@"OCMockObjectCleanupTestsMetaSuite"];
    XCTestSuite *suite1 = [super defaultTestSuite];
    XCTestSuite *subsuite = [super defaultTestSuite];
    [suite1 addTest:subsuite];
    XCTestSuite *suite2 = [super defaultTestSuite];
    [suite addTest:suite1];
    [suite addTest:suite2];
    return suite;
}

+ (void)setUp
{
    suiteMock = [OCMockObject mockForClass:[NSString class]];
    OCMStub([suiteMock intValue]).andReturn(42);
    caseMock = nil;
    if (!crossSuiteMock1) {
        crossSuiteMock1 = [OCMockObject mockForClass:[NSString class]];
        OCMStub([crossSuiteMock1 uppercaseString]).andReturn(@"crossSuiteMock1");
    }
    else if (crossSuiteMock1 && !subSuiteMock && !crossSuiteMock2)
    {
        subSuiteMock = [OCMockObject mockForClass:[NSString class]];
        OCMStub([subSuiteMock uppercaseString]).andReturn(@"subSuiteMock");
    }
    else if (crossSuiteMock1 && subSuiteMock && !crossSuiteMock2)
    {
        crossSuiteMock2 = [OCMockObject mockForClass:[NSString class]];
        OCMStub([crossSuiteMock2 uppercaseString]).andReturn(@"crossSuiteMock2");
    } else {
        abort();
    }
}

#pragma mark   Tests suite mocks survive across test cases

- (void)testSuiteMockWorksHere
{
    // Verify that a testSuite Mock made in +setUp doesn't get cleaned up until test suite is done.
    // By verifying in two test cases we know this is true (See testSuiteMockWorksAndHere).
    XCTAssertEqual([suiteMock intValue], 42);
}

- (void)testSuiteMockWorksAndHere
{
    // Verify that a testSuite Mock made in +setUp doesn't get cleaned up until test suite is done.
    // By verifying in two test cases we know this is true (See testSuiteMockWorksHere).
    XCTAssertEqual([suiteMock intValue], 42);
}

#pragma mark   Tests suite mocks fail across test suites

- (void)testCrossSuiteMockWorksHere
{
    // Verify that a mock set up in one suite doesn't propagate over to another suite.
    if (crossSuiteMock1 && !subSuiteMock && !crossSuiteMock2)
    {
        XCTAssertEqual([crossSuiteMock1 uppercaseString], @"crossSuiteMock1");
    }
    else if (crossSuiteMock1 && subSuiteMock && !crossSuiteMock2)
    {
        XCTAssertEqual([crossSuiteMock1 uppercaseString], @"crossSuiteMock1");
        XCTAssertEqual([subSuiteMock uppercaseString], @"subSuiteMock");
    }
    else if (crossSuiteMock1 && subSuiteMock && crossSuiteMock2)
    {
        XCTAssertThrows([crossSuiteMock1 uppercaseString],
                        @"Expected a throw here because the caseMock set up in "
                        @"testCaseMockFailsOrHere should have had stopMock called on it");
        XCTAssertThrows([subSuiteMock uppercaseString],
                        @"Expected a throw here because the caseMock set up in "
                        @"testCaseMockFailsOrHere should have had stopMock called on it");
        XCTAssertEqual([crossSuiteMock2 uppercaseString], @"crossSuiteMock2");
    }
    else
    {
        XCTFail(@"Should never have get here.");
    }
}

#pragma mark   Tests case mocks get stopped across test cases

- (void)setUpCaseMock
{
    caseMock = [OCMockObject mockForClass:[NSString class]];
    OCMStub([caseMock intValue]).andReturn(42);
}

- (void)testCaseMockFailsEitherHere
{
    // Set up a mock here that should get cleaned up (but the global pointer will still be non-nil)
    // or test that the mock set up in testCaseMockFailsOrHere has had stop mocking called on it.
    if (!caseMock)
    {
        [self setUpCaseMock];
    }
    else
    {
        XCTAssertThrows([caseMock intValue],
                        @"Expected a throw here because the caseMock set up in "
                        @"testCaseMockFailsOrHere should have had stopMock called on it");
    }
}

- (void)testCaseMockFailsOrHere
{
    // Set up a mock here that should get cleaned up (but the global pointer will still be non-nil)
    // or test that the mock set up in testCaseMockFailsOrHere has had stop mocking called on it.
    if (!caseMock)
    {
        [self setUpCaseMock];
    }
    else
    {
        XCTAssertThrows([caseMock intValue],
                        @"Expected a throw here because the caseMock set up in "
                        @"testCaseMockFailsEitherHere should have had stopMock called on it");
    }
}


@end
