/*
 *  Copyright (c) 2014-2016 Erik Doernenburg and contributors
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
#import "TestProtocol.h"


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


#pragma mark   Tests for interaction with runtime and foundation conventions

@interface OCMockObjectRuntimeTests : XCTestCase

@end

@implementation OCMockObjectRuntimeTests

- (void)testRespondsToValidSelectorForClass
{
    id mock = [OCMockObject mockForClass:[NSString class]
                               protocols:@protocol(NSLocking), @protocol(TestProtocol), nil];

    XCTAssertTrue([mock respondsToSelector:@selector(lowercaseString)]);
}

- (void)testRespondsToValidSelectorForProtocols
{
    id mock = [OCMockObject mockForClass:[NSString class]
                               protocols:@protocol(NSLocking), @protocol(TestProtocol), nil];

    XCTAssertTrue([mock respondsToSelector:@selector(lock)]);
    XCTAssertTrue([mock respondsToSelector:@selector(primitiveValue)]);
}

- (void)testDoesNotRespondToInvalidSelector
{
    id mock = [OCMockObject mockForClass:[NSString class]
                               protocols:@protocol(NSLocking), @protocol(TestProtocol), nil];

    // We use a selector that's not implemented by the mock
    XCTAssertFalse([mock respondsToSelector:@selector(arrayWithArray:)]);
}

- (void)testConformsToProtocolsFromList
{
    id mock = [OCMockObject mockForClass:[NSString class]
                               protocols:@protocol(NSLocking), @protocol(TestProtocol), nil];

    XCTAssertTrue([mock conformsToProtocol:@protocol(NSLocking)]);
    XCTAssertTrue([mock conformsToProtocol:@protocol(TestProtocol)]);
}

- (void)testDoesNotConformToInvalidProtocol
{
    id mock = [OCMockObject mockForClass:[NSString class]
                               protocols:@protocol(TestProtocol), nil];

    // We use a protocol that's not implemented by the mock
    XCTAssertFalse([mock conformsToProtocol:@protocol(NSLocking)]);
}

- (void)testCanStubValueForKeyMethod
{
    id mock = [OCMockObject mockForClass:[NSObject class] protocols:nil];
    [[[mock stub] andReturn:@"SomeValue"] valueForKey:@"SomeKey"];

    id returnValue = [mock valueForKey:@"SomeKey"];

    XCTAssertEqualObjects(@"SomeValue", returnValue, @"Should have returned value that was set up.");
}


- (void)testCanMockNSMutableArray
{
    id mock = [OCMockObject niceMockForClass:[NSMutableArray class] protocols:nil];
    id anArray = [[NSMutableArray alloc] init];
}


- (void)testForwardsIsKindOfClass
{
    id mock = [OCMockObject mockForClass:[NSString class] protocols:nil];
    XCTAssertTrue([mock isKindOfClass:[NSString class]], @"Should have pretended to be the mocked class.");
}


- (void)testWorksWithTypeQualifiers
{
    id myMock = [OCMockObject mockForClass:[TestClassWithTypeQualifierMethod class] protocols:nil];

    XCTAssertNoThrow([[myMock expect] aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
    XCTAssertNoThrow([myMock aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
}

- (void)testWorksWithTypedefsToObjects
{
    id myMock = [OCMockObject mockForClass:[TestClassWithTypedefObjectArgument class] protocols:nil];
    [[[myMock stub] andReturn:@"stubbed"] stringForTypedef:[OCMArg any]];
     id actualReturn = [myMock stringForTypedef:@"Some arg that shouldn't matter"];
     XCTAssertEqualObjects(actualReturn, @"stubbed", @"Should have matched invocation.");
}


#if 0 // can't test this with ARC
- (void)testAdjustsRetainCountWhenStubbingMethodsThatCreateObjects
{
    id mock = [OCMockObject mockForClass:[NSString class] protocols:nil];
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
    id mock = [OCMockObject mockForClass:[NSString class] protocols:nil];
    XCTAssertThrowsSpecificNamed([mock performSelector:@selector(sortedArrayHint)], NSException, NSInvalidArgumentException);
}

- (void)testComplainsWhenAttemptIsMadeToStubInitMethod
{
    id mock = [OCMockObject mockForClass:[NSString class] protocols:nil];
    XCTAssertThrows([[[mock stub] init] andReturn:nil]);
}

- (void)testComplainsWhenAttemptIsMadeToStubInitMethodViaMacro
{
    id mock = [OCMockObject mockForClass:[NSString class] protocols:nil];
    XCTAssertThrows(OCMStub([mock init]));
}


- (void)testMockShouldNotRaiseWhenDescribing
{
    id mock = [OCMockObject mockForClass:[NSObject class] protocols:nil];

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

    id mock = [OCMockObject mockForClass:[TestDelegate class] protocols:nil];
    [mock stopMocking];

    int numClassesAfter = objc_getClassList(NULL, 0);
    XCTAssertEqual(numClassesBefore, numClassesAfter, @"Should have disposed dynamically generated classes.");
}

- (void)testDescriptionForClassMockObjectForNoProtocols
{
    id mock = [OCMockObject mockForClass:[NSString class] protocols:nil];
    XCTAssertEqualObjects(@"OCMockObject(NSString)", [mock description], @"Should have returned correct description.");
}

- (void)testDescriptionForClassMockObjectForSingleProtocol
{
    id mock = [OCMockObject mockForClass:[NSString class]
                               protocols:@protocol(TestProtocol), nil];
    XCTAssertEqualObjects(@"OCMockObject(NSString <TestProtocol>)", [mock description], @"Should have returned correct description.");
}

- (void)testDescriptionForClassMockObjectForMultipleProtocols
{
    id mock = [OCMockObject mockForClass:[NSString class]
                               protocols:@protocol(NSLocking), @protocol(TestProtocol), nil];
    XCTAssertEqualObjects(@"OCMockObject(NSString <NSLocking, TestProtocol>)", [mock description], @"Should have returned correct description.");
}

- (void)testCanMockFormalProtocol
{
    id mock = [OCMockObject mockForProtocols:@protocol(NSLocking), nil];
    [[mock expect] lock];

    [mock lock];

    [mock verify];
}

- (void)testCanMockMultipleProtocols
{
    id mock = OCMProtocolMock(@protocol(NSLocking), @protocol(TestProtocol));
    [[mock expect] lock];
    [[mock expect] primitiveValue];

    [mock lock];
    [mock primitiveValue];

    [mock verify];
}

- (void)testRaisesWhenUnknownMethodIsCalledOnProtocolsMock
{
    id mock = [OCMockObject mockForClass:[NSObject class]
                               protocols:@protocol(NSLocking), @protocol(TestProtocol), nil];
    XCTAssertThrows([mock lowercaseString], @"Should have raised an exception.");
}

- (void)testCanMockMultipleProtocolsNicely
{
    id mock = [OCMockObject niceMockForClass:[NSObject class]
                                   protocols:@protocol(NSLocking), @protocol(TestProtocol), nil];
    [[mock expect] lock];
    [[mock expect] primitiveValue];

    [mock lock];
    [mock primitiveValue];

    [mock verify];
}

- (void)testRaisesAnExceptionWhenAnExpectedMethodIsNotCalledOnNiceProtocolsMock
{
    id mock = [OCMockObject niceMockForClass:[NSObject class]
                                   protocols:@protocol(NSLocking), @protocol(TestProtocol), nil];
    [[mock expect] primitiveValue];
    XCTAssertThrows([mock verify], @"Should have raised an exception because method was not called.");
}

- (void)testProtocolClassMethod
{
    id mock = [OCMockObject mockForClass:[NSObject class]
                               protocols:@protocol(NSLocking), @protocol(TestProtocol), nil];
    OCMStub([mock stringValueClassMethod]).andReturn(@"stubbed");
    id result = [mock stringValueClassMethod];
    XCTAssertEqual(@"stubbed", result, @"Should have stubbed the class method.");
}

@end
