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


@implementation OCMBlockArgCaller {
    NSMethodSignature *_sig;
    NSInvocation *_inv;
}

- (instancetype)initWithBlockParams:(NSArray *)params {
    self = [super init];
    if (self) {
        _params = params;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [self retain];
}

- (void)buildInvocationFromBlock:(id)block {
    
    NSParameterAssert(block != nil);
    _sig = [NSMethodSignature signatureForBlock:block];
    NSAssert(_params.count == _sig.numberOfArguments, @"Params specified don't match ");
    _inv = [NSInvocation invocationWithMethodSignature:_sig];
    
    for (NSUInteger i = 0; i < _sig.numberOfArguments; i++) {
        id param = _params[i];
        if ([param isMemberOfClass:[NSValue class]]) {
            char const *typeEncoding = [_sig getArgumentTypeAtIndex:i];
            NSUInteger argSize;
            NSGetSizeAndAlignment(typeEncoding, &argSize, NULL);
            void *buf = malloc(argSize);
            if (!buf) {
                NSAssert(@"Allocation failed for arg of type %@", [NSString stringWithUTF8String:typeEncoding]);
            }
            [_inv setArgument:buf atIndex:0];
            free(buf);
        } else {
            [_inv setArgument:&param atIndex:0];
        }
    }
    
}

- (void)handleArgument:(id)arg {
    [self buildInvocationFromBlock:arg];
    [_inv invokeWithTarget:arg];
}

@end