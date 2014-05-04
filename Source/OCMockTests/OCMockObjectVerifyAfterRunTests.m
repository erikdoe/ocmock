//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import "OCMockObject.h"

@interface TestClassForVerifyAfterRun : NSObject

- (NSString *)method1;
- (NSString *)method2;

@end

@implementation TestClassForVerifyAfterRun

- (NSString *)method1
{
	id retVal = [self method2];
	return retVal;
}

- (NSString *)method2
{
	return @"Foo";
}

@end


@interface OCMockObjectVerifyAfterRunTests : XCTestCase

@end


@implementation OCMockObjectVerifyAfterRunTests

- (void)testDoesNotThrowWhenMethodWasInvoked
{
    id mock = [OCMockObject niceMockForClass:[NSString class]];

    [mock lowercaseString];

    XCTAssertNoThrow([[mock verify] lowercaseString], @"Should not have thrown an exception for method that was called.");
}

- (void)testThrowsWhenMethodWasNotInvoked
{
    id mock = [OCMockObject niceMockForClass:[NSString class]];

    [mock lowercaseString];

    XCTAssertThrows([[mock verify] uppercaseString], @"Should have thrown an exception for a method that was not called.");
}

- (void)testDoesNotThrowWhenMethodWasInvokedOnPartialMock
{
    TestClassForVerifyAfterRun *testObject = [[[TestClassForVerifyAfterRun alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:testObject];

    [mock method2];

    XCTAssertNoThrow([[mock verify] method2], @"Should not have thrown an exception for method that was called.");
}

//- (void)testDoesNotThrowWhenMethodWasInvokedDirectlyOnRealObject
//{
//    TestClassForVerifyAfterRun *testObject = [[[TestClassForVerifyAfterRun alloc] init] autorelease];
//    id mock = [OCMockObject partialMockForObject:testObject];
//
//    [mock method1];
//
//    XCTAssertNoThrow([[mock verify] method2], @"Should not have thrown an exception for method that was called.");
//}

@end
