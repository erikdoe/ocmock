//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMock.h>
#import "OCClassMockObject.h"
#import "OCMockObjectClassMethodMockingTests.h"

#pragma mark   Helper classes

@interface TestClassWithClassMethods : NSObject
+ (NSString *)foo;
+ (NSString *)bar;
- (NSString *)bar;
@end

@implementation TestClassWithClassMethods

+ (NSString *)foo
{
    return @"Foo-ClassMethod";
}

+ (NSString *)bar
{
    return @"Bar-ClassMethod";
}

- (NSString *)bar
{
    return @"Bar";
}

@end



@implementation OCMockObjectClassMethodMockingTests

#pragma mark   Tests stubbing class methods

- (void)testCanStubClassMethod
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];

    [[[[mock stub] classMethod] andReturn:@"mocked"] foo];
    
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed class method.");
}

- (void)testClassReceivesMethodsAfterStopWasCalled
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked"] foo];
    [mock stopMocking];
    
    STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should not have stubbed class method.");
}

- (void)testClassReceivesMethodAgainWhenExpectedCallOccurred
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];

   	[[[[mock expect] classMethod] andReturn:@"mocked"] foo];
   	
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed method.");
   	STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should have 'unstubbed' method.");
}

- (void)testStubsOnlyClassMethodWhenInstanceMethodWithSameNameExists
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked"] bar];
    
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods bar], @"Should have stubbed class method.");
    STAssertThrows([mock bar], @"Should not have stubbed instance method.");
}

- (void)testStubsClassMethodWhenNoInstanceMethodExistsWithName
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[mock stub] andReturn:@"mocked"] foo];
    
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed class method.");
}

- (void)testStubsCanDistinguishInstanceAndClassMethods
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked-class"] bar];
    [[[mock stub] andReturn:@"mocked-instance"] bar];
    
    STAssertEqualObjects(@"mocked-class", [TestClassWithClassMethods bar], @"Should have stubbed class method.");
    STAssertEqualObjects(@"mocked-instance", [mock bar], @"Should have stubbed instance method.");
}

- (void)testRevertsAllStubbedMethodsOnDealloc
{
    id mock = [[OCClassMockObject alloc] initWithClass:[TestClassWithClassMethods class]];

    [[[[mock stub] classMethod] andReturn:@"mocked-foo"] foo];
    [[[[mock stub] classMethod] andReturn:@"mocked-bar"] bar];

    STAssertEqualObjects(@"mocked-foo", [TestClassWithClassMethods foo], @"Should have stubbed class method 'foo'.");
    STAssertEqualObjects(@"mocked-bar", [TestClassWithClassMethods bar], @"Should have stubbed class method 'bar'.");

    [mock release];

    STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should have 'unstubbed' class method 'foo'.");
    STAssertEqualObjects(@"Bar-ClassMethod", [TestClassWithClassMethods bar], @"Should have 'unstubbed' class method 'bar'.");
}


@end
