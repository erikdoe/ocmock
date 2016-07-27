/*
 *  Copyright (c) 2005-2016 Erik Doernenburg and contributors
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
#import "NSMethodSignature+OCMAdditions.h"
#import "OCProtocolMockObject.h"

@implementation OCProtocolMockObject

#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithProtocol:(Protocol *)aProtocol
{
    NSParameterAssert(aProtocol != nil);
	[super init];
	mockedProtocols = @[aProtocol];
	return self;
}

- (id)initWithProtocols:(NSArray<Protocol *> *)protocols
{
    NSParameterAssert(protocols != nil);
    [super init];
    mockedProtocols = protocols;
    return self;
}

- (NSString *)description
{
    char* names = (char*)protocol_getName(mockedProtocols[0]);
    for(NSUInteger ix = 1; ix < mockedProtocols.count; ix++)
    {
        asprintf(&names, "%s, %s", names, protocol_getName(mockedProtocols[ix]));
    }
    return [NSString stringWithFormat:@"OCMockObject(%s)", names];
}

#pragma mark  Proxy API

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    struct { BOOL isRequired; BOOL isInstance; } opts[4] = { {YES, YES}, {NO, YES}, {YES, NO}, {NO, NO} };
    for(Protocol *aProtocol in mockedProtocols)
    {
        for(int i = 0; i < 4; i++)
        {
            struct objc_method_description methodDescription = protocol_getMethodDescription(aProtocol, aSelector, opts[i].isRequired, opts[i].isInstance);
            if(methodDescription.name != NULL)
                return [NSMethodSignature signatureWithObjCTypes:methodDescription.types];
        }
    }
    return nil;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    BOOL conformsToProtocol = NO;
    for(Protocol *procotol in mockedProtocols)
    {
        conformsToProtocol = protocol_conformsToProtocol(procotol, aProtocol);
        if(conformsToProtocol)
            break;
    }
    return conformsToProtocol;
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return ([self methodSignatureForSelector:selector] != nil);
}

@end
