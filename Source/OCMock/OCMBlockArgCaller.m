/*
 *  Copyright (c) 2015 Erik Doernenburg and contributors
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

#import "OCMBlockArgCaller.h"
#import "NSMethodSignature+OCMAdditions.h"
#import "OCMFunctions.h"

@implementation OCMBlockArgCaller
{
    NSArray *params;
}

- (instancetype)initWithBlockParams:(NSArray *)blockParams
{
    self = [super init];
    if(self)
    {
        params = [blockParams copy];
    }
    return self;
}

- (void)dealloc
{
    [params release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (NSInvocation *)buildInvocationFromBlock:(id)block
{
    
    NSMethodSignature *sig = [NSMethodSignature signatureForBlock:block];
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];

    if(!params)
    {
        return inv;
    }
    
    /// @note Unlike normal method signatures, args at index 0 and 1 aren't
    /// reserved for `self` and `cmd`. The arg at index 0 is reserved for the
    /// block itself, though: (`'@?'`).
    NSAssert(
        params.count + 1 == sig.numberOfArguments,
        @"All block arguments are require (%lu). Pass NSNull for default.",
        (unsigned long)sig.numberOfArguments - 1
    );
    void *buf = NULL;
    
    for(NSUInteger i = 0, j = 1; i < params.count; ++i, ++j)
    {
        id param = params[i];
        if([param isKindOfClass:[NSNull class]])
        {
            continue;
        }
        char const *typeEncoding = [sig getArgumentTypeAtIndex:j];
        if(typeEncoding[0] == '@')
        {
            [inv setArgument:&param atIndex:j];
        }
        else
        {
            NSAssert([param isKindOfClass:[NSValue class]], @"Param at %lu should be boxed in NSValue", (long unsigned)i);
            char const *valEncoding = [param objCType];
            /// @note Here we allow any data pointer to be passed as a void pointer and
            /// any numberical types to be passed as arguments to the block.
            BOOL takesVoidPtr = !strcmp(typeEncoding, "^v") && valEncoding[0] == '^';
            BOOL takesNumber = OCMNumberTypeForObjCType(typeEncoding) && OCMNumberTypeForObjCType(valEncoding);
            NSAssert(
                takesVoidPtr || takesNumber || OCMEqualTypesAllowingOpaqueStructs(typeEncoding, valEncoding),
                @"Param type mismatch! You gave %s, block requires %s",
                valEncoding, typeEncoding
            );
            NSUInteger argSize;
            NSGetSizeAndAlignment(typeEncoding, &argSize, NULL);
            buf = reallocf(buf, argSize);
            NSAssert(buf, @"Allocation failed arg at %lu", (long unsigned)i);
            [param getValue:buf];
            [inv setArgument:buf atIndex:j];
        }
    }
    
    if(buf)
    {
        free(buf);
    }
    return inv;
}

- (void)handleArgument:(id)arg
{
    if(arg)
    {
        NSInvocation *inv = [self buildInvocationFromBlock:arg];
        [inv invokeWithTarget:arg];
    }
}

@end