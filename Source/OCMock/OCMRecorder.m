/*
 *  Copyright (c) 2014-2021 Erik Doernenburg and contributors
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

#import <limits.h>
#import <objc/runtime.h>
#import "NSInvocation+OCMAdditions.h"
#import "OCClassMockObject.h"
#import "OCMInvocationMatcher.h"
#import "OCMRecorder.h"
#import "OCMFunctionsPrivate.h"
#import "OCMMacroState.h"

@implementation OCMRecorder

- (instancetype)init
{
    // no super, we're inheriting from NSProxy
    shouldReturnMockFromInit = NO;
    return self;
}

- (instancetype)initWithMockObject:(OCMockObject *)aMockObject
{
    [self init];
    [self setMockObject:aMockObject];
    return self;
}

- (void)setMockObject:(OCMockObject *)aMockObject
{
    mockObject = aMockObject;
}

- (void)setShouldReturnMockFromInit:(BOOL)flag
{
    shouldReturnMockFromInit = flag;
}

- (void)dealloc
{
    [invocationMatcher release];
    [super dealloc];
}

- (NSString *)description
{
    return [invocationMatcher description];
}

- (OCMInvocationMatcher *)invocationMatcher
{
    return invocationMatcher;
}

- (BOOL)didRecordInvocation
{
    return [invocationMatcher recordedInvocation] != nil;
}


#pragma mark Modifying the matcher

- (id)classMethod
{
    // should we handle the case where this is called with a mock that isn't a class mock?
    [invocationMatcher setRecordedAsClassMethod:YES];
    return self;
}

- (id)ignoringNonObjectArgs
{
    [invocationMatcher setIgnoreNonObjectArgs:YES];
    return self;
}

- (BOOL)currentlyRecordingInMacro
{
    return [[OCMMacroState globalState] recorder] == self;
}

#pragma mark Recording the actual invocation

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if([self didRecordInvocation] && [self currentlyRecordingInMacro])
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Recorder attempting to record `%s` but recorder has already recorded a stub for: `%@`. "
                           @"Are there multiple invocations on mocks in a single macro?",
                           sel_getName(aSelector), [self description]];
    }
    if([invocationMatcher recordedAsClassMethod])
        return [[(OCClassMockObject *)mockObject mockedClass] methodSignatureForSelector:aSelector];

    NSMethodSignature *signature = [mockObject methodSignatureForSelector:aSelector];
    if(signature == nil)
    {
        // if we're a working with a class mock and there is a class method, auto-switch
        if(([object_getClass(mockObject) isSubclassOfClass:[OCClassMockObject class]]) &&
            ([[(OCClassMockObject *)mockObject mockedClass] respondsToSelector:aSelector]))
        {
            [self classMethod];
            signature = [self methodSignatureForSelector:aSelector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSAssert(!([self didRecordInvocation] && [self currentlyRecordingInMacro]),
             @"Should not be recording multiple stubs. This should've been prevented in `-methodSignatureForSelector`.");
    [anInvocation setTarget:nil];
    [invocationMatcher setInvocation:anInvocation];

    // If the method returns an object, we want to return a recorder so that we can trap the case
    // where multiple invocations are possibly being recorded in a single OCMStub/OCMExpect macro.
    // (this is caught in -methodSignatureForSelector).
    if(OCMIsObjectType([[anInvocation methodSignature] methodReturnType]))
    {
        id returnValue = self;
        // Code with ARC may retain the receiver of an init method before invoking it. In that case it
        // relies on the init method returning an object it can release. So, we must set the correct
        // return value here. Normally, the correct return value is the recorder but sometimes it's the
        // mock. The decision is easier to make in the mock, which is why the mock sets a flag in the
        // recorder and we simply use the flag here.
        if(shouldReturnMockFromInit && [anInvocation methodIsInInitFamily])
        {
            returnValue = mockObject;
        }
        else if ([anInvocation methodIsInCreateFamily])
        {
            // In the case of mocking a create method (new, alloc, copy, mutableCopy) we need to
            // add a retain count to keep ARC happy. This will appear as a leak in non-arc code.
            [returnValue retain];
        }
        [anInvocation setReturnValue:&returnValue];
    }
}

- (void)doesNotRecognizeSelector:(SEL)aSelector __used
{
    [NSException raise:NSInvalidArgumentException format:@"%@: cannot stub/expect/verify method '%@' because no such method exists in the mocked class.", mockObject, NSStringFromSelector(aSelector)];
}


@end


@implementation OCMRecorder (Properties)

@dynamic _ignoringNonObjectArgs;

- (OCMRecorder *(^)(void))_ignoringNonObjectArgs
{
    id (^theBlock)(void) = ^(void) {
        return [self ignoringNonObjectArgs];
    };
    return [[theBlock copy] autorelease];
}


@end
