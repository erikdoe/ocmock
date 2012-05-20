//
//  OCMockClassTests.m
//  OCMock
//
//  Created by Kevin Kim on 5/20/12.
//  Copyright (c) 2012 Mulle Kybernetik. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "OCMockClassTests.h"

// --------------------------------------------------------------------------------------
//	Helper class for testing
// --------------------------------------------------------------------------------------

@interface TestClassWithClassMethod : NSObject

+ (NSString *)method1;

@end

@implementation TestClassWithClassMethod

+ (NSString *)method1
{
    return @"Foo";
}

@end


@implementation OCMockClassTests

- (void)setUp
{
    mockClass = [OCMockObject mockForClassObject:[TestClassWithClassMethod class]];
}

// --------------------------------------------------------------------------------------
//	class object mocks allow stubbing/expecting on class objects
// --------------------------------------------------------------------------------------

- (void)testStubsMethodOnClassObject
{
    
	[[[mockClass stub] andReturn:@"TestFoo"] method1];
	STAssertEqualObjects(@"TestFoo", [TestClassWithClassMethod method1], @"Should have stubbed method.");
}

- (void)testForwardsUnstubbedMethodsToRealClassObjectAfterStopIsCalled
{
	[[[mockClass stub] andReturn:@"TestFoo"] method1];
    [mockClass stopMocking];
	STAssertEqualObjects(@"Foo", [TestClassWithClassMethod method1], @"Should not have stubbed method.");
}

@end
