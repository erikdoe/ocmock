//
//  OCMockClassTests.m
//  OCMock
//
//  Created by Kevin Kim on 5/20/12.
//  Copyright (c) 2012 Mulle Kybernetik. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "OCMockClassTests.h"
#import "OCMockClassObject.h"

#import <objc/runtime.h>

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
}

// --------------------------------------------------------------------------------------
//	class object mocks allow stubbing/expecting on class objects
// --------------------------------------------------------------------------------------

// This test is necessarily messy and complex
//   As soon as we mock, the -forwardInvocation: is remapped on all subsequent calls.
//   So we need to check everything here to make sure it's really clean.
- (void)testKeepsForwardInvocationReplacementAndRestoration
{
    // Get the original -forwardInvocation: IMP
    Class metaClass = objc_getMetaClass(class_getName([TestClassWithClassMethod class]));
	Method forwardInvocationMethod = class_getInstanceMethod(metaClass, @selector(forwardInvocation:));
	IMP origForwardInvocation = method_getImplementation(forwardInvocationMethod);
    
    // Get the mocked -forwardInvocation: IMP
    Method mockForwardInvocationMethod = class_getInstanceMethod([OCMockClassObject class], @selector(forwardInvocationForRealObject:));
	IMP mockForwardInvocation = method_getImplementation(mockForwardInvocationMethod);

    // Setup Mock
    mockClass = [OCMockObject mockForClassObject:[TestClassWithClassMethod class]];
    
    // Test the original -forwardInvocation IMP: is cached
    IMP originalFwdInv = [mockClass originalForwardIMP];
    STAssertEquals(origForwardInvocation, originalFwdInv, @"Expected original forwardInvocation: to be cached");
    
    // Test mock -forwardInvocation is remapped - we need to reinvoke the method fetch
    forwardInvocationMethod = class_getInstanceMethod(metaClass, @selector(forwardInvocation:));
    IMP forwardInvocation = method_getImplementation(forwardInvocationMethod);
    STAssertEquals(forwardInvocation, mockForwardInvocation, @"Expected forwardInvocation: to be replaced with Mock");

    // Sanity check -forwardInvocation remapping
    STAssertTrue(origForwardInvocation != forwardInvocation, @"Expected original forwardInvocation: to not change");
    
    // Stop Mocking
    [mockClass stopMocking];
    
    // Test -forwardInvocation has been remapped to original - reinvoke the method fetch
    forwardInvocationMethod = class_getInstanceMethod(metaClass, @selector(forwardInvocation:));
    forwardInvocation = method_getImplementation(forwardInvocationMethod);
    STAssertEquals(forwardInvocation, origForwardInvocation, @"Expected forwardInvocation: to be restored to original");
}

- (void)testStubsMethodOnClassObject
{
    mockClass = [OCMockObject mockForClassObject:[TestClassWithClassMethod class]];
	[[[mockClass stub] andReturn:@"TestFoo"] method1];
	STAssertEqualObjects(@"TestFoo", [TestClassWithClassMethod method1], @"Should have stubbed method.");
}

- (void)testForwardsUnstubbedMethodsToRealClassObjectAfterStopIsCalled
{
    mockClass = [OCMockObject mockForClassObject:[TestClassWithClassMethod class]];
	[[[mockClass stub] andReturn:@"TestFoo"] method1];
    [mockClass stopMocking];
	STAssertEqualObjects(@"Foo", [TestClassWithClassMethod method1], @"Should not have stubbed method.");
}

- (void)testStopMockingUnmocksClass
{
    mockClass = [OCMockObject mockForClassObject:[TestClassWithClassMethod class]];
    Class mockClassObject = [(OCMockClassObject *)mockClass class];
    STAssertNotNil([mockClassObject existingMockForClass:[TestClassWithClassMethod class]], @"Should have mocked class to start");
    [mockClass stopMocking];
    STAssertThrowsSpecificNamed([mockClassObject existingMockForClass:[TestClassWithClassMethod class]], NSException, NSInternalInconsistencyException, @"Should not have mocked class");    
}

@end
