/*
 *  Copyright (c) 2009-2021 Erik Doernenburg and contributors
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

// Options for controlling how OCMArgs function.
typedef NS_OPTIONS(NSUInteger, OCMArgOptions) {
    // The OCMArg will retain/release the value passed to it, and invocations on a stub that has
    // arguments that the OCMArg is constraining will retain the values passed to them for the
    // arguments being constrained by the OCMArg.
    OCMArgDefaultOptions = 0UL,

    // The OCMArg will not retain/release the value passed to it. Is only applicable for
    // `isEqual:options:` and `isNotEqual:options`. The caller is responsible for making sure that the
    // arg is valid for the required lifetime. Note that unless `OCMArgDoNotRetainInvocationArg` is
    // also specified, invocations of the stub that the OCMArg arg is constraining will retain values
    // passed to them for the arguments being constrained by the OCMArg. `OCMArgNeverRetainArg` is
    // usually what you want to use.
    OCMArgDoNotRetainStubArg = (1UL << 0),

    // Invocations on a stub that has arguments that the OCMArg is constraining will retain/release
    // the values passed to them for the arguments being constrained by the OCMArg.
    OCMArgDoNotRetainInvocationArg = (1UL << 1),

    // Invocations on a stub that has arguments that the OCMArg is constraining will copy/release
    // the values passed to them for the arguments being constrained by the OCMArg.
    OCMArgCopyInvocationArg = (1UL << 2),

    OCMArgNeverRetainArg = OCMArgDoNotRetainStubArg | OCMArgDoNotRetainInvocationArg,
};

@interface OCMArg : NSObject
// constraining arguments

// constrain using OCMArgDefaultOptions
+ (id)any;
+ (SEL)anySelector;
+ (void *)anyPointer;
+ (id __autoreleasing *)anyObjectRef;
+ (id)isNil;
+ (id)isNotNil;
+ (id)isEqual:(id)value;
+ (id)isNotEqual:(id)value;
+ (id)isKindOfClass:(Class)cls;
+ (id)checkWithSelector:(SEL)selector onObject:(id)anObject;
+ (id)checkWithBlock:(BOOL (^)(id obj))block;

+ (id)anyWithOptions:(OCMArgOptions)options;
+ (id)isNilWithOptions:(OCMArgOptions)options;
+ (id)isNotNilWithOptions:(OCMArgOptions)options;
+ (id)isEqual:(id)value options:(OCMArgOptions)options;
+ (id)isNotEqual:(id)value options:(OCMArgOptions)options;
+ (id)isKindOfClass:(Class)cls options:(OCMArgOptions)options;
+ (id)checkWithSelector:(SEL)selector onObject:(id)anObject options:(OCMArgOptions)options;
+ (id)checkWithOptions:(OCMArgOptions)options withBlock:(BOOL (^)(id obj))block;

// manipulating arguments

+ (id *)setTo:(id)value;
+ (void *)setToValue:(NSValue *)value;
+ (id)invokeBlock;
+ (id)invokeBlockWithArgs:(id)first, ... NS_REQUIRES_NIL_TERMINATION;

+ (id)defaultValue;

// internal use only

+ (id)resolveSpecialValues:(NSValue *)value;

@end

#define OCMOCK_ANY [OCMArg any]

#define OCMOCK_VALUE(variable) \
    ({ __typeof__(variable) __v = (variable); [NSValue value:&__v withObjCType:@encode(__typeof__(__v))]; })
