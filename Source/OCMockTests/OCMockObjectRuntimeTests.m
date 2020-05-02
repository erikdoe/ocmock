/*
 *  Copyright (c) 2014-2020 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>


#pragma mark   Helper classes

@interface TestClassWithTypeQualifierMethod : NSObject

- (void)aSpecialMethod:(byref in void *)someArg;

@end

@implementation TestClassWithTypeQualifierMethod

- (void)aSpecialMethod:(byref in __unused void *)someArg
{
}

@end


typedef NSString TypedefString;

@interface TestClassWithTypedefObjectArgument : NSObject

- (NSString *)stringForTypedef:(TypedefString *)string;

@end

@implementation TestClassWithTypedefObjectArgument

- (NSString *)stringForTypedef:(TypedefString *)string
{
    return @"Whatever. Doesn't matter.";
}
@end


@interface TestDelegate : NSObject

- (void)go;

@end

@implementation TestDelegate

- (void)go
{
}

@end

@interface TestClassWithDelegate : NSObject

@property (nonatomic, weak) TestDelegate *delegate;

@end

@implementation TestClassWithDelegate

- (void)run
{
    TestDelegate *delegate = self.delegate;
    [delegate go];
}

@end


@interface NSValueSubclassForTesting : NSValue

@end

@implementation NSValueSubclassForTesting

@end


@interface TestClassWithInitMethod : NSObject
@end

@implementation TestClassWithInitMethod

- (id)initMethodNotCalledJustInitWithArg:(id)foo {
return [super init];
}

- (id)initMethodNotCalledJustInit
{
	return [super init];
}

- (id)_init
{
	return [super init];
}

- (id)initMethodWithNestedInit
{
	return [self initMethodNotCalledJustInit];
}

@end

#pragma mark   Tests for interaction with runtime and foundation conventions

@interface OCMockObjectRuntimeTests : XCTestCase

@end

@implementation OCMockObjectRuntimeTests

- (void)testRespondsToValidSelector
{
    id mock = [OCMockObject mockForClass:[NSString class]];
    XCTAssertTrue([mock respondsToSelector:@selector(lowercaseString)]);
}


- (void)testDoesNotRespondToInvalidSelector
{
    id mock = [OCMockObject mockForClass:[NSString class]];
    // We use a selector that's not implemented by the mock
    XCTAssertFalse([mock respondsToSelector:@selector(arrayWithArray:)]);
}


- (void)testCanStubValueForKeyMethod
{
    id mock = [OCMockObject mockForClass:[NSObject class]];
    [[[mock stub] andReturn:@"SomeValue"] valueForKey:@"SomeKey"];

    id returnValue = [mock valueForKey:@"SomeKey"];

    XCTAssertEqualObjects(@"SomeValue", returnValue, @"Should have returned value that was set up.");
}


- (void)testMockConformsToProtocolImplementedInSuperclass
{
    id mock = [OCMockObject mockForClass:[NSValueSubclassForTesting class]];
    XCTAssertTrue([mock conformsToProtocol:@protocol(NSCopying)]);

}

- (void)testCanMockNSMutableArray
{
    id mock = [OCMockObject niceMockForClass:[NSMutableArray class]];
    id anArray = [[NSMutableArray alloc] init];
#pragma unused(mock, anArray)
}


- (void)testForwardsIsKindOfClass
{
    id mock = [OCMockObject mockForClass:[NSString class]];
    XCTAssertTrue([mock isKindOfClass:[NSString class]], @"Should have pretended to be the mocked class.");
}


- (void)testWorksWithTypeQualifiers
{
    id myMock = [OCMockObject mockForClass:[TestClassWithTypeQualifierMethod class]];

    XCTAssertNoThrow([[myMock expect] aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
    XCTAssertNoThrow([myMock aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
}

- (void)testWorksWithTypedefsToObjects
{
    id myMock = [OCMockObject mockForClass:[TestClassWithTypedefObjectArgument class]];
    [[[myMock stub] andReturn:@"stubbed"] stringForTypedef:[OCMArg any]];
     id actualReturn = [myMock stringForTypedef:@"Some arg that shouldn't matter"];
     XCTAssertEqualObjects(actualReturn, @"stubbed", @"Should have matched invocation.");
}


#if 0 // can't test this with ARC
- (void)testAdjustsRetainCountWhenStubbingMethodsThatCreateObjects
{
    id mock = [OCMockObject mockForClass:[NSString class]];
    NSString *objectToReturn = [NSString stringWithFormat:@"This is not a %@.", @"string constant"];
#pragma clang diagnostic push
#pragma ide diagnostic ignored "NotReleasedValue"
    [[[mock stub] andReturn:objectToReturn] mutableCopy];
#pragma clang diagnostic pop

    NSUInteger retainCountBefore = [objectToReturn retainCount];
    id returnedObject = [mock mutableCopy];
    [returnedObject release]; // the expectation is that we have to call release after a copy
    NSUInteger retainCountAfter = [objectToReturn retainCount];

    XCTAssertEqualObjects(objectToReturn, returnedObject, @"Should have stubbed copy method");
    XCTAssertEqual(retainCountBefore, retainCountAfter, @"Should have incremented retain count in copy stub.");
}
#endif

- (void)testComplainsWhenUnimplementedMethodIsCalled
{
    id mock = [OCMockObject mockForClass:[NSString class]];
    XCTAssertThrowsSpecificNamed([mock performSelector:@selector(sortedArrayHint)], NSException, NSInvalidArgumentException);
}

- (void)testComplainsWhenAttemptIsMadeToStubInitMethod
{
    id mock = [OCMockObject mockForClass:[NSString class]];
    XCTAssertThrows([[[mock stub] init] andReturn:nil]);
}

- (void)testComplainsWhenAttemptIsMadeToStubInitMethodViaMacro
{
    id mock = [OCMockObject mockForClass:[NSString class]];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    XCTAssertThrows(OCMStub([mock init]));
#pragma clang diagnostic pop
}


- (void)testMockShouldNotRaiseWhenDescribing
{
    id mock = [OCMockObject mockForClass:[NSObject class]];

    XCTAssertNoThrow(NSLog(@"Testing description handling dummy methods... %@ %@ %@ %@ %@",
            @{@"foo": mock},
            @[mock],
            [NSSet setWithObject:mock],
            [mock description],
            mock),
                    @"asking for the description of a mock shouldn't cause a test to fail.");
}


- (void)testPartialMockShouldNotRaiseWhenDescribing
{
    id mock = [OCMockObject partialMockForObject:[[NSObject alloc] init]];

    XCTAssertNoThrow(NSLog(@"Testing description handling dummy methods... %@ %@ %@ %@ %@",
            @{@"bar": mock},
            @[mock],
            [NSSet setWithObject:mock],
            [mock description],
            mock),
                    @"asking for the description of a mock shouldn't cause a test to fail.");
    [mock stopMocking];
}


- (void)testWeakReferencesShouldStayAround
{
    TestClassWithDelegate *object = [TestClassWithDelegate new];

    TestDelegate *delegate = [TestDelegate new];
    object.delegate = delegate;
    XCTAssertNotNil(object.delegate, @"Should have delegate");

    id mockDelegate = OCMPartialMock(delegate);
    XCTAssertNotNil(object.delegate, @"Should still have delegate");

    [object run];

    OCMVerify([mockDelegate go]);
    XCTAssertNotNil(object.delegate, @"Should still have delegate");
}


- (void)testDynamicSubclassesShouldBeDisposed
{
    int numClassesBefore = objc_getClassList(NULL, 0);

    id mock = [OCMockObject mockForClass:[TestDelegate class]];
    [mock stopMocking];

    int numClassesAfter = objc_getClassList(NULL, 0);
    XCTAssertEqual(numClassesBefore, numClassesAfter, @"Should have disposed dynamically generated classes.");
}

#pragma mark    verify mocks work properly when mocking init

- (void)testPartialMockNestedInitReturnsCorrectSelfAndDoesntLeak
{
	__weak id outerMock;
	__weak id outerReal;
	@autoreleasepool
	{
		TestClassWithInitMethod *realObject = [TestClassWithInitMethod alloc];
		outerReal = realObject;
		id innerMock = [OCMockObject partialMockForObject:realObject];
		outerMock = innerMock;
		TestClassWithInitMethod *mockInstance = [innerMock initMethodNotCalledJustInit];
		TestClassWithInitMethod *objectInstance = [realObject initMethodNotCalledJustInit];

		// Intentionally comparing pointers.
		XCTAssertEqual(mockInstance, innerMock);

		// Intentionally comparing pointers.
		XCTAssertEqual(objectInstance, realObject, @"No Stub, so realObject should be returned");

		__unused id value = [[[innerMock stub] andReturn:mockInstance] initMethodNotCalledJustInit];

		mockInstance = [innerMock initMethodWithNestedInit];
		XCTAssertEqual(mockInstance, innerMock);

		objectInstance = [realObject initMethodWithNestedInit];
		XCTAssertEqual(objectInstance, innerMock, @"Stubbed, so mock should be returned");
	}
	XCTAssertNil(outerMock, @"innerMock should not be leaked.");
	XCTAssertNil(outerReal, @"realObject should not be leaked.");
}

- (void)testPartialMockNestedInitReturnsCorrectSelfAndDoesntLeakWithMacro
{
	__weak id outerMock;
	__weak id outerReal;
	@autoreleasepool
	{
		TestClassWithInitMethod *realObject = [TestClassWithInitMethod alloc];
		outerReal = realObject;
		id innerMock = [OCMockObject partialMockForObject:realObject];
		outerMock = innerMock;
		TestClassWithInitMethod *mockInstance = [innerMock initMethodNotCalledJustInit];
		TestClassWithInitMethod *objectInstance = [realObject initMethodNotCalledJustInit];

		// Intentionally comparing pointers.
		XCTAssertEqual(mockInstance, innerMock);

		// Intentionally comparing pointers.
		XCTAssertEqual(objectInstance, realObject, @"No Stub, so realObject should be returned");

		OCMStub([innerMock initMethodNotCalledJustInit]).andReturn(mockInstance);

		mockInstance = [innerMock initMethodWithNestedInit];
		XCTAssertEqual(mockInstance, innerMock);

		objectInstance = [realObject initMethodWithNestedInit];
		XCTAssertEqual(objectInstance, innerMock, @"Stubbed, so mock should be returned");
	}
	XCTAssertNil(outerMock, @"innerMock should not be leaked.");
	XCTAssertNil(outerReal, @"realObject should not be leaked.");
}

- (void)testDoesntLeakWhenAnInitMethodIsStubbedAndReturnsDifferentObject {
	__weak id outerMock;
	__weak id outerReal;
	@autoreleasepool
	{
		TestClassWithInitMethod *realObject = [[TestClassWithInitMethod alloc] init];
		outerReal = realObject;
		id innerMock = OCMClassMock([TestClassWithInitMethod class]);
		outerMock = innerMock;
		__unused id value = [[[innerMock stub] andReturn:realObject] initMethodNotCalledJustInit];
		TestClassWithInitMethod *object = [innerMock initMethodNotCalledJustInit];
		XCTAssertEqualObjects(object, realObject, @"Stub should return expected object.");
	}
	XCTAssertNil(outerMock, @"innerMock should not be leaked.");
	XCTAssertNil(outerReal, @"outerReal should not be leaked.");
}

- (void)testDoesntLeakWhenAnInitMethodIsStubbedWithMacroAndReturnsDifferentObject {
	__weak id outerMock;
	__weak id outerReal;
	@autoreleasepool
	{
		TestClassWithInitMethod *realObject = [[TestClassWithInitMethod alloc] init];
		outerReal = realObject;
		id innerMock = OCMClassMock([TestClassWithInitMethod class]);
		outerMock = innerMock;
		OCMStub([innerMock initMethodNotCalledJustInit]).andReturn(realObject);
		TestClassWithInitMethod *object = [innerMock initMethodNotCalledJustInit];
		XCTAssertEqualObjects(object, realObject, @"Stub should return expected object.");
	}
	XCTAssertNil(outerMock, @"innerMock should not be leaked.");
	XCTAssertNil(outerReal, @"outerReal should not be leaked.");
}

- (void)testUnderscoreInit {
	// According to https://clang.llvm.org/docs/AutomaticReferenceCounting.html#method-families
	// methods that are part of families are allowed to start with underscores.
	__weak id outerMock;
	__weak id outerReal;
	@autoreleasepool
	{
		TestClassWithInitMethod *realObject = [[TestClassWithInitMethod alloc] init];
		outerReal = realObject;
		id innerMock = OCMClassMock([TestClassWithInitMethod class]);
		outerMock = innerMock;
		__unused id value = [[[innerMock stub] andReturn:realObject] _init];
		TestClassWithInitMethod *object = [innerMock _init];
		XCTAssertEqualObjects(object, realObject, @"Stub should return expected object.");
	}
	XCTAssertNil(outerMock, @"innerMock should not be leaked.");
	XCTAssertNil(outerReal, @"outerReal should not be leaked.");
}

- (void)testInitStubWithNoReturnValueSetDoesntLeak {
	__weak id outerMock;
	@autoreleasepool
	{
		id innerMock = OCMClassMock([TestClassWithInitMethod class]);
		outerMock = innerMock;
		__unused id value = [[innerMock stub] initMethodNotCalledJustInit];
	}
	XCTAssertNil(outerMock, @"innerMock should not be leaked.");
}

- (void)testInitStubWithNoReturnValueSetWithMacroDoesntLeak {
  __weak id outerMock;
  @autoreleasepool
  {
    id innerMock = OCMClassMock([TestClassWithInitMethod class]);
    outerMock = innerMock;
    OCMStub([innerMock initMethodNotCalledJustInit]);
  }
  XCTAssertNil(outerMock, @"innerMock should not be leaked.");
}

- (void)testInitStubWithNoReturnValueSetThrowsWhenCalled {
  id mock = OCMClassMock([TestClassWithInitMethod class]);
  __unused id value = [[mock stub] initMethodNotCalledJustInit];
  XCTAssertThrowsSpecificNamed([mock initMethodNotCalledJustInit], NSException, NSInvalidArgumentException);
}

- (void)testInitStubWithNoReturnValueSetWithMacroThrowsWhenCalled {
  id mock = OCMClassMock([TestClassWithInitMethod class]);
  OCMStub([mock initMethodNotCalledJustInit]);
  XCTAssertThrowsSpecificNamed([mock initMethodNotCalledJustInit], NSException, NSInvalidArgumentException);
}

- (void)testInitStubWithRejectMacro {
  id mock = OCMClassMock([TestClassWithInitMethod class]);
  OCMReject([mock initMethodNotCalledJustInit]);
}

@end
