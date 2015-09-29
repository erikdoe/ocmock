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
#import "OCMFunctionsPrivate.h"

@implementation OCMBlockArgCaller

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
    
    NSUInteger argsLen = sig.numberOfArguments - 1;
    void *buf = NULL;
    
    /// @note Either allow all args or no args (all default) to avoid users
    /// passing mismatching arguments.
    NSAssert(
             params.count == argsLen || params == nil,
             @"All block arguments are required (%lu). Pass [OCMArg defaultValue] for default value.",
             (unsigned long)argsLen
             );

    for(NSUInteger i = 0, j = 1; i < argsLen; ++i, ++j)
    {
        id param = [params objectAtIndex:i];
        char const *typeEncoding = [sig getArgumentTypeAtIndex:j];
        
        if(!param || [param isKindOfClass:[NSNull class]])
        {
            void *pDef;
        
            /// @note Provide nil, NULL and 0 as defaults where possible. Any other
            /// types raise an exception and its up to the user to provider their own
            /// default.
            if(typeEncoding[0] == '^')
            {
                void *nullPtr = NULL;
                pDef = &nullPtr;
            }
            else if(typeEncoding[0] == '@')
            {
                id nilObj =  nil;
                pDef = &nilObj;
            }
            else if(OCMNumberTypeForObjCType(typeEncoding))
            {
                NSUInteger zero = 0;
                pDef = &zero;
            }
            else
            {
                [NSException raise:NSInvalidArgumentException format:@"Could not default type %s", typeEncoding];
            }

            [inv setArgument:pDef atIndex:j];
            
        }
        else if (typeEncoding[0] == '@')
        {
            [inv setArgument:&param atIndex:j];
        }
        else
        {
            NSAssert([param isKindOfClass:[NSValue class]], @"Argument at %lu should be boxed in NSValue", (long unsigned)i);
            
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
            NSAssert(buf, @"Allocation failed for arg at %lu", (long unsigned)i);
            
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
