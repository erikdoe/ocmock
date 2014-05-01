//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import "OCMockObject.h"


@interface OCMockObjectVerifyAfterRunTests : XCTestCase

@end

@implementation OCMockObjectVerifyAfterRunTests

- (void)testDoesNotThrowWhenMethodWasCalled
{
    id mock = [OCMockObject niceMockForClass:[NSString class]];

    [mock lowercaseString];

    XCTAssertNoThrow([[mock verify] lowercaseString], @"Should not have thrown an exception for method that was called.");
}

- (void)testThrowsWhenMethodWasCalled
{
    id mock = [OCMockObject niceMockForClass:[NSString class]];

    [mock lowercaseString];

    XCTAssertThrows([[mock verify] uppercaseString], @"Should have thrown an exception for a method that was not called.");
}

@end
