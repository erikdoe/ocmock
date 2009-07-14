//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2008 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMock.h>
#import "OCMockObjectTests.h"

// --------------------------------------------------------------------------------------
//	Helper classes and protocols for testing
// --------------------------------------------------------------------------------------

@protocol TestProtocol
- (int)primitiveValue;
@optional
- (id)objectValue;
@end

@protocol ProtocolWithTypeQualifierMethod
- (void)aSpecialMethod:(byref in void *)someArg;
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


// --------------------------------------------------------------------------------------
//  setup
// --------------------------------------------------------------------------------------


@implementation OCMockObjectTests

- (void)setUp
{
	mock = [OCMockObject mockForClass:[NSString class]];
}


// --------------------------------------------------------------------------------------
//	accepting stubbed methods / rejecting methods not stubbed
// --------------------------------------------------------------------------------------

- (void)testAcceptsStubbedMethod
{
	[[mock stub] lowercaseString];
	[mock lowercaseString];
}

- (void)testRaisesExceptionWhenUnknownMethodIsCalled
{
	[[mock stub] lowercaseString];
	STAssertThrows([mock uppercaseString], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithSpecificArgument
{
	[[mock stub] hasSuffix:@"foo"];
	[mock hasSuffix:@"foo"];
}


- (void)testAcceptsStubbedMethodWithConstraint
{
	[[mock stub] hasSuffix:[OCMArg any]];
	[mock hasSuffix:@"foo"];
	[mock hasSuffix:@"bar"];
}


- (void)testAcceptsStubbedMethodWithNilArgument
{
	[[mock stub] hasSuffix:nil];
	
	[mock hasSuffix:nil];
}

- (void)testRaisesExceptionWhenMethodWithWrongArgumentIsCalled
{
	[[mock stub] hasSuffix:@"foo"];
	STAssertThrows([mock hasSuffix:@"xyz"], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithScalarArgument
{
	[[mock stub] stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
	[mock stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
}


- (void)testRaisesExceptionWhenMethodWithOneWrongScalarArgumentIsCalled
{
	[[mock stub] stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
	STAssertThrows([mock stringByPaddingToLength:20 withString:@"foo" startingAtIndex:3], @"Should have raised an exception.");	
}

- (void)testAcceptsStubbedMethodWithPointerArgument
{
	NSError *error;
	BOOL yes = YES;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(yes)] writeToFile:OCMOCK_ANY atomically:YES encoding:NSMacOSRomanStringEncoding error:&error];
	
	STAssertTrue([mock writeToFile:@"foo" atomically:YES encoding:NSMacOSRomanStringEncoding error:&error], nil);
}

- (void)testAcceptsStubbedMethodWithAnyPointerArgument
{
	BOOL yes = YES;
	NSError *error;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(yes)] writeToFile:OCMOCK_ANY atomically:YES encoding:NSMacOSRomanStringEncoding error:[OCMArg anyPointer]];
	
	STAssertTrue([mock writeToFile:@"foo" atomically:YES encoding:NSMacOSRomanStringEncoding error:&error], nil);
}

- (void)testRaisesExceptionWhenMethodWithWrongPointerArgumentIsCalled
{
	NSString *string;
	NSString *anotherString;
	NSArray *array;
	
	[[mock stub] completePathIntoString:&string caseSensitive:YES matchesIntoArray:&array filterTypes:OCMOCK_ANY];
	
	STAssertThrows([mock completePathIntoString:&anotherString caseSensitive:YES matchesIntoArray:&array filterTypes:OCMOCK_ANY], nil);
}

- (void)testAcceptsStubbedMethodWithVoidPointerArgument
{
	mock = [OCMockObject mockForClass:[NSMutableData class]];
	[[mock stub] appendBytes:NULL length:0];
	[mock appendBytes:NULL length:0];
}


- (void)testRaisesExceptionWhenMethodWithWrongVoidPointerArgumentIsCalled
{
	mock = [OCMockObject mockForClass:[NSMutableData class]];
	[[mock stub] appendBytes:"foo" length:3];
	STAssertThrows([mock appendBytes:"bar" length:3], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithPointerPointerArgument
{
	NSError *error = nil;
	[[mock stub] initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error];	
	[mock initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error];
}


- (void)testRaisesExceptionWhenMethodWithWrongPointerPointerArgumentIsCalled
{
	NSError *error = nil, *error2;
	[[mock stub] initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error];	
	STAssertThrows([mock initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error2], @"Should have raised.");
}


- (void)testAcceptsStubbedMethodWithStructArgument
{
    NSRange range = NSMakeRange(0,20);
	[[mock stub] substringWithRange:range];
	[mock substringWithRange:range];
}


- (void)testRaisesExceptionWhenMethodWithWrongStructArgumentIsCalled
{
    NSRange range = NSMakeRange(0,20);
    NSRange otherRange = NSMakeRange(0,10);
	[[mock stub] substringWithRange:range];
	STAssertThrows([mock substringWithRange:otherRange], @"Should have raised an exception.");	
}


// --------------------------------------------------------------------------------------
//	returning values from stubbed methods
// --------------------------------------------------------------------------------------

- (void)testReturnsStubbedReturnValue
{
	id returnValue;  

	[[[mock stub] andReturn:@"megamock"] lowercaseString];
	returnValue = [mock lowercaseString];
	
	STAssertEqualObjects(@"megamock", returnValue, @"Should have returned stubbed value.");
	
}

- (void)testReturnsStubbedIntReturnValue
{
    int expectedValue = 42;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(expectedValue)] intValue];
	int returnValue = [mock intValue];
    
	STAssertEquals(expectedValue, returnValue, @"Should have returned stubbed value.");
}

- (void)testRaisesWhenBoxedValueTypesDoNotMatch
{
    double expectedValue = 42;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(expectedValue)] intValue];
    
	STAssertThrows([mock intValue], @"Should have raised an exception.");
}

- (void)testReturnsStubbedNilReturnValue
{
	[[[mock stub] andReturn:nil] uppercaseString];
	
	id returnValue = [mock uppercaseString];
	
	STAssertNil(returnValue, @"Should have returned stubbed value, which is nil.");
}


// --------------------------------------------------------------------------------------
//	raising exceptions and posting notifications
// --------------------------------------------------------------------------------------

- (void)testRaisesExceptionWhenAskedTo
{
	NSException *exception = [NSException exceptionWithName:@"TestException" reason:@"test" userInfo:nil];
	[[[mock expect] andThrow:exception] lowercaseString];
	
	STAssertThrows([mock lowercaseString], @"Should have raised an exception.");
}



// --------------------------------------------------------------------------------------
//	returning values in pass-by-reference arguments
// --------------------------------------------------------------------------------------

- (void)testReturnsValuesInPassByReferenceArguments
{
	NSString *expectedName = [NSString stringWithString:@"Test"];
	NSArray *expectedArray = [NSArray array];
	
	[[mock expect] completePathIntoString:[OCMArg setTo:expectedName] caseSensitive:YES 
						 matchesIntoArray:[OCMArg setTo:expectedArray] filterTypes:OCMOCK_ANY];
	
	NSString *actualName = nil;
	NSArray *actualArray = nil;
	[mock completePathIntoString:&actualName caseSensitive:YES matchesIntoArray:&actualArray filterTypes:nil];

	STAssertNoThrow([mock verify], @"An unexpected exception was thrown");
	STAssertEqualObjects(expectedName, actualName, @"The two string objects should be equal");
	STAssertEqualObjects(expectedArray, actualArray, @"The two array objects should be equal");
}


// --------------------------------------------------------------------------------------
//	accepting expected methods
// --------------------------------------------------------------------------------------

- (void)testAcceptsExpectedMethod
{
	[[mock expect] lowercaseString];
	[mock lowercaseString];
}


- (void)testAcceptsExpectedMethodAndReturnsValue
{
	id returnValue;

	[[[mock expect] andReturn:@"Objective-C"] lowercaseString];
	returnValue = [mock lowercaseString];

	STAssertEqualObjects(@"Objective-C", returnValue, @"Should have returned stubbed value.");
}


- (void)testAcceptsExpectedMethodsInRecordedSequence
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	[mock lowercaseString];
	[mock uppercaseString];
}


- (void)testAcceptsExpectedMethodsInDifferentSequence
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	[mock uppercaseString];
	[mock lowercaseString];
}


// --------------------------------------------------------------------------------------
//	verifying expected methods
// --------------------------------------------------------------------------------------

- (void)testAcceptsAndVerifiesExpectedMethods
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	[mock lowercaseString];
	[mock uppercaseString];
	
	[mock verify];
}


- (void)testRaisesExceptionOnVerifyWhenNotAllExpectedMethodsWereCalled
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	[mock lowercaseString];
	
	STAssertThrows([mock verify], @"Should have raised an exception.");
}

- (void)testAcceptsAndVerifiesTwoExpectedInvocationsOfSameMethod
{
	[[mock expect] lowercaseString];
	[[mock expect] lowercaseString];
	
	[mock lowercaseString];
	[mock lowercaseString];
	
	[mock verify];
}


- (void)testAcceptsAndVerifiesTwoExpectedInvocationsOfSameMethodAndReturnsCorrespondingValues
{
	[[[mock expect] andReturn:@"foo"] lowercaseString];
	[[[mock expect] andReturn:@"bar"] lowercaseString];
	
	STAssertEqualObjects(@"foo", [mock lowercaseString], @"Should have returned first stubbed value");
	STAssertEqualObjects(@"bar", [mock lowercaseString], @"Should have returned seconds stubbed value");
	
	[mock verify];
}

- (void)testReturnsStubbedValuesIndependentOfExpectations
{
	[[mock stub] hasSuffix:@"foo"];
	[[mock expect] hasSuffix:@"bar"];
	
	[mock hasSuffix:@"foo"];
	[mock hasSuffix:@"bar"];
	[mock hasSuffix:@"foo"]; // Since it's a stub, shouldn't matter how many times we call this
	
	[mock verify];
}

-(void)testAcceptsAndVerifiesMethodsWithSelectorArgument
{
	[[mock expect] performSelector:@selector(lowercaseString)];
	[mock performSelector:@selector(lowercaseString)];
	[mock verify];
}


// --------------------------------------------------------------------------------------
//	protocol mocks
// --------------------------------------------------------------------------------------

- (void)testCanMockFormalProtocol
{
	mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
	[[mock expect] lock];
	
	[mock lock];
	
	[mock verify];
}

- (void)testRaisesWhenUnknownMethodIsCalledOnProtocol
{
	mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
	STAssertThrows([mock lowercaseString], @"Should have raised an exception.");
}

- (void)testConformsToMockedProtocol
{
	mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
	STAssertTrue([mock conformsToProtocol:@protocol(NSLocking)], nil);
}

- (void)testRespondsToValidProtocolRequiredSelector
{
	mock = [OCMockObject mockForProtocol:@protocol(TestProtocol)];	
    STAssertTrue([mock respondsToSelector:@selector(primitiveValue)], nil);
}

- (void)testRespondsToValidProtocolOptionalSelector
{
	mock = [OCMockObject mockForProtocol:@protocol(TestProtocol)];	
    STAssertTrue([mock respondsToSelector:@selector(objectValue)], nil);
}

- (void)testDoesNotRespondToInvalidProtocolSelector
{
	mock = [OCMockObject mockForProtocol:@protocol(TestProtocol)];	
    STAssertFalse([mock respondsToSelector:@selector(fooBar)], nil);
}


// --------------------------------------------------------------------------------------
//	nice mocks don't complain about unknown methods
// --------------------------------------------------------------------------------------

- (void)testReturnsDefaultValueWhenUnknownMethodIsCalledOnNiceClassMock
{
	mock = [OCMockObject niceMockForClass:[NSString class]];
	STAssertNil([mock lowercaseString], @"Should return nil on unexpected method call (for nice mock).");	
	[mock verify];
}

- (void)testRaisesAnExceptionWhenAnExpectedMethodIsNotCalledOnNiceClassMock
{
	mock = [OCMockObject niceMockForClass:[NSString class]];	
	[[[mock expect] andReturn:@"HELLO!"] uppercaseString];
	STAssertThrows([mock verify], @"Should have raised an exception because method was not called.");
}

- (void)testReturnDefaultValueWhenUnknownMethodIsCalledOnProtocolMock
{
	mock = [OCMockObject niceMockForProtocol:@protocol(TestProtocol)];
	STAssertTrue(0 == [mock primitiveValue], @"Should return 0 on unexpected method call (for nice mock).");
	[mock verify];
}

- (void)testRaisesAnExceptionWenAnExpectedMethodIsNotCalledOnNiceProtocolMock
{
	mock = [OCMockObject niceMockForProtocol:@protocol(TestProtocol)];	
	[[mock expect] primitiveValue];
	STAssertThrows([mock verify], @"Should have raised an exception because method was not called.");
}


// --------------------------------------------------------------------------------------
//	partial mocks forward unknown methods to a real instance
// --------------------------------------------------------------------------------------

- (void)testStubsMethodsOnPartialMock
{
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andReturn:@"hi"] method1];
	STAssertEqualObjects(@"hi", [mock method1], @"Should have returned stubbed value");
}

//- (void)testStubsMethodsOnPartialMockForTollFreeBridgedClasses
//{
//	mock = [OCMockObject partialMockForObject:[NSString stringWithString:@"hello"]];
//	[[[mock stub] andReturn:@"hi"] uppercaseString];
//	STAssertEqualObjects(@"hi", [mock uppercaseString], @"Should have returned stubbed value");
//}

- (void)testForwardsUnstubbedMethodsCallsToRealObjectOnPartialMock
{
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:foo];
	STAssertEqualObjects(@"Foo", [mock method2], @"Should have returned value from real object.");
}

//- (void)testForwardsUnstubbedMethodsCallsToRealObjectOnPartialMockForTollFreeBridgedClasses
//{
//	mock = [OCMockObject partialMockForObject:[NSString stringWithString:@"hello2"]];
//	STAssertEqualObjects(@"HELLO2", [mock uppercaseString], @"Should have returned value from real object.");
//}

- (void)testStubsMethodOnRealObjectReference
{
	TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"FooFoo"] method1];
	STAssertEqualObjects(@"FooFoo", [realObject method1], @"Should have stubbed method.");
}

- (void)testCallsToSelfInRealObjectAreShadowedByPartialMock
{
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andReturn:@"FooFoo"] method2];
	STAssertEqualObjects(@"FooFoo", [mock method1], @"Should have called through to stubbed method.");
}


// --------------------------------------------------------------------------------------
//	mocks should honour the NSObject contract, etc.
// --------------------------------------------------------------------------------------

- (void)testRespondsToValidSelector
{
	STAssertTrue([mock respondsToSelector:@selector(lowercaseString)], nil);
}

- (void)testDoesNotRespondToInvalidSelector
{
	STAssertFalse([mock respondsToSelector:@selector(fooBar)], nil);
}

- (void)testCanStubValueForKeyMethod
{
	id returnValue;
	
	mock = [OCMockObject mockForClass:[NSObject class]];
	[[[mock stub] andReturn:@"SomeValue"] valueForKey:@"SomeKey"];
	
	returnValue = [mock valueForKey:@"SomeKey"];
	
	STAssertEqualObjects(@"SomeValue", returnValue, @"Should have returned value that was set up.");
}

- (void)testWorksWithTypeQualifiers
{
	id myMock = [OCMockObject mockForProtocol:@protocol(ProtocolWithTypeQualifierMethod)];
	
	STAssertNoThrow([[myMock expect] aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
	STAssertNoThrow([myMock aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
}


// --------------------------------------------------------------------------------------
//  some internal tests
// --------------------------------------------------------------------------------------

- (void)testReRaisesFailFastExceptionsOnVerify
{
	@try
	{
		[mock lowercaseString];
	}
	@catch(NSException *exception)
	{
		// expected
	}
	STAssertThrows([mock verify], @"Should have reraised the exception.");
}


- (void)testCanCreateExpectationsAfterInvocations
{
	[[mock expect] lowercaseString];
	[mock lowercaseString];
	[mock expect];
}

@end
