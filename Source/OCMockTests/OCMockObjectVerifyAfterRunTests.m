//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import "OCMockObject.h"
#import "OCMockRecorder.h"

@interface TestBaseClassForVerifyAfterRun : NSObject

+ (NSString *)classMethod1;
- (NSString *)method2;

@end

@implementation TestBaseClassForVerifyAfterRun

+ (NSString *)classMethod1
{
    return @"Foo-ClassMethod";
}

- (NSString *)method2
{
	return @"Foo";
}

@end

@interface TestClassForVerifyAfterRun : TestBaseClassForVerifyAfterRun

- (NSString *)method1;

@end

@implementation TestClassForVerifyAfterRun

- (NSString *)method1
{
	id retVal = [self method2];
	return retVal;
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

- (void)testDoesNotThrowWhenMethodWasInvokedOnRealObjectEvenInSuperclass
{
    TestClassForVerifyAfterRun *testObject = [[[TestClassForVerifyAfterRun alloc] init] autorelease];
    id mock = [OCMockObject partialMockForObject:testObject];

    NSString *string =  [testObject method1];

    XCTAssertEqualObjects(@"Foo", string, @"Should have returned value from actual implementation.");
    XCTAssertNoThrow([[mock verify] method2], @"Should not have thrown an exception for method that was called.");
}

- (void)testDoesNotThrowWhenClassMethodWasInvoked
{
    id mock = [OCMockObject niceMockForClass:[TestBaseClassForVerifyAfterRun class]];

    [TestBaseClassForVerifyAfterRun classMethod1];

    XCTAssertNoThrow([[mock verify] classMethod1], @"Should not have thrown an exception for class method that was called.");
}

- (void)testThrowsWhenClassMethodWasNotInvoked
{
    id mock = [OCMockObject niceMockForClass:[TestBaseClassForVerifyAfterRun class]];

    XCTAssertThrows([[mock verify] classMethod1], @"Should not have thrown an exception for class method that was called.");
}

@end
