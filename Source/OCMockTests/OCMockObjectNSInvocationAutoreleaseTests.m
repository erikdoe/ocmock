/*
 *  Copyright (c) 2014 Erik Doernenburg and contributors
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


/*
 NSInovation Autorelease Tests
 
 These tests test a specific senario where the return value of an NSInvocation is released before the invocation is invoked. This will cause a crash.
 The senarios here are contrived, but they were come upon by trying to mock an NSURLSession and NSURLSessionDataTask objects.
 
 To reproduce the specific bug, reimplement handleInvocation: in OCMockObject to use indexOfObjectPassingTest: instead of the custom implementation there
 */

@interface OCMockObjectNSInvocationAutoreleaseTests : XCTestCase

@end

#pragma mark - Helper Class Interfaces
// These are classes we want to mock, so don't have a good idea of their implementation

@interface OCMockTestTask: NSObject

- (void)runTask;

@end

@interface OCMockTestTaskCreator : NSObject

- (OCMockTestTask *)createTaskWithBlock:(void(^)())block;

@end

#pragma mark - Tests

@implementation OCMockObjectNSInvocationAutoreleaseTests

- (void)testMockTaskCreator
{
    // First, let's create our mocks
    id mockCreator = [OCMockObject mockForClass:[OCMockTestTaskCreator class]];
    
    // Let's stub it out, so that when we call runTask on a task, it runs our own block
    [[[mockCreator stub] andDo:^(NSInvocation *invocation) {
        // First, let's grab the task block
        // We need to do some ARC fun stuff to make sure we retain this block properly
        __unsafe_unretained void(^task)() = nil;
        [invocation getArgument:&task atIndex:2];
        void(^retainedTask)() = task;
        
        // Now, let's create a mock task
        // Note, we use autoreleasing, because this will be returned by this method
        // This is what we're testing. Does this get released before we try to use it?
        __autoreleasing id mockTask = [OCMockObject mockForClass:[OCMockTestTask class]];
        [[[mockTask stub] andDo:^(NSInvocation *invocation) {
            // We should run the task here
            retainedTask();
        }] runTask];
        
        [invocation setReturnValue:&mockTask];

    }] createTaskWithBlock:OCMOCK_ANY];
    
    // Now, let's try running this thing.
    // If we don't crash, then the test succeeds. If we crash, then the test fails.
    
    __block BOOL success = NO;
    OCMockTestTask *task = [mockCreator createTaskWithBlock:^{
        success = YES;
    }];
    [task runTask];
    
    XCTAssertTrue(success, @"We should have run our custom block which set this to YES");
}

@end

#pragma mark - Helper Classes Implementation

@implementation OCMockTestTask

- (void)runTask {
    NSAssert(NO, @"We don't want this method to run. We are trying to mock it out so that another method runs in its place");
}

@end

@implementation OCMockTestTaskCreator

- (OCMockTestTask *)createTaskWithBlock:(void (^)())block {
    NSAssert(NO, @"We don't want this method to run. We are trying to mock it out so that another method runs in its place");
    return nil;
}

@end
