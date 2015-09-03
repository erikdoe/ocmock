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
    
    NSLog(@"Block signature: %@", _sig.fullTypeString);

    /// @todo
    /// - Handle blocks that take an NSNumber param. At the moment, this will
    ///   be interprated as a boxed number and extracted (I think)
    /// - Compare parameters with type signatures correctly while building the
    ///   invocation. That way, if a user passes an array of args that don't
    ///   match the block's, then we can tell them upfront
    /// - Handle NULL, nil and 0 passed by the user. At the moment, our handling
    ///   of va_list treats them as terminal.
    
    /// @note Why + 1?
    ///
    //NSAssert(_params.count + 1 == _sig.numberOfArguments, @"Params specified don't match: %lu, %lu", (unsigned long)_params.count, (unsigned long)_sig.numberOfArguments);
    _inv = [NSInvocation invocationWithMethodSignature:_sig];
    
    for (NSUInteger i = 0, j = 1; i < _params.count; ++i, ++j) {
        id param = _params[i];
        if ([param isKindOfClass:[NSValue class]]) {
            char const *typeEncoding = [_sig getArgumentTypeAtIndex:j];
            NSLog(@"Found NSValue of type %@", [NSString stringWithUTF8String:typeEncoding]);
            NSUInteger argSize;
            NSGetSizeAndAlignment(typeEncoding, &argSize, NULL);
            /// @todo Use reallocf
            void *buf = malloc(argSize);
            [param getValue:buf];
            if (!buf) {
                NSAssert(@"Allocation failed for arg of type %@", [NSString stringWithUTF8String:typeEncoding]);
            }
            [_inv setArgument:buf atIndex:j];
            NSLog(@"Setting value at %lu", (unsigned long)j);
            free(buf);
        } else {
            [_inv setArgument:&param atIndex:j];
            NSLog(@"Found other");
        }
    }
    
}

- (void)handleArgument:(id)arg {
    [self buildInvocationFromBlock:arg];
    [_inv invokeWithTarget:arg];
}

@end