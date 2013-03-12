//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMock.h>
#import "OCMockObjectTests+ClassMethodMocking.h"

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



@implementation OCMockObjectTests(ClassMethodMocking)

- (void)testCanStubClassMethod
{
    mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];

    [[[[mock stub] classMethod] andReturn:@"mocked"] foo];
    
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed class method.");
}

- (void)testClassReceivesMethodsAfterStopWasCalled
{
    mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked"] foo];
    [mock stopMocking];
    
    STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should not have stubbed class method.");
}

- (void)testClassReceivesMethodAgainWhenExpectedCallOccurred
{
    mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];

   	[[[[mock expect] classMethod] andReturn:@"mocked"] foo];
   	
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed method.");
   	STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should have 'unstubbed' method.");
}

- (void)testStubsOnlyClassMethodWhenInstanceMethodWithSameNameExists
{
    mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked"] bar];
    
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods bar], @"Should have stubbed class method.");
    STAssertThrows([mock bar], @"Should not have stubbed instance method.");
}

- (void)testStubsClassMethodWhenNoInstanceMethodExistsWithName
{
    mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[mock stub] andReturn:@"mocked"] foo];
    
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed class method.");
}

- (void)testStubsCanDistinguishInstanceAndClassMethods
{
    mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked-class"] bar];
    [[[mock stub] andReturn:@"mocked-instance"] bar];
    
    STAssertEqualObjects(@"mocked-class", [TestClassWithClassMethods bar], @"Should have stubbed class method.");
    STAssertEqualObjects(@"mocked-instance", [mock bar], @"Should have stubbed instance method.");
}


@end
