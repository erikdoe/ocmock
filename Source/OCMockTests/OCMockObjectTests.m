//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2010 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMock.h>
#import "OCMockObjectTests.h"

// --------------------------------------------------------------------------------------
//	Helper classes and protocols for testing
// --------------------------------------------------------------------------------------

@interface InterfaceForTypedef : NSObject
@end

@implementation InterfaceForTypedef
@end

typedef InterfaceForTypedef TypedefInterface;
typedef InterfaceForTypedef* PointerTypedefInterface;
typedef int intTypedef;

@protocol TestProtocol
- (int)primitiveValue;
@optional
- (id)objectValue;
@end

@protocol ProtocolWithTypeQualifierMethod
- (void)aSpecialMethod:(byref in void *)someArg;
@end

@protocol ProtocolWithTypedefs
- (TypedefInterface*)typedefReturnValue1;
- (PointerTypedefInterface)typedefReturnValue2;
- (void)typedefParameter:(TypedefInterface*)parameter;
- (void)typedefPointerParameter:(PointerTypedefInterface)parameter;
@end

@interface ProtocolWithTypedefsImplementation : NSObject<ProtocolWithTypedefs>
- (TypedefInterface*)typedefReturnValue1;
- (PointerTypedefInterface)typedefReturnValue2;
- (void)typedefParameter:(TypedefInterface*)parameter;
- (void)typedefPointerParameter:(PointerTypedefInterface)parameter;
@end

@implementation ProtocolWithTypedefsImplementation

- (TypedefInterface*)typedefReturnValue1 {
    return nil;
}

- (PointerTypedefInterface)typedefReturnValue2 {
    return nil;
}

- (void)typedefParameter:(TypedefInterface*)parameter {
}

-(void)typedefPointerParameter:(PointerTypedefInterface)parameter {
}

@end


@interface TestClassWithIntPointerMethod : NSObject

- (void)returnValueInPointer:(int *)ptr;

@end

@implementation TestClassWithIntPointerMethod

- (void)returnValueInPointer:(int *)ptr
{
    *ptr = 555;
}

@end



@interface TestObserver	: NSObject
{
	@public
	NSNotification *notification;
}

@end

@implementation TestObserver

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[notification release];
	[super dealloc];
}

- (void)receiveNotification:(NSNotification *)aNotification
{
	notification = [aNotification retain];
}

@end

static NSString *TestNotification = @"TestNotification";


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

#if NS_BLOCKS_AVAILABLE

- (void)testAcceptsStubbedMethodWithBlockArgument
{
	mock = [OCMockObject mockForClass:[NSArray class]];
	[[mock stub] indexesOfObjectsPassingTest:[OCMArg any]];
	[mock indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) { return YES; }];
}


- (void)testAcceptsStubbedMethodWithBlockConstraint
{
	[[mock stub] hasSuffix:[OCMArg checkWithBlock:^(id value) { return [value isEqualToString:@"foo"]; }]];

	STAssertNoThrow([mock hasSuffix:@"foo"], @"Should not have thrown a exception");   
	STAssertThrows([mock hasSuffix:@"bar"], @"Should have thrown a exception");   
}
	
#endif

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
	[[[mock stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] writeToFile:OCMOCK_ANY atomically:YES encoding:NSMacOSRomanStringEncoding error:&error];
	
	STAssertTrue([mock writeToFile:@"foo" atomically:YES encoding:NSMacOSRomanStringEncoding error:&error], nil);
}

- (void)testAcceptsStubbedMethodWithAnyPointerArgument
{
	NSError *error;
	[[[mock stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] writeToFile:OCMOCK_ANY atomically:YES encoding:NSMacOSRomanStringEncoding error:[OCMArg anyPointer]];
	
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


- (void)testCanPassMocksAsArguments
{
	id mockArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:[OCMArg any]];
	[mock stringByAppendingString:mockArg];
}

- (void)testCanStubWithMockArguments
{
	id mockArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:mockArg];
	[mock stringByAppendingString:mockArg];
}

- (void)testRaisesExceptionWhenStubbedMockArgIsNotUsed
{
	id mockArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:mockArg];
	STAssertThrows([mock stringByAppendingString:@"foo"], @"Should have raised an exception.");
}

- (void)testRaisesExceptionWhenDifferentMockArgumentIsPassed
{
	id expectedArg = [OCMockObject mockForClass:[NSString class]];
	id otherArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:otherArg];
	STAssertThrows([mock stringByAppendingString:expectedArg], @"Should have raised an exception.");	
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
//	raising exceptions, posting notifications, etc.
// --------------------------------------------------------------------------------------

- (void)testRaisesExceptionWhenAskedTo
{
	NSException *exception = [NSException exceptionWithName:@"TestException" reason:@"test" userInfo:nil];
	[[[mock expect] andThrow:exception] lowercaseString];
	
	STAssertThrows([mock lowercaseString], @"Should have raised an exception.");
}

- (void)testPostsNotificationWhenAskedTo
{
	TestObserver *observer = [[[TestObserver alloc] init] autorelease];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receiveNotification:) name:TestNotification object:nil];
	
	NSNotification *notification = [NSNotification notificationWithName:TestNotification object:self];
	[[[mock stub] andPost:notification] lowercaseString];
	
	[mock lowercaseString];
	
	STAssertNotNil(observer->notification, @"Should have sent a notification.");
	STAssertEqualObjects(TestNotification, [observer->notification name], @"Name should match posted one.");
	STAssertEqualObjects(self, [observer->notification object], @"Object should match posted one.");
}

- (void)testPostsNotificationInAddtionToReturningValue
{
	TestObserver *observer = [[[TestObserver alloc] init] autorelease];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receiveNotification:) name:TestNotification object:nil];
	
	NSNotification *notification = [NSNotification notificationWithName:TestNotification object:self];
	[[[[mock stub] andReturn:@"foo"] andPost:notification] lowercaseString];
	
	STAssertEqualObjects(@"foo", [mock lowercaseString], @"Should have returned stubbed value.");
	STAssertNotNil(observer->notification, @"Should have sent a notification.");
}


- (NSString *)valueForString:(NSString *)aString andMask:(NSStringCompareOptions)mask
{
	return [NSString stringWithFormat:@"[%@, %ld]", aString, mask];
}

- (void)testCallsAlternativeMethodAndPassesOriginalArgumentsAndReturnsValue
{
	[[[mock stub] andCall:@selector(valueForString:andMask:) onObject:self] commonPrefixWithString:@"FOO" options:NSCaseInsensitiveSearch];
	
	NSString *returnValue = [mock commonPrefixWithString:@"FOO" options:NSCaseInsensitiveSearch];
	
	STAssertEqualObjects(@"[FOO, 1]", returnValue, @"Should have passed and returned invocation.");
}

#if NS_BLOCKS_AVAILABLE

- (void)testCallsBlockWhichCanSetUpReturnValue
{
	void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) 
		{
			NSString *value;
			[invocation getArgument:&value atIndex:2];
			value = [NSString stringWithFormat:@"MOCK %@", value];
			[invocation setReturnValue:&value];
		};
		
	[[[mock stub] andDo:theBlock] stringByAppendingString:[OCMArg any]];
		
	STAssertEqualObjects(@"MOCK foo", [mock stringByAppendingString:@"foo"], @"Should have called block.");
	STAssertEqualObjects(@"MOCK bar", [mock stringByAppendingString:@"bar"], @"Should have called block.");
}

#endif

- (void)testThrowsWhenTryingToUseForwardToRealObjectOnNonPartialMock
{
	STAssertThrows([[[mock expect] andForwardToRealObject] name], @"Should have raised and exception.");
}


// --------------------------------------------------------------------------------------
//	returning values in pass-by-reference arguments
// --------------------------------------------------------------------------------------

- (void)testReturnsValuesInPassByReferenceArguments
{
	NSString *expectedName = @"Test";
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


- (void)testReturnsValuesInNonObjectPassByReferenceArguments
{
    int expectedValue = 1234;
    mock = [OCMockObject mockForClass:[TestClassWithIntPointerMethod class]];
    [[mock stub] returnValueInPointer:[OCMArg setToValue:[NSValue value:&expectedValue withObjCType:@encode(int)]]];
    
    int actualValue = 0;
    [mock returnValueInPointer:&actualValue];
    
    STAssertEquals(expectedValue, actualValue, @"Should have returned value via pass by ref argument.");
    
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
//	ordered expectations
// --------------------------------------------------------------------------------------

- (void)testAcceptsExpectedMethodsInRecordedSequenceWhenOrderMatters
{
	[mock setExpectationOrderMatters:YES];
	
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	STAssertNoThrow([mock lowercaseString], @"Should have accepted expected method in sequence.");
	STAssertNoThrow([mock uppercaseString], @"Should have accepted expected method in sequence.");
}

- (void)testRaisesExceptionWhenSequenceIsWrongAndOrderMatters
{
	[mock setExpectationOrderMatters:YES];
	
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	STAssertThrows([mock uppercaseString], @"Should have complained about wrong sequence.");
}


// --------------------------------------------------------------------------------------
//	explicitly rejecting methods (mostly for nice mocks, see below)
// --------------------------------------------------------------------------------------

- (void)testThrowsWhenRejectedMethodIsCalledOnNiceMock
{
	mock = [OCMockObject niceMockForClass:[NSString class]];
	
	[[mock reject] uppercaseString];
	STAssertThrows([mock uppercaseString], @"Should have complained about rejected method being called.");
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

- (void)testSetsCorrectNameForProtocolMockObjects
{
	mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
	STAssertEqualObjects(@"OCMockObject[NSLocking]", [mock description], @"Should have returned correct description.");
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

- (void)testWithTypedefReturnType {
	mock = [OCMockObject mockForProtocol:@protocol(ProtocolWithTypedefs)];
    STAssertNoThrow([[[mock stub] andReturn:[TypedefInterface new]] typedefReturnValue1], @"Should accept a typedefed return-type");
    STAssertNoThrow([mock typedefReturnValue1], @"bla");
}

- (void)testWithTypedefPointerReturnType {
	mock = [OCMockObject mockForProtocol:@protocol(ProtocolWithTypedefs)];
    STAssertNoThrow([[[mock stub] andReturn:[TypedefInterface new]] typedefReturnValue2], @"Should accept a typedefed return-type");
    STAssertNoThrow([mock typedefReturnValue2], @"bla");
}

- (void)testWithTypedefParameter {
	mock = [OCMockObject mockForProtocol:@protocol(ProtocolWithTypedefs)];
    STAssertNoThrow([[mock stub] typedefParameter:nil], @"Should accept a typedefed parameter-type");
    STAssertNoThrow([mock typedefParameter:nil], @"bla");
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

- (void)testForwardsIsKindOfClass
{
    STAssertTrue([mock isKindOfClass:[NSString class]], @"Should have pretended to be the mocked class.");
}

- (void)testWorksWithTypeQualifiers
{
	id myMock = [OCMockObject mockForProtocol:@protocol(ProtocolWithTypeQualifierMethod)];
	
	STAssertNoThrow([[myMock expect] aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
	STAssertNoThrow([myMock aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
}


- (void)testAdjustsRetainCountWhenStubbingMethodsThatCreateObjects
{
    NSString *objectToReturn = [NSString stringWithFormat:@"This is not a %@.", @"string constant"];
    [[[mock stub] andReturn:objectToReturn] mutableCopy];

    NSUInteger retainCountBefore = [objectToReturn retainCount];
    id returnedObject = [mock mutableCopy];
    [returnedObject release]; // the expectation is that we have to call release after a copy
    NSUInteger retainCountAfter = [objectToReturn retainCount];

    STAssertEqualObjects(objectToReturn, returnedObject, @"Should not stubbed copy method");
    STAssertEquals(retainCountBefore, retainCountAfter, @"Should have incremented retain count in copy stub.");
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

- (void)testReRaisesRejectExceptionsOnVerify
{
	mock = [OCMockObject niceMockForClass:[NSString class]];
	[[mock reject] uppercaseString];
	@try
	{
		[mock uppercaseString];
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
