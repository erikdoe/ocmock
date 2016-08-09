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
#import "OCProtocolProxy.h"

@implementation OCProtocolMockObject
{
    NSArray *protocolProxies;
}

#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithProtocols:(NSArray *)protocols
{
	[super init];

    NSMutableArray *proxies = [NSMutableArray new];

    for(Protocol *aProtocol in protocols)
    {
        OCProtocolProxy *protocolProxy = [[OCProtocolProxy alloc] initWithProtocol:aProtocol];
        [proxies addObject:protocolProxy];
        [protocolProxy release];
    }

	protocolProxies = proxies;

	return self;
}

- (void)dealloc
{
    [protocolProxies release];
    [super dealloc];
}

- (NSString *)description
{
    NSArray *protocolNames = [protocolProxies valueForKey:NSStringFromSelector(@selector(protocolName))];
    return [NSString stringWithFormat:@"OCMockObject(%@)", [protocolNames componentsJoinedByString:@", "]];
}

#pragma mark  Proxy API

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    for(OCProtocolProxy *protocolProxy in protocolProxies)
    {
        NSMethodSignature *signature = [protocolProxy methodSignatureForSelector:aSelector];

        if(signature)
        {
            return signature;
        }
    }
    return nil;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    for(OCProtocolProxy *protocolProxy in protocolProxies)
    {
        if([protocolProxy conformsToProtocol:aProtocol])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return ([self methodSignatureForSelector:selector] != nil);
}

@end
