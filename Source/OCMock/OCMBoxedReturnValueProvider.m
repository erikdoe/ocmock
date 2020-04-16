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

#import "OCMBoxedReturnValueProvider.h"
#import "OCMFunctionsPrivate.h"
#import "NSValue+OCMAdditions.h"

static BOOL IsZeroBuffer(const char* buffer, size_t length)
{
    for(size_t i = 0; i < length; ++i)
    {
        if(buffer[i] != 0)
        {
            return NO;
        }
    }
    return YES;
}

@implementation OCMBoxedReturnValueProvider

- (void)handleInvocation:(NSInvocation *)anInvocation
{
	const char *returnType = [[anInvocation methodSignature] methodReturnType];
    NSUInteger returnTypeSize = [[anInvocation methodSignature] methodReturnLength];
    char valueBuffer[returnTypeSize];
    NSValue *returnValueAsNSValue = (NSValue *)returnValue;
    [returnValueAsNSValue getValue:valueBuffer];

    if([self isMethodReturnType:returnType
        compatibleWithValueType:[returnValueAsNSValue objCType]
                          value:valueBuffer
                      valueSize:returnTypeSize])
    {
        [anInvocation setReturnValue:valueBuffer];
    }
    else if([returnValueAsNSValue getBytes:valueBuffer objCType:returnType])
    {
        [anInvocation setReturnValue:valueBuffer];
    }
    else
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Return value cannot be used for method; method signature declares '%s' but value is '%s'.", returnType, [returnValueAsNSValue objCType]];
    }
}

- (BOOL)isMethodReturnType:(const char *)returnType compatibleWithValueType:(const char *)valueType value:(const char*)value valueSize:(size_t)valueSize
{
    /* Same types are obviously compatible */
    if(strcmp(returnType, valueType) == 0)
        return YES;

    // Special casing for nil and Nil
    if(strcmp(returnType, @encode(id)) == 0 || strcmp(returnType, @encode(Class)) == 0)
    {
        // Check to verify that the value is actually zero.
        if(IsZeroBuffer(value, valueSize))
        {
            // nil and Nil get potentially different encodings depending on the compilation
            // settings of the file where the return value gets recorded. We check to verify
            // against all the values we know of.
            const char *validNilEncodings[] =
            {
                @encode(void *),    // Standard Obj C
                @encode(int),       // 32 bit C++ (before nullptr)
                @encode(long long), // 64 bit C++ (before nullptr)
                @encode(char *),    // C++ with nullptr
            };
            for(size_t i = 0; i < sizeof(validNilEncodings) / sizeof(validNilEncodings[0]); ++i)
            {
                if(strcmp(valueType, validNilEncodings[i]) == 0)
                {
                    return YES;
                }
            }
        }
    }

    return OCMEqualTypesAllowingOpaqueStructs(returnType, valueType);
}


@end
