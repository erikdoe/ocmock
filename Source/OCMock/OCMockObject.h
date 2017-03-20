/*
 *  Copyright (c) 2004-2016 Erik Doernenburg and contributors
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

#import <Foundation/Foundation.h>
#import "OCMVerifier.h"

@class OCMLocation;
@class OCMInvocationStub;
@class OCMStubRecorder;
@class OCMInvocationMatcher;
@class OCMInvocationExpectation;


@interface OCMockObject : NSProxy
{
	BOOL			isNice;
	BOOL			expectationOrderMatters;
	NSMutableArray	*stubs;
	NSMutableArray	*expectations;
	NSMutableArray	*exceptions;
    NSMutableArray  *invocations;
}

+ (id _Nonnull)mockForClass:(Class _Nonnull)aClass;
+ (id _Nonnull)mockForProtocol:(Protocol * _Nonnull)aProtocol;
+ (id _Nonnull)partialMockForObject:(NSObject * _Nonnull)anObject;

+ (id _Nonnull)niceMockForClass:(Class _Nonnull)aClass;
+ (id _Nonnull)niceMockForProtocol:(Protocol * _Nonnull)aProtocol;

+ (id _Nonnull)observerMock;

- (instancetype _Nonnull)init;

- (void)setExpectationOrderMatters:(BOOL)flag;

- (id _Nonnull)stub;
- (id _Nonnull)expect;
- (id _Nonnull)reject;

- (id _Nonnull)verify;
- (id _Nonnull)verify:(BOOL)failWithException;
- (id _Nonnull)verifyAtLocation:(OCMLocation * _Nullable)location;
- (id _Nonnull)verifyAtLocation:(OCMLocation * _Nullable)location failWithException:(BOOL)failWithException;

- (id _Nonnull)verifyWithDelay:(NSTimeInterval)delay;
- (id _Nonnull)verifyWithDelay:(NSTimeInterval)delay failWithException:(BOOL)failWithException;
- (id _Nonnull)verifyWithDelay:(NSTimeInterval)delay atLocation:(OCMLocation * _Nullable)location;
- (id _Nonnull)verifyWithDelay:(NSTimeInterval)delay atLocation:(OCMLocation * _Nullable)location failWithException:(BOOL)failWithException;

- (void)stopMocking;

// internal use only

- (void)addStub:(OCMInvocationStub * _Nonnull)aStub;
- (void)addExpectation:(OCMInvocationExpectation * _Nonnull)anExpectation;

- (BOOL)handleInvocation:(NSInvocation * _Nonnull)anInvocation;
- (void)handleUnRecordedInvocation:(NSInvocation * _Nonnull)anInvocation;
- (BOOL)handleSelector:(SEL _Nonnull)sel;

- (void)verifyInvocation:(OCMInvocationMatcher * _Nonnull)matcher;
- (void)verifyInvocation:(OCMInvocationMatcher * _Nonnull)matcher atLocation:(OCMLocation * _Nullable)location;

@end

