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

#import "OCMBoxedReturnValueProvider.h"
#import "NSValue+OCMAdditions.h"
#import "NSMethodSignature+OCMAdditions.h"

@implementation OCMBoxedReturnValueProvider

- (void)handleInvocation:(NSInvocation *)anInvocation
{
    NSUInteger valueSize = 0;
    NSValue *returnValueAsNSValue = (NSValue *)returnValue;
    NSGetSizeAndAlignment([returnValueAsNSValue objCType], &valueSize, NULL);
    char valueBuffer[valueSize];
    [returnValueAsNSValue getValue:valueBuffer];
    NSMethodSignature *signature = [anInvocation methodSignature];
    const char *returnType = [signature methodReturnType];
    const char *returnValueType = [returnValueAsNSValue objCType];

    if([signature isMethodReturnTypeCompatibleWithValueType:returnValueType value:valueBuffer valueSize:valueSize])
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
                    format:@"Return value cannot be used for method; method signature declares '%s' but value is '%s'.", returnType, returnValueType];
    }
}

@end
