/*
 *  Copyright (c) 2015 Erik Doernenburg and contributors
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

@interface TestClassWithDynamicProperties : NSObject
@property(nonatomic, retain) NSDictionary *anObject;
@property(nonatomic, assign) NSUInteger aUInt;
@property(nonatomic, assign) NSInteger __aPrivateInt;
@property(getter=customGetter, setter=customSetter:) NSDictionary *aCustomProperty;

@end

@implementation TestClassWithDynamicProperties
@dynamic anObject;
@dynamic aUInt;
@dynamic __aPrivateInt;
@dynamic aCustomProperty;

@end


@interface OCMockObjectDynamicPropertyMockingTests : XCTestCase

@end

@implementation OCMockObjectDynamicPropertyMockingTests

#pragma mark   Tests stubbing dynamic properties

- (void)testCanStubDynamicPropertiesWithIdType
{
    id mock = [OCMockObject mockForClass:[TestClassWithDynamicProperties class]];
    NSDictionary *testDict = @{@"test-key" : @"test-value"};
    [[[mock stub] andReturn:testDict] anObject];
    XCTAssertEqualObjects(testDict, [mock anObject]);
  
    [[mock stub] setAnObject:testDict];
}

- (void)testCanStubDynamicPropertiesWithUIntType
{
    id mock = [OCMockObject mockForClass:[TestClassWithDynamicProperties class]];
    NSUInteger someUInt = 5;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(someUInt)] aUInt];
    XCTAssertEqual(5, [mock aUInt]);
    
    [[mock stub] setAUInt:5];
}

- (void)testCanStubDynamicPropertiesWithIntType
{
    id mock = [OCMockObject mockForClass:[TestClassWithDynamicProperties class]];
    NSInteger someInt = -10;
    [[[mock stub] andReturnValue:OCMOCK_VALUE(someInt)] __aPrivateInt];
    XCTAssertEqual(-10, [mock __aPrivateInt]);
    
    [[mock stub] set__aPrivateInt:10];
}

- (void)testCanStubDynamicPropertiesWithCustomGetterAndSetter {
    id mock = [OCMockObject mockForClass:[TestClassWithDynamicProperties class]];
    NSDictionary *testDict = @{@"test-key" : @"test-value"};
    [[[mock stub] andReturn:testDict] customGetter];
    XCTAssertEqualObjects(testDict, [mock customGetter]);
    
    [[mock stub] customSetter:testDict];
}

@end