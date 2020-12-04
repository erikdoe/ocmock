/*
 *  Copyright (c) 2020 Erik Doernenburg and contributors
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
#import "OCMFunctions.h"
#import "OCMFunctionsPrivate.h"

@interface OCMFunctionsTests : XCTestCase
@end


@implementation OCMFunctionsTests

- (void)testIsBlockReturnsFalseForClass
{
    XCTAssertFalse(OCMIsBlock([NSString class]));
}

- (void)testIsBlockReturnsFalseForObject
{
    XCTAssertFalse(OCMIsBlock([NSArray array]));
}

- (void)testIsBlockReturnsFalseForNil
{
    XCTAssertFalse(OCMIsBlock(nil));
}

- (void)testIsBlockReturnsTrueForBlock
{
    XCTAssertTrue(OCMIsBlock(^{}));
}

- (void)testIsMockSubclass
{
  Class cls = OCMCreateSubclass([NSString class], "foo");
  XCTAssertNotNil(cls);
  XCTAssertTrue(OCMIsMockDirectSubclass(cls));
  XCTAssertTrue(OCMIsMockSubclass(cls));
  OCMDisposeSubclass(cls);
  XCTAssertFalse(OCMIsMockSubclass([NSString class]));
  XCTAssertFalse(OCMIsMockDirectSubclass([NSString class]));
}

@end
