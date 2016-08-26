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
#import "OCProtocolsProxy.h"

@interface OCProtocolProxy : NSObject

- (id)initWithProtocol:(Protocol *)aProtocol;

- (NSString *)protocolName;

@end

@implementation OCProtocolProxy
{
    Protocol *mockedProtocol;
}

#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithProtocol:(Protocol *)aProtocol
{
    NSParameterAssert(aProtocol != nil);
    self = [super init];
    if(self)
    {
        mockedProtocol = aProtocol;
    }

    return self;
}

- (NSString *)protocolName
{
    const char* name = protocol_getName(mockedProtocol);
    return [NSString stringWithUTF8String:name];
}

#pragma mark  Proxy API

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    struct { BOOL isRequired; BOOL isInstance; } opts[4] = { {YES, YES}, {NO, YES}, {YES, NO}, {NO, NO} };
    for(int i = 0; i < 4; i++)
    {
        struct objc_method_description methodDescription = protocol_getMethodDescription(mockedProtocol, aSelector, opts[i].isRequired, opts[i].isInstance);
        if(methodDescription.name != NULL)
            return [NSMethodSignature signatureWithObjCTypes:methodDescription.types];
    }
    return nil;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return protocol_conformsToProtocol(mockedProtocol, aProtocol);
}

@end


@implementation OCProtocolsProxy
{
    NSArray *protocolProxies;
}

- (instancetype)initWithProtocols:(NSArray *)protocols
{
    self = [super init];

    if (self && protocols)
    {
        NSMutableArray *proxies = [NSMutableArray new];

        for(Protocol *aProtocol in protocols)
        {
            OCProtocolProxy *protocolProxy = [[OCProtocolProxy alloc] initWithProtocol:aProtocol];
            [proxies addObject:protocolProxy];
            [protocolProxy release];
        }

        protocolProxies = proxies;
    }
    return self;
}

- (void)dealloc
{
    [protocolProxies release];
    [super dealloc];
}

- (NSArray *)protocolNames
{
    return [protocolProxies valueForKey:NSStringFromSelector(@selector(protocolName))];
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
