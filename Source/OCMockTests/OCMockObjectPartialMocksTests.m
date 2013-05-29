//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMock.h>
#import "OCMockObjectPartialMocksTests.h"

#pragma mark   Helper classes

@interface TestClassWithSimpleMethod : NSObject
- (NSString *)foo;
@end

@implementation TestClassWithSimpleMethod

- (NSString *)foo
{
    return @"Foo";
}

@end


@interface TestClassThatCallsSelf : NSObject
- (NSString *)method1;
- (NSString *)method2;
@end

@implementation TestClassThatCallsSelf

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



@implementation OCMockObjectPartialMocksTests

#pragma mark   Tests for stubbing with partial mocks

- (void)testStubsMethodsOnPartialMock
{
	TestClassWithSimpleMethod *object = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:object];
	[[[mock stub] andReturn:@"hi"] foo];
	STAssertEqualObjects(@"hi", [mock foo], @"Should have returned stubbed value");
}

//- (void)testStubsMethodsOnPartialMockForTollFreeBridgedClasses
//{
//	mock = [OCMockObject partialMockForObject:[NSString stringWithString:@"hello"]];
//	[[[mock stub] andReturn:@"hi"] uppercaseString];
//	STAssertEqualObjects(@"hi", [mock uppercaseString], @"Should have returned stubbed value");
//}

- (void)testForwardsUnstubbedMethodsCallsToRealObjectOnPartialMock
{
	TestClassWithSimpleMethod *object = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:object];
	STAssertEqualObjects(@"Foo", [mock foo], @"Should have returned value from real object.");
}

//- (void)testForwardsUnstubbedMethodsCallsToRealObjectOnPartialMockForTollFreeBridgedClasses
//{
//	mock = [OCMockObject partialMockForObject:[NSString stringWithString:@"hello2"]];
//	STAssertEqualObjects(@"HELLO2", [mock uppercaseString], @"Should have returned value from real object.");
//}

- (void)testStubsMethodOnRealObjectReference
{
	TestClassWithSimpleMethod *realObject = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"TestFoo"] foo];
	STAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
}

- (void)testCallsToSelfInRealObjectAreShadowedByPartialMock
{
	TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"FooFoo"] method2];
	STAssertEqualObjects(@"FooFoo", [mock method1], @"Should have called through to stubbed method.");
}


#pragma mark   Tests for end of stubbing with partial mocks

- (void)testReturnsToRealImplementationWhenExpectedCallOccurred
{
    TestClassWithSimpleMethod *realObject = [[[TestClassWithSimpleMethod alloc] init] autorelease];
   	id mock = [OCMockObject partialMockForObject:realObject];
   	[[[mock expect] andReturn:@"TestFoo"] foo];
   	STAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
   	STAssertEqualObjects(@"Foo", [realObject foo], @"Should have 'unstubbed' method.");
}

- (void)testRestoresObjectWhenStopped
{
	TestClassWithSimpleMethod *realObject = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"TestFoo"] foo];
	STAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
	STAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
	[mock stopMocking];
	STAssertEqualObjects(@"Foo", [realObject foo], @"Should have 'unstubbed' method.");
}


#pragma mark   Tests for explicit forward to real object with partial mocks

- (void)testForwardsToRealObjectWhenSetUpAndCalledOnMock
{
	TestClassWithSimpleMethod *realObject = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:realObject];
    
	[[[mock expect] andForwardToRealObject] foo];
	STAssertEquals(@"Foo", [mock foo], @"Should have called method on real object.");
    
	[mock verify];
}

- (void)testForwardsToRealObjectWhenSetUpAndCalledOnRealObject
{
	TestClassWithSimpleMethod *realObject = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:realObject];
	
	[[[mock expect] andForwardToRealObject] foo];
	STAssertEquals(@"Foo", [realObject foo], @"Should have called method on real object.");
	
	[mock verify];
}


#pragma mark   Tests for method swizzling with partial mocks

- (NSString *)differentMethodInDifferentClass
{
	return @"swizzled!";
}

- (void)testImplementsMethodSwizzling
{
	// using partial mocks and the indirect return value provider
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andCall:@selector(differentMethodInDifferentClass) onObject:self] method1];
	STAssertEqualObjects(@"swizzled!", [foo method1], @"Should have returned value from different method");
}


- (void)aMethodWithVoidReturn
{
}

- (void)testMethodSwizzlingWorksForVoidReturns
{
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andCall:@selector(aMethodWithVoidReturn) onObject:self] method1];
	STAssertNoThrow([foo method1], @"Should have worked.");
}


@end
