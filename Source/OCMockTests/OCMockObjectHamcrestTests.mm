//---------------------------------------------------------------------------------------
//  $Id: OCMockObjectTests.m 21 2008-01-24 18:59:39Z erik $
//  Copyright (c) 2004-2008 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>


@interface OCMockObjectHamcrestTests : XCTestCase

@end


@implementation OCMockObjectHamcrestTests

- (void)testAcceptsStubbedMethodWithHamcrestConstraint
{
	id mock = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] hasSuffix:(id)startsWith(@"foo")];
	[mock hasSuffix:@"foobar"];
}


- (void)testRejectsUnstubbedMethodWithHamcrestConstraint
{
	id mock = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] hasSuffix:(id)anyOf(equalTo(@"foo"), equalTo(@"bar"), NULL)];
	XCTAssertThrows([mock hasSuffix:@"foobar"], @"Should have raised an exception.");
}


@end
