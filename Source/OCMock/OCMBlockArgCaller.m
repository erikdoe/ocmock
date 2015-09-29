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
    if((params != nil) && ([params count] != argsLen))
        [NSException raise:NSInvalidArgumentException format:@"Specified too few arguments for block; expected (%lu) arguments.", (unsigned long)argsLen];

    for(NSUInteger i = 0, j = 1; i < argsLen; ++i, ++j)
    {
        id param = [params objectAtIndex:i];
        char const *typeEncoding = [sig getArgumentTypeAtIndex:j];
        
        if(!param || [param isKindOfClass:[NSNull class]])
        {
            if(typeEncoding[0] == '^')
            {
                void *nullPtr = NULL;
                [inv setArgument:&nullPtr atIndex:j];
            }
            else if(typeEncoding[0] == '@')
            {
                id nilObj =  nil;
                [inv setArgument:&nilObj atIndex:j];
            }
            else if(OCMNumberTypeForObjCType(typeEncoding))
            {
                NSUInteger zero = 0;
                [inv setArgument:&zero atIndex:j];
            }
            else
            {
                [NSException raise:NSInvalidArgumentException format:@"Could not default type %s. Must specify arguments for this block.", typeEncoding];
            }
        }
        else if (typeEncoding[0] == '@')
        {
            [inv setArgument:&param atIndex:j];
        }
        else
        {
            if(![param isKindOfClass:[NSValue class]])
                [NSException raise:NSInvalidArgumentException format:@"Argument at index %lu should be boxed in NSValue.", (long unsigned)i];
            
            char const *valEncoding = [param objCType];
            
            /// @note Here we allow any data pointer to be passed as a void pointer and
            /// any numberical types to be passed as arguments to the block.
            BOOL takesVoidPtr = !strcmp(typeEncoding, "^v") && valEncoding[0] == '^';
            BOOL takesNumber = OCMNumberTypeForObjCType(typeEncoding) && OCMNumberTypeForObjCType(valEncoding);
            
            if(!takesVoidPtr && !takesNumber && !OCMEqualTypesAllowingOpaqueStructs(typeEncoding, valEncoding))
                 [NSException raise:NSInvalidArgumentException format:@"Argument type mismatch; Block requires %s but argument provided is %s", typeEncoding, valEncoding];
            
            NSUInteger argSize;
            NSGetSizeAndAlignment(typeEncoding, &argSize, NULL);
            void *argBuffer = malloc(argSize);
            [param getValue:argBuffer];
            [inv setArgument:argBuffer atIndex:j];
            free(argBuffer);
        }
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
