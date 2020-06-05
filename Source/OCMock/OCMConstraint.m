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

#import <limits.h>
#import "OCMConstraint.h"
#import "OCMFunctions.h"

@implementation OCMConstraint

- (instancetype)initWithOptions:(OCMConstraintOptions)options
{
  self = [super init];
  if(self)
  {
    OCMConstraintOptions badOptions = (OCMConstraintDoNotRetainInvocationArg | OCMConstraintCopyInvocationArg);
    if((options & badOptions) == badOptions)
    {
      [NSException raise:NSInvalidArgumentException format:@"`OCMConstraintDoNotRetainInvocationArg` and `OCMConstraintCopyInvocationArg` are mutually exclusive."];
    }
    _constraintOptions = options;
  }
  return self;
}

- (BOOL)evaluate:(id)value
{
    return NO;
}

- (id)copyWithZone:(struct _NSZone *)zone __unused
{
    return [self retain];
}

+ (instancetype)constraintWithSelector:(SEL)aSelector onObject:(id)anObject
{
  return [self constraintWithSelector:aSelector onObject:anObject options:OCMConstraintDefaultOptions];
}

+ (instancetype)constraintWithSelector:(SEL)aSelector onObject:(id)anObject withValue:(id)aValue
{
  return [self constraintWithSelector:aSelector onObject:anObject withValue:aValue options:OCMConstraintDefaultOptions];
}

+ (NSInvocation *)invocationWithSelector:(SEL)aSelector onObject:(id)anObject
{
  NSMethodSignature *signature = [anObject methodSignatureForSelector:aSelector];
  if(signature == nil)
    [NSException raise:NSInvalidArgumentException format:@"Unknown selector %@ used in constraint.", NSStringFromSelector(aSelector)];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:anObject];
  [invocation setSelector:aSelector];
  return invocation;
}

+ (instancetype)constraintWithSelector:(SEL)aSelector onObject:(id)anObject options:(OCMConstraintOptions)options
{
    NSInvocation *invocation = [self invocationWithSelector:aSelector onObject:anObject];
    return [[[OCMInvocationConstraint alloc] initWithInvocation:invocation options:options] autorelease];
}

+ (instancetype)constraintWithSelector:(SEL)aSelector onObject:(id)anObject withValue:(id)aValue options:(OCMConstraintOptions)options
{
    NSInvocation *invocation = [self invocationWithSelector:aSelector onObject:anObject];
    if([[invocation methodSignature] numberOfArguments] < 4)
        [NSException raise:NSInvalidArgumentException format:@"Constraint with value requires selector with two arguments."];
    [invocation setArgument:&aValue atIndex:3];
    return [[[OCMInvocationConstraint alloc] initWithInvocation:invocation options:options] autorelease];
}


@end


#pragma mark -

@implementation OCMAnyConstraint

- (instancetype)initWithOptions:(OCMConstraintOptions)options
{

    self = [super initWithOptions:options];
    if(self.constraintOptions & OCMConstraintDoNotRetainStubArg)
        [NSException raise:NSInvalidArgumentException format:@"`OCMConstraintDoNotRetainStubArg` does not make sense for `OCMAnyConstraint`."];
    return self;
}
- (BOOL)evaluate:(id)value
{
    return YES;
}

@end


#pragma mark -

@implementation OCMEqualityConstraint

- (instancetype)initWithTestValue:(id)aTestValue options:(OCMConstraintOptions)options
{
    if((self = [super initWithOptions:options]))
    {
        if(self.constraintOptions & OCMConstraintDoNotRetainStubArg)
        {
            testValue = aTestValue;
        }
        else
        {
            testValue = [aTestValue retain];
        }
    }
    return self;
}

- (void)dealloc
{
    if(!(self.constraintOptions & OCMConstraintDoNotRetainStubArg))
    {
        [testValue release];
    }
    [super dealloc];
}

@end

#pragma mark  -

@implementation OCMIsEqualConstraint

- (BOOL)evaluate:(id)value
{
    // Note that ordering of `[testValue isEqual:value]` is intentional as we want `testValue`
    // to control what equality means in this case. `value` may not even support equality.
    return value == testValue || [testValue isEqual:value];
}

@end

#pragma mark  -

@implementation OCMIsNotEqualConstraint

- (BOOL)evaluate:(id)value
{
    // Note that ordering of `[testValue isEqual:value]` is intentional as we want `testValue`
    // to control what inequality means in this case. `value` may not even support equality.
    return value != testValue && ![testValue isEqual: value];
}

@end


#pragma mark -

@implementation OCMInvocationConstraint

- (instancetype)initWithInvocation:(NSInvocation *)anInvocation options:(OCMConstraintOptions)options
{
  if((self = [super initWithOptions:options]))
  {
      NSMethodSignature *signature = [anInvocation methodSignature];
      if([signature numberOfArguments] < 3)
      {
          [NSException raise:NSInvalidArgumentException format:@"invocation must take at least one argument (other than _cmd and self)"];
      }
      if(!(OCMIsObjectType([signature getArgumentTypeAtIndex:2])))
      {
          [NSException raise:NSInvalidArgumentException format:@"invocation's second argument must be an object type"];
      }
      if(strcmp([signature methodReturnType], @encode(BOOL)))
      {
          [NSException raise:NSInvalidArgumentException format:@"invocation must return BOOL"];
      }
      if (self.constraintOptions & OCMConstraintDoNotRetainStubArg)
      {
          [NSException raise:NSInvalidArgumentException format:@"`OCMConstraintDoNotRetainStubArg` does not make sense for `OCMInvocationConstraint`."];
      }
      invocation = [anInvocation retain];
    }
    return self;
}

- (void)dealloc
{
    [invocation release];
    [super dealloc];
}

- (BOOL)evaluate:(id)value
{
    [invocation setArgument:&value atIndex:2];
    [invocation invoke];
    BOOL returnValue;
    [invocation getReturnValue:&returnValue];
    return returnValue;
}

@end

#pragma mark -

@implementation OCMBlockConstraint

- (instancetype)initWithOptions:(OCMConstraintOptions)options block:(BOOL (^)(id))aBlock;
{

    if((self = [super initWithOptions:options]))
    {
        if(self.constraintOptions & OCMConstraintDoNotRetainStubArg)
        {
            [NSException raise:NSInvalidArgumentException format:@"`OCMConstraintDoNotRetainStubArg` does not make sense for `OCMBlockConstraint`."];
        }
        block = [aBlock copy];
    }

    return self;
}

- (void)dealloc
{
    [block release];
    [super dealloc];
}

- (BOOL)evaluate:(id)value
{
    return block ? block(value) : NO;
}


@end
