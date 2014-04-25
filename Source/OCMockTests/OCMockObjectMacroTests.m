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
    return @"FOO";
}

@end


// implemented in OCMockObjectClassMethodMockingTests

@interface TestClassWithClassMethods : NSObject
+ (NSString *)foo;
+ (NSString *)bar;
- (NSString *)bar;
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
    OCMVerifyAll(mock); const char *expectedFile = __FILE__; int expectedLine = __LINE__;
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
    OCMVerifyAll(mock); const char *expectedFile = __FILE__; int expectedLine = __LINE__;
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

- (void)testSetsUpStubsWithNonObjectReturnValues
{
    id mock = OCMStrictClassMock([NSString class]);

    OCMStub([mock boolValue]).andReturn(YES);

    XCTAssertEqual(1, [mock boolValue], @"Should have returned stubbed value");
}

- (void)testSetsUpStubsWithStructureReturnValues
{
    id mock = OCMStrictClassMock([NSString class]);

    NSRange expected = NSMakeRange(123, 456);
    OCMStub([mock rangeOfString:[OCMArg any]]).andReturn(expected);

    NSRange actual = [mock rangeOfString:@"substring"];
    XCTAssertEqual(123, actual.location, @"Should have returned stubbed value");
    XCTAssertEqual(456, actual.length, @"Should have returned stubbed value");
}

- (void)testCanUseVariablesInInvocationSpec
{
    id mock = OCMStrictClassMock([NSString class]);

    NSString *expected = @"foo";
    OCMStub([mock rangeOfString:expected]).andReturn(NSMakeRange(0, 3));

    XCTAssertThrows([mock rangeOfString:@"bar"], @"Should not have accepted invocation with non-matching arg.");
}

- (void)testSetsUpExceptionThrowing
{
    id mock = OCMClassMock([NSString class]);

    OCMStub([mock uppercaseString]).andThrow([NSException exceptionWithName:@"TestException" reason:@"Testing" userInfo:nil]);

    XCTAssertThrowsSpecificNamed([mock uppercaseString], NSException, @"TestException", @"Should have thrown correct exception");
}


- (void)testSetsUpNotificationPostingAndNotificationObserving
{
    id mock = OCMProtocolMock(@protocol(TestProtocolForMacroTesting));

    NSNotification *n = [NSNotification notificationWithName:@"TestNotification" object:nil];

    id observer = OCMObserverMock();
    [[NSNotificationCenter defaultCenter] addMockObserver:observer name:[n name] object:nil];
    OCMExpect([observer notificationWithName:[n name] object:[OCMArg any]]);

    OCMStub([mock stringValue]).andPost(n);

    [mock stringValue];

    OCMVerifyAll(observer);
}


- (void)testSetsUpSubstituteCall
{
    id mock = OCMStrictProtocolMock(@protocol(TestProtocolForMacroTesting));

    OCMStub([mock stringValue]).andCall(self, @selector(stringValueForTesting));

    XCTAssertEqualObjects([mock stringValue], @"TEST_STRING_FROM_TESTCASE", @"Should have called method from test case");
}

- (NSString *)stringValueForTesting
{
    return @"TEST_STRING_FROM_TESTCASE";
}


- (void)testCanChainPropertyBasedActions
{
    id mock = OCMPartialMock([[[TestClassForMacroTesting alloc] init] autorelease]);

    __block BOOL didCallBlock = NO;
    void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation)
    {
        didCallBlock = YES;
    };

    OCMStub([mock stringValue]).andDo(theBlock).andForwardToRealObject();

    NSString *actual = [mock stringValue];

    XCTAssertTrue(didCallBlock, @"Should have called block");
    XCTAssertEqualObjects(@"FOO", actual, @"Should have forwarded invocation");
}


- (void)testCanExplicitlySelectClassMethod
{
    id mock = OCMClassMock([TestClassWithClassMethods class]);

    OCMStub(ClassMethod([mock bar])).andReturn(@"mocked-class");
    OCMStub([mock bar]).andReturn(@"mocked-instance");

    XCTAssertEqualObjects(@"mocked-class", [TestClassWithClassMethods bar], @"Should have stubbed class method.");
    XCTAssertEqualObjects(@"mocked-instance", [mock bar], @"Should have stubbed instance method.");
}


- (void)testSetsUpExpectations
{
    id mock = OCMClassMock([TestClassForMacroTesting class]);

    OCMExpect([mock stringValue]).andReturn(@"TEST_STRING");

    XCTAssertThrows([mock verify], @"Should have complained about expected method not being invoked");

    XCTAssertEqual([mock stringValue], @"TEST_STRING", @"Should have stubbed method, too");
    XCTAssertNoThrow([mock verify], @"Should have accepted invocation as matching expectation");
}

@end
