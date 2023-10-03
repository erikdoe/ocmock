/*
 *  Copyright (c) 2020-2021 Erik Doernenburg and contributors
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
#import "OCMock.h"

#if !defined(__cplusplus)
#error This file must be compiled with C++
#endif

#if !__has_feature(cxx_nullptr)
#error This file must be compiled with a version of C++ that supports nullptr
#endif

#pragma mark Helper classes

class IntCounter
{
public:
    IntCounter()
        : counter_(nullptr)
    {
    }
    ~IntCounter()
    {
        if(counter_)
        {
            (*counter_)--;
        }
    }
    void init(int *counter)
    {
        counter_ = counter;
        if(counter_)
        {
            (*counter_)++;
        }
    }

private:
    int *counter_;
};

@interface BaseFake : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCounter:(int *)counter NS_DESIGNATED_INITIALIZER;
@end

@interface DerivedFake : BaseFake
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCounter:(int *)counter NS_DESIGNATED_INITIALIZER;
@end

@implementation BaseFake
{
    IntCounter _counter;
}

- (instancetype)initWithCounter:(int *)counter
{
    self = [super init];
    if(self)
    {
        _counter.init(counter);
    }
    return self;
}

@end

@implementation DerivedFake

- (instancetype)initWithCounter:(int *)counter
{
    return [super initWithCounter:counter];
}

@end

#pragma mark Tests

@interface OCMCPlusPlus11Tests : XCTestCase
@end

@implementation OCMCPlusPlus11Tests

- (void)testSetsUpStubReturningNilForIdReturnType
{
    id mock = OCMPartialMock([NSArray arrayWithObject:@"Foo"]);

    OCMExpect([mock lastObject]).andReturn(nil);
    XCTAssertNil([mock lastObject], @"Should have returned stubbed value");

    OCMExpect([mock lastObject]).andReturn(Nil);
    XCTAssertNil([mock lastObject], @"Should have returned stubbed value");
}

- (void)testPartialMockBaseCXXDestruct
{
    int counter = 0;
    @autoreleasepool
    {
        BaseFake *fake = [[BaseFake alloc] initWithCounter:&counter];
        XCTAssertEqual(counter, 1);
        id __unused mockFake = OCMPartialMock(fake);
        XCTAssertEqual(counter, 1);
    }
    XCTAssertEqual(counter, 0);
}

- (void)testPartialMockDerivedCXXDestruct
{
    int counter = 0;
    @autoreleasepool
    {
        DerivedFake *fake = [[DerivedFake alloc] initWithCounter:&counter];
        XCTAssertEqual(counter, 1);
        id __unused mockFake = OCMPartialMock(fake);
        XCTAssertEqual(counter, 1);
    }
    XCTAssertEqual(counter, 0);
}

@end
