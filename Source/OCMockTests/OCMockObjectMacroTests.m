//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>


@protocol TestProtocolForMacroTesting
- (NSString *)stringValue;
@end

@interface TestClassForMacroTesting : NSObject <TestProtocolForMacroTesting>

@end

@implementation TestClassForMacroTesting

- (NSString *)stringValue
{
    return nil;
}

@end



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
    id mock = OCMPartialMock([[[TestClassForMacroTesting alloc] init] autorelease]);

    __block BOOL didCallBlock = NO;
    void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation)
    {
        didCallBlock = YES;
    };

    OCMStub([mock stringValue]).andDo(theBlock).andReturn(@"TEST_STRING");

    NSString *actual = [mock stringValue];

    XCTAssertTrue(didCallBlock, @"Should have called block");
    XCTAssertEqualObjects(@"TEST_STRING", actual, @"Should have returned stubbed value");
}

- (void)testSetsUpExpectations
{
    id mock = OCMProtocolMock(@protocol(TestProtocolForMacroTesting));

    OCMExpect([mock stringValue]).andReturn(@"TEST_STRING");

    XCTAssertThrows([mock verify], @"Should have complained about expected method not being invoked");

    XCTAssertEqual([mock stringValue], @"TEST_STRING", @"Should have stubbed method, too");
    XCTAssertNoThrow([mock verify], @"Should have accepted invocation as matching expectation");
}

@end
