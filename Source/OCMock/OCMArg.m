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

#import <objc/runtime.h>
#import "OCMArg.h"
#import "OCMBlockArgCaller.h"
#import "OCMConstraint.h"
#import "OCMPassByRefSetter.h"


@implementation OCMArg

+ (id)any
{
	  return [self anyWithOptions:OCMArgDefaultOptions];
}

+ (void *)anyPointer
{
    return (void *)0x01234567;
}

+ (id __autoreleasing *)anyObjectRef
{
    return (id *)[self anyPointer];
}

+ (SEL)anySelector
{
    return NSSelectorFromString(@"aSelectorThatMatchesAnySelector");
}

+ (id)isNil
{

	  return [self isNilWithOptions:OCMArgDefaultOptions];
}

+ (id)isNotNil
{
	  return [self isNotNilWithOptions:OCMArgDefaultOptions];
}

+ (id)isEqual:(id)value
{
    return [self isEqual:value options:OCMArgDefaultOptions];
}

+ (id)isNotEqual:(id)value
{
    return [self isNotEqual:value options:OCMArgDefaultOptions];
}

+ (id)isKindOfClass:(Class)cls
{
    return [self isKindOfClass:cls options:OCMArgDefaultOptions];
}

+ (id)checkWithSelector:(SEL)selector onObject:(id)anObject
{
    return [self checkWithSelector:selector onObject:anObject options:OCMArgDefaultOptions];
}

+ (id)checkWithBlock:(BOOL (^)(id))block
{
    return [self checkWithOptions:OCMArgDefaultOptions withBlock:block];
}

+ (id)anyWithOptions:(OCMArgOptions)options
{
    return [[[OCMAnyConstraint alloc] initWithOptions:[self constraintOptionsFromArgOptions:options]] autorelease];
}

+ (id)isNilWithOptions:(OCMArgOptions)options
{
    return [[[OCMIsEqualConstraint alloc] initWithTestValue:nil options:[self constraintOptionsFromArgOptions:options]] autorelease];
}

+ (id)isNotNilWithOptions:(OCMArgOptions)options
{
    return [[[OCMIsNotEqualConstraint alloc] initWithTestValue:nil options:[self constraintOptionsFromArgOptions:options]] autorelease];
}

+ (id)isEqual:(id)value options:(OCMArgOptions)options
{
    return [[[OCMIsEqualConstraint alloc] initWithTestValue:value options:[self constraintOptionsFromArgOptions:options]] autorelease];
}

+ (id)isNotEqual:(id)value options:(OCMArgOptions)options
{
    return [[[OCMIsNotEqualConstraint alloc] initWithTestValue:value options:[self constraintOptionsFromArgOptions:options]] autorelease];
}

+ (id)isKindOfClass:(Class)cls options:(OCMArgOptions)options
{
    return [[[OCMBlockConstraint alloc] initWithOptions:[self constraintOptionsFromArgOptions:options] block:^BOOL(id obj) {
          return [obj isKindOfClass:cls];
      }] autorelease];
}

+ (id)checkWithSelector:(SEL)selector onObject:(id)anObject options:(OCMArgOptions)options
{
    return [OCMConstraint constraintWithSelector:selector onObject:anObject options:[self constraintOptionsFromArgOptions:options]];
}

+ (id)checkWithOptions:(OCMArgOptions)options withBlock:(BOOL (^)(id obj))block
{
    return [[[OCMBlockConstraint alloc] initWithOptions:[self constraintOptionsFromArgOptions:options] block:block] autorelease];
}

+ (id *)setTo:(id)value
{
    return (id *)[[[OCMPassByRefSetter alloc] initWithValue:value] autorelease];
}

+ (void *)setToValue:(NSValue *)value
{
    return (id *)[[[OCMPassByRefSetter alloc] initWithValue:value] autorelease];
}

+ (id)invokeBlock
{
    return [[[OCMBlockArgCaller alloc] init] autorelease];
}

+ (id)invokeBlockWithArgs:(id)first, ... NS_REQUIRES_NIL_TERMINATION
{
    NSMutableArray *params = [NSMutableArray array];
    va_list args;
    if(first)
    {
        [params addObject:first];
        va_start(args, first);
        id obj;
        while((obj = va_arg(args, id)))
        {
            [params addObject:obj];
        }
        va_end(args);
    }
    return [[[OCMBlockArgCaller alloc] initWithBlockArguments:params] autorelease];
}

+ (id)defaultValue
{
    return [NSNull null];
}


+ (id)resolveSpecialValues:(NSValue *)value
{
    const char *type = [value objCType];
    if(type[0] == '^')
    {
        void *pointer = [value pointerValue];
        if(pointer == [self anyPointer])
            return [OCMArg any];
        if((pointer != NULL) && [OCMPassByRefSetter isPassByRefSetterInstance:pointer])
            return (id)pointer;
    }
    else if(type[0] == ':')
    {
        SEL selector;
        [value getValue:&selector];
        if(selector == NSSelectorFromString(@"aSelectorThatMatchesAnySelector"))
            return [OCMArg any];
    }
    return value;
}

+ (OCMConstraintOptions)constraintOptionsFromArgOptions:(OCMArgOptions)argOptions
{
  OCMConstraintOptions constraintOptions = 0;
  if(argOptions & OCMArgDoNotRetainStubArg) constraintOptions |= OCMConstraintDoNotRetainStubArg;
  if(argOptions & OCMArgDoNotRetainInvocationArg) constraintOptions |= OCMConstraintDoNotRetainInvocationArg;
  if(argOptions & OCMArgCopyInvocationArg) constraintOptions |= OCMConstraintCopyInvocationArg;
  return constraintOptions;
}

@end
