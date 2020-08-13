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
#import "OCMFunctionsPrivate.h"

@interface OCMFunctionsTests : XCTestCase
@end


@implementation OCMFunctionsTests

- (void)testOCMIsBlock
{
  XCTAssertFalse(OCMIsBlock([NSString class]));
  XCTAssertFalse(OCMIsBlock(@""));
  XCTAssertFalse(OCMIsBlock([NSString stringWithFormat:@"%d", 42]));
  XCTAssertFalse(OCMIsBlock(nil));
  XCTAssertTrue(OCMIsBlock(^{}));
}

@end
