/*
 *  Copyright (c) 2010-2016 Erik Doernenburg and contributors
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

#import "OCMBlockWithArgsCaller.h"

#import <objc/runtime.h>

@implementation OCMBlockWithArgsCaller
{
    id block;
    id provider;
}

- (id)initWithProvider:(id)aProvider callBlock:(id)theBlock
{
    if ((self = [super init]))
    {
        block = [theBlock copy];
        provider = [aProvider retain];
    }
    
    return self;
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
    Class class = [provider class];
    
    SEL selector = anInvocation.selector;
    
    Method method = class_getInstanceMethod([anInvocation.target class], selector);
    IMP originalImplementation = class_getMethodImplementation(class, selector);
    IMP implementation = imp_implementationWithBlock(block);
  
    class_replaceMethod(class, selector, implementation, method_getTypeEncoding(method));

    id originalTarget = anInvocation.target;
    
    anInvocation.target = provider;
    [anInvocation invoke];
    
    anInvocation.target = originalTarget;

    class_replaceMethod(class, selector, originalImplementation, method_getTypeEncoding(method));
    
}

@end
