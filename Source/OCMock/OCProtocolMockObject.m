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
#import "OCProtocolsProxy.h"

@implementation OCProtocolMockObject
{
    OCProtocolsProxy *protocolsProxy;
}

#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithProtocols:(NSArray *)protocols
{
    NSCParameterAssert(protocols != nil);

	[super init];

	protocolsProxy = [[OCProtocolsProxy alloc] initWithProtocols:protocols];

	return self;
}

- (void)dealloc
{
    [protocolsProxy release];
    [super dealloc];
}

- (NSString *)description
{
    NSArray *protocolNames = [protocolsProxy protocolNames];
    return [NSString stringWithFormat:@"OCMockObject(%@)", [protocolNames componentsJoinedByString:@", "]];
}

#pragma mark  Proxy API

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [protocolsProxy methodSignatureForSelector:aSelector];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return [protocolsProxy conformsToProtocol:aProtocol];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return [protocolsProxy respondsToSelector:selector];
}

@end
