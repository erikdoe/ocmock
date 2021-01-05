/*
 *  Copyright (c) 2009-2020 Erik Doernenburg and contributors
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

@interface OCMArg : NSObject 

// constraining arguments

+ (id)any;
+ (SEL)anySelector;
+ (void *)anyPointer;
+ (id __autoreleasing *)anyObjectRef;
+ (id)isNil;
+ (id)isNotNil;
+ (id)isEqual:(id)value;
+ (id)isNotEqual:(id)value;
+ (id)isKindOfClass:(Class)cls;

// Be cautious using `checkWithSelector:onObject:`. Note that the selector
// will be executed before the method that is expected is recorded as having
// been executed. Therefore code like this:
// ```
// OCMExpect([foo bar:[OCMArg checkWithBlock:^(id obj) {
//     [expectation fulfill];
//     return YES;
//   }]]);
// ...
// [self waitForExpectationsWithTimeout:5 handler:nil];
// OCMVerify(foo);
// ```
// where `[foo bar:]` is executed on a different thread/queue is a race
// condition between OCMVerify being called before the OCMExpect is marked as
// having been done because `waitForExpectationsWithTimeout:handler:` may return
// before `bar:` is recorded as having been executed by `foo`.
// This will end up being a flaky test that will be a pain to deal with.
// In general use `and...` methods like `andDo:` or `andFulfill:` for any
// functionality that has side effects as they are executed after the method
// is recorded as having been executed.
+ (id)checkWithSelector:(SEL)selector onObject:(id)anObject;

// See warning about `checkWithSelector:onObject:`.
+ (id)checkWithBlock:(BOOL (^)(id obj))block;

// manipulating arguments

+ (id *)setTo:(id)value;
+ (void *)setToValue:(NSValue *)value;
+ (id)invokeBlock;
+ (id)invokeBlockWithArgs:(id)first,... NS_REQUIRES_NIL_TERMINATION;

+ (id)defaultValue;

// internal use only

+ (id)resolveSpecialValues:(NSValue *)value;

@end

#define OCMOCK_ANY [OCMArg any]

#if defined(__GNUC__) && !defined(__STRICT_ANSI__)
  #define OCMOCK_VALUE(variable) \
    ({ __typeof__(variable) __v = (variable); [NSValue value:&__v withObjCType:@encode(__typeof__(__v))]; })
#else
  #define OCMOCK_VALUE(variable) [NSValue value:&variable withObjCType:@encode(__typeof__(variable))]
#endif

