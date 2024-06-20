/*
 *  Copyright (c) 2007-2021 Erik Doernenburg and contributors
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

// See OCMArgOptions for documentation on options.
typedef NS_OPTIONS(NSUInteger, OCMConstraintOptions) {
    OCMConstraintDefaultOptions = 0UL,
    OCMConstraintDoNotRetainStubArg = (1UL << 0),
    OCMConstraintDoNotRetainInvocationArg = (1UL << 1),
    OCMConstraintCopyInvocationArg = (1UL << 2),
    OCMConstraintNeverRetainArg = OCMConstraintDoNotRetainStubArg | OCMConstraintDoNotRetainInvocationArg,
};

@interface OCMConstraint : NSObject

@property (readonly) OCMConstraintOptions constraintOptions;

- (instancetype)initWithOptions:(OCMConstraintOptions)options NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)evaluate:(id)value;

// if you are looking for any, isNil, etc, they have moved to OCMArg

// try to use [OCMArg checkWith...] instead of the constraintWith... methods below

+ (instancetype)constraintWithSelector:(SEL)aSelector onObject:(id)anObject;
+ (instancetype)constraintWithSelector:(SEL)aSelector onObject:(id)anObject withValue:(id)aValue;

+ (instancetype)constraintWithSelector:(SEL)aSelector onObject:(id)anObject options:(OCMConstraintOptions)options;
+ (instancetype)constraintWithSelector:(SEL)aSelector onObject:(id)anObject withValue:(id)aValue options:(OCMConstraintOptions)options;

@end

@interface OCMAnyConstraint : OCMConstraint
@end

@interface OCMIsNilConstraint : OCMConstraint
@end

@interface OCMIsNotNilConstraint : OCMConstraint
@end

@interface OCMEqualityConstraint : OCMConstraint
{
    id testValue;
}

- (instancetype)initWithTestValue:(id)testValue options:(OCMConstraintOptions)options NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithOptions:(OCMConstraintOptions)options NS_UNAVAILABLE;

@end

@interface OCMIsEqualConstraint : OCMEqualityConstraint
@end

@interface OCMIsNotEqualConstraint : OCMEqualityConstraint
@end

@interface OCMInvocationConstraint : OCMConstraint
{
    NSInvocation *invocation;
}

- (instancetype)initWithInvocation:(NSInvocation *)invocation options:(OCMConstraintOptions)options NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithOptions:(OCMConstraintOptions)options NS_UNAVAILABLE;

@end

@interface OCMBlockConstraint : OCMConstraint
{
    BOOL (^block)(id);
}

- (instancetype)initWithOptions:(OCMConstraintOptions)options block:(BOOL (^)(id))block NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithOptions:(OCMConstraintOptions)options NS_UNAVAILABLE;

@end

#ifndef OCM_DISABLE_SHORT_SYNTAX
#define CONSTRAINT(aSelector) [OCMConstraint constraintWithSelector:aSelector onObject:self]
#define CONSTRAINTV(aSelector, aValue) [OCMConstraint constraintWithSelector:aSelector onObject:self withValue:(aValue)]
#endif
