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

- (void)testRealClassReceivesMethodsAfterStopWasCalled
{
    mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked"] foo];
    [mock stopMocking];
    
    STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should not have stubbed class method.");
}

- (void)testReturnsToClassImplementationWhenExpectedCallOccurred
{
    mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];

   	[[[[mock expect] classMethod] andReturn:@"mocked"] foo];
   	
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed method.");
   	STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should have 'unstubbed' method.");
}

- (void)testCanStubClassMethodWhenInstanceMethodWithSameNameExists
{
    mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked"] bar];
    
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods bar], @"Should have stubbed class method.");
}

- (void)testStubsClassMethodWhenNoInstanceMethodExistsWithName
{
    mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[mock stub] andReturn:@"mocked"] foo];
    
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed class method.");
}

@end
