/*
 *  Copyright (c) 2010-2021 Erik Doernenburg and contributors
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

#import "OCMBlockCaller.h"
#import "NSMethodSignature+OCMAdditions.h"
#import "OCMFunctionsPrivate.h"
#import "NSInvocation+OCMAdditions.h"

@implementation OCMBlockCaller

-(id)initWithCallBlock:(id)theBlock
{
    if((self = [super init]))
    {
        block = [theBlock copy];
    }

    return self;
}

- (void)dealloc
{
    [block release];
    [super dealloc];
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
    if(!block)
    {
        return;
    }
    NSMethodSignature *blockMethodSignature = [NSMethodSignature signatureForBlock:block];
    NSUInteger blockNumberOfArguments = [blockMethodSignature numberOfArguments];
    if(blockNumberOfArguments == 2 && strcmp([blockMethodSignature getArgumentTypeAtIndex:1], "@\"NSInvocation\"") == 0)
    {
        // This is the deprecated ^(NSInvocation *) {} case.
        if([blockMethodSignature methodReturnLength] != 0)
        {
            [NSException raise:NSInvalidArgumentException format:@"NSInvocation style `andDo:` block for `-%@` cannot have return value.", NSStringFromSelector([anInvocation selector])];
        }

        void (^theBlock)(NSInvocation *) = block;
        theBlock(anInvocation);
        NSLog(@"Warning: Replace `^(NSInvocation *invocation) { ... }` with `%@`.", OCMBlockDeclarationForInvocation(anInvocation));
        return;
    }

    // This handles both the ^{} case and the ^(SelfType *a, Arg1Type b, ...) case.
    NSMethodSignature *invocationMethodSignature = [anInvocation methodSignature];
    NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:blockMethodSignature];
    NSUInteger invocationNumberOfArguments = [invocationMethodSignature numberOfArguments];
    if(blockNumberOfArguments != 1 && blockNumberOfArguments != invocationNumberOfArguments)
    {
        [NSException raise:NSInvalidArgumentException format:@"Block style `andDo:` block signature has wrong number of arguments. %d vs %d", (int)invocationNumberOfArguments, (int)blockNumberOfArguments];
    }
    id target = [anInvocation target];

    // In the ^{} case, blockNumberOfArguments will be 1, so we will just skip the whole for block.
    for(NSUInteger argIndex = 1; argIndex < blockNumberOfArguments; ++argIndex)
    {
        // Set arg1 to be "localSelf".
        // Note that in a standard NSInvocation this would be SEL, but blocks don't have SEL args.
        if(argIndex == 1)
        {
            [blockInvocation setArgument:&target atIndex:1];
            continue;
        }
        const char *blockArgType = [blockMethodSignature getArgumentTypeAtIndex:argIndex];
        const char *invocationArgType = [invocationMethodSignature getArgumentTypeAtIndex:argIndex];
        NSUInteger argSize;
        NSGetSizeAndAlignment(blockArgType, &argSize, NULL);
        NSMutableData *argSpace = [NSMutableData dataWithLength:argSize];
        void *argBytes = [argSpace mutableBytes];
        [anInvocation getArgument:argBytes atIndex:argIndex];
        if(!OCMIsObjCTypeCompatibleWithValueType(invocationArgType, blockArgType, argBytes, argSize) && !OCMEqualTypesAllowingOpaqueStructs(blockArgType, invocationArgType))
        {
            [NSException raise:NSInvalidArgumentException format:@"Block style `andDo:` block signature does not match selector signature. Arg %d is `%@` vs `%@`.", (int)argIndex, OCMObjCTypeForArgumentType(blockArgType), OCMObjCTypeForArgumentType(invocationArgType)];
        }
        [blockInvocation setArgument:argBytes atIndex:argIndex];
    }
    [blockInvocation invokeWithTarget:block];
    NSUInteger blockReturnLength = [blockMethodSignature methodReturnLength];
    if(blockReturnLength > 0)
    {
      // If there is a return value, make sure that it matches the expected return type.
      const char *blockReturnType = [blockMethodSignature methodReturnType];
      NSUInteger invocationReturnLength = [invocationMethodSignature methodReturnLength];
      const char *invocationReturnType = [invocationMethodSignature methodReturnType];
      if(invocationReturnLength != blockReturnLength)
      {
          [NSException raise:NSInvalidArgumentException format:@"Block style `andDo:` block signature does not match selector signature. Return type is `%@` vs `%@`.", OCMObjCTypeForArgumentType(blockReturnType), OCMObjCTypeForArgumentType(invocationReturnType)];
      }
      NSMutableData *argSpace = [NSMutableData dataWithLength:invocationReturnLength];
      void *argBytes = [argSpace mutableBytes];
      [blockInvocation getReturnValue:argBytes];
      if(!OCMIsObjCTypeCompatibleWithValueType(invocationReturnType, blockReturnType, argBytes, invocationReturnLength) && !OCMEqualTypesAllowingOpaqueStructs(blockReturnType, invocationReturnType))
      {
          [NSException raise:NSInvalidArgumentException format:@"Block style `andDo:` block signature does not match selector signature. Return type is `%@` vs `%@`.", OCMObjCTypeForArgumentType(blockReturnType), OCMObjCTypeForArgumentType(invocationReturnType)];
      }
      [anInvocation setReturnValue:argBytes];
    }
}

@end
