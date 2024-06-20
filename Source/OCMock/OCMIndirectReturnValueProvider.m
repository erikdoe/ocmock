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

#import "OCMIndirectReturnValueProvider.h"


@implementation OCMIndirectReturnValueProvider

- (id)initWithProvider:(id)aProvider andSelector:(SEL)aSelector
{
    if((self = [super init]))
    {
        provider = [aProvider retain];
        selector = aSelector;
    }

    return self;
}

- (void)dealloc
{
    [provider release];
    [super dealloc];
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
    id originalTarget = [anInvocation target];
    SEL originalSelector = [anInvocation selector];

    [anInvocation setTarget:provider];
    [anInvocation setSelector:selector];
    [anInvocation invoke];

    [anInvocation setTarget:originalTarget];
    [anInvocation setSelector:originalSelector];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[%@ - %p]: Calls `%@` on `%@`", [self class], self, NSStringFromSelector(selector), provider];
}

@end
