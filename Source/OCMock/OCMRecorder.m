/*
 *  Copyright (c) 2014-2020 Erik Doernenburg and contributors
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

#import <objc/runtime.h>
#import "OCMRecorder.h"
#import "OCMockObject.h"
#import "OCMInvocationMatcher.h"
#import "OCClassMockObject.h"
#import "NSInvocation+OCMAdditions.h"

@implementation OCMRecorder

- (instancetype)init
{
    // no super, we're inheriting from NSProxy
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

- (BOOL)wasUsed
{
    return wasUsed;
}

- (id)initTarget {
    return initTarget;
}

- (void)setInitTarget:(id)target
{
    initTarget = target;
}

#pragma mark  Modifying the matcher

- (id)classMethod
{
    [self setInitTarget:self];
    // should we handle the case where this is called with a mock that isn't a class mock?
    [invocationMatcher setRecordedAsClassMethod:YES];
    return self;
}

- (id)ignoringNonObjectArgs
{
    [self setInitTarget:self];
    [invocationMatcher setIgnoreNonObjectArgs:YES];
    return self;
}


#pragma mark  Recording the actual invocation

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
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
	[anInvocation setTarget:nil];
	wasUsed = YES;
    [invocationMatcher setInvocation:anInvocation];
	if([anInvocation methodIsInInitFamily])
	{
        // init methods must be instance methods and must return an Objective-C pointer type.
        // An init called from ARC code is expecting to get something back to release if it chose
        // to retain it before the init call. If we don't set a return type here, ARC code may crash.
        id target = [self initTarget];
        if (!target) {
          // target was never set by forwarding, so target must be us.
          target = self;
        }
        [anInvocation setReturnValue:&target];
	}
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
	wasUsed = YES;
    [NSException raise:NSInvalidArgumentException format:@"%@: cannot stub/expect/verify method '%@' because no such method exists in the mocked class.", mockObject, NSStringFromSelector(aSelector)];
}


@end


@implementation OCMRecorder (Properties)

@dynamic _ignoringNonObjectArgs;

- (OCMRecorder *(^)(void))_ignoringNonObjectArgs
{
    id (^theBlock)(void) = ^ (void)
    {
        return [self ignoringNonObjectArgs];
    };
    return [[theBlock copy] autorelease];
}


@end
