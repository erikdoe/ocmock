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

    /// @todo
    /// - Handle blocks that take an NSNumber param. At the moment, this will
    ///   be interprated as a boxed number and extracted (I think)
    /// - Compare parameters with type signatures correctly while building the
    ///   invocation. That way, if a user passes an array of args that don't
    ///   match the block's, then we can tell them upfront
    
    /// @note Unlike normal method signatures, args at index 0 and 1 aren't
    /// reserved for `self` and `_cmd`. The arg at index 0 is reserved for the
    /// block itself, though: (`'@?'`).
    NSAssert(
        _params.count + 1 == _sig.numberOfArguments,
        @"All block arguments are require (%lu). Pass NSNull for default.",
        (unsigned long)_sig.numberOfArguments - 1
    );
    
    _inv = [NSInvocation invocationWithMethodSignature:_sig];
    void *buf;
    
    for (NSUInteger i = 0, j = 1; i < _params.count; ++i, ++j) {
        id param = _params[i];
        if ([param isKindOfClass:[NSNull class]]) {
            continue;
        }
        char const *typeEncoding = [_sig getArgumentTypeAtIndex:j];
        if (typeEncoding[0] == '@') {
            [_inv setArgument:&param atIndex:j];
        } else {
            char const *valEncoding = [param objCType];
            BOOL isVoidPtr = typeEncoding[0] == '^' && !strcmp(valEncoding, "^v");
            BOOL typesEq = isVoidPtr || !strcmp(typeEncoding, valEncoding);
            NSAssert(typesEq, @"Param type mismatch! You gave %@, block requires %@",
                [NSString stringWithUTF8String:valEncoding],
                [NSString stringWithUTF8String:typeEncoding]
            );
            NSUInteger argSize;
            NSGetSizeAndAlignment(typeEncoding, &argSize, NULL);
            buf = reallocf(buf, argSize);
            NSAssert(buf, @"Allocation failed arg at %lu", (long unsigned)i);
            [param getValue:buf];
            [_inv setArgument:buf atIndex:j];
        }
    }
    
    if (buf) {
        free(buf);
    }
}

- (void)handleArgument:(id)arg {
    [self buildInvocationFromBlock:arg];
    [_inv invokeWithTarget:arg];
}

@end