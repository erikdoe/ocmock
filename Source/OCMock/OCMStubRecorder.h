/*
 *  Copyright (c) 2004-2021 Erik Doernenburg and contributors
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

#import <OCMock/OCMFunctions.h>
#import <OCMock/OCMRecorder.h>

#import <objc/runtime.h>
#import <string.h>

#if !defined(OCM_DISABLE_XCTEST_FEATURES)
@class XCTestExpectation;
#endif

@interface OCMStubRecorder : OCMRecorder

- (id)andReturn:(id)anObject;
- (id)andReturnValue:(NSValue *)aValue;
- (id)andThrow:(NSException *)anException;
- (id)andPost:(NSNotification *)aNotification;
- (id)andCall:(SEL)selector onObject:(id)anObject;
- (id)andDo:(void (^)(NSInvocation *invocation))block;
- (id)andForwardToRealObject;

#if !defined(OCM_DISABLE_XCTEST_FEATURES)
- (id)andFulfill:(XCTestExpectation *)expectation;
#endif

@end


@interface OCMStubRecorder (Properties)

// Used to autoselect `return` vs `returnValue` based on type.
// Gets complicated because NSValue cannot be NSCoded if it contains a type
// of void*, and typeof(nil) is void* in ObjC (but not ObjC++) code.
// Also we want to avoid undefined behaviours by casting _val into an id
// if it isn't a pointer type.
#define andReturn(aValue) _andReturn(({                                        \
  __typeof__(aValue) _val = (aValue);                                          \
  const char *_encoding = @encode(__typeof(aValue));                           \
  const void *_nilPtr = nil;                                                   \
  BOOL _objectOrNil = OCMIsObjectType(_encoding) ||                            \
                      (strcmp(_encoding, @encode(void *)) == 0 &&              \
                       memcmp((void*)&_val, &_nilPtr, sizeof(void*)) == 0);    \
  id _retVal;                                                                  \
  if(_objectOrNil)                                                             \
  {                                                                            \
    __unsafe_unretained id _unsafeId;                                          \
    memcpy(&_unsafeId, (void*)&_val, sizeof(id));                              \
    _retVal = _unsafeId;                                                       \
  }                                                                            \
  else                                                                         \
  {                                                                            \
    _retVal = [NSValue valueWithBytes:&_val objCType:_encoding];               \
  }                                                                            \
  [NSArray arrayWithObjects:@(_objectOrNil), _retVal, nil];                    \
}))
@property (nonatomic, readonly) OCMStubRecorder *(^ _andReturn)(NSArray<id> *);

#define andThrow(anException) _andThrow(anException)
@property (nonatomic, readonly) OCMStubRecorder *(^ _andThrow)(NSException *);

#define andPost(aNotification) _andPost(aNotification)
@property (nonatomic, readonly) OCMStubRecorder *(^ _andPost)(NSNotification *);

#define andCall(anObject, aSelector) _andCall(anObject, aSelector)
@property (nonatomic, readonly) OCMStubRecorder *(^ _andCall)(id, SEL);

#define andDo(aBlock) _andDo(aBlock)
@property (nonatomic, readonly) OCMStubRecorder *(^ _andDo)(void (^)(NSInvocation *));

#define andForwardToRealObject() _andForwardToRealObject()
@property (nonatomic, readonly) OCMStubRecorder *(^ _andForwardToRealObject)(void);

#if !defined(OCM_DISABLE_XCTEST_FEATURES)
#define andFulfill(anExpectation) _andFulfill(anExpectation)
@property (nonatomic, readonly) OCMStubRecorder *(^ _andFulfill)(XCTestExpectation *);
#endif

@property (nonatomic, readonly) OCMStubRecorder *(^ _ignoringNonObjectArgs)(void);

#define andBreak() _andDo(^(NSInvocation *_invocation)                \
{                                                                     \
  __builtin_debugtrap();                                              \
})                                                                    \

#define andLog(_format, ...) _andDo(^(NSInvocation *_invocation)      \
{                                                                     \
  NSLog(_format, ##__VA_ARGS__);                                      \
})                                                                    \

@end
