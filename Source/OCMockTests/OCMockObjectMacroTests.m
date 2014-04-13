//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>


@interface OCMockObjectMacroTests : XCTestCase
{
    BOOL        shouldCaptureFailure;
    NSString    *reportedDescription;
    NSString    *reportedFile;
    NSUInteger  reportedLine;
}

@end


@implementation OCMockObjectMacroTests

- (void)recordFailureWithDescription:(NSString *)description inFile:(NSString *)file atLine:(NSUInteger)line expected:(BOOL)expected
{
    if(shouldCaptureFailure)
    {
        reportedDescription = description;
        reportedFile = file;
        reportedLine = line;
    }
    else
    {
        [super recordFailureWithDescription:description inFile:file atLine:line expected:expected];
    }
}


- (void)testReportsVerifyFailureWithCorrectLocation
{
    id mock = OCMClassMock([NSString class]);
    
    [[mock expect] lowercaseString];
    
    shouldCaptureFailure = YES;
    OCMVerify(mock); const char *expectedFile = __FILE__; int expectedLine = __LINE__;
    shouldCaptureFailure = NO;
    
    XCTAssertNotNil(reportedDescription, @"Should have recorded a failure with description.");
    XCTAssertEqualObjects([NSString stringWithUTF8String:expectedFile], reportedFile, @"Should have reported correct file.");
    XCTAssertEqual(expectedLine, (int)reportedLine, @"Should have reported correct line");
}

- (void)testReportsIgnoredExceptionsAtVerifyLocation
{
    id mock = OCMClassMock([NSString class]);
    
    [[mock reject] lowercaseString];

    @try
    {
        [mock lowercaseString];
    }
    @catch (NSException *exception)
    {
        // ignore; the mock will rethrow this in verify
    }

    shouldCaptureFailure = YES;
    OCMVerify(mock); const char *expectedFile = __FILE__; int expectedLine = __LINE__;
    shouldCaptureFailure = NO;
    
    XCTAssertTrue([reportedDescription rangeOfString:@"ignored"].location != NSNotFound, @"Should have reported ignored exceptions.");
    XCTAssertEqualObjects([NSString stringWithUTF8String:expectedFile], reportedFile, @"Should have reported correct file.");
    XCTAssertEqual(expectedLine, (int)reportedLine, @"Should have reported correct line");
}


- (void)testSetsUpStubsForCorrectMethods
{
    id mock = OCMStrictClassMock([NSString class]);

    OCMStub([mock uppercaseString]).andReturn(@"TEST_STRING");

    XCTAssertEqualObjects(@"TEST_STRING", [mock uppercaseString], @"Should have returned stubbed value");
    XCTAssertThrows([mock lowercaseString]);
}


- (void)testCanChainPropertyBasedActions
{
    id mock = OCMStrictClassMock([NSString class]);

    __block BOOL didCallBlock = NO;
    void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation)
    {
        didCallBlock = YES;
    };

    OCMStub([mock uppercaseString]).andDo(theBlock).andReturn(@"TEST_STRING");

    NSString *actual = [mock uppercaseString];

    XCTAssertTrue(didCallBlock, @"Should have called block");
    XCTAssertEqualObjects(@"TEST_STRING", actual, @"Should have returned stubbed value");
}

- (void)testSetsUpExpectations
{
    id mock = OCMClassMock([NSString class]);

    OCMExpect([mock uppercaseString]).andReturn(@"TEST_STRING");

    XCTAssertThrows([mock verify], @"Should have complained about expected method not being invoked");

    XCTAssertEqual([mock uppercaseString], @"TEST_STRING", @"Should have stubbed method, too");
    XCTAssertNoThrow([mock verify], @"Should have accepted invocation as matching expectation");
}

@end
