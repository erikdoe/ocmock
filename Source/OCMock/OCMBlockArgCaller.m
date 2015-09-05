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
#import "OCMFunctions.h"

@implementation OCMBlockArgCaller {
    NSInvocation *_inv;
    NSArray *_params;
}

/// @note Q: Why don't we pass the va_list to this class and extract the vargs
/// of various types based on the NSMethodSignature specification?
/// A: On the surface, it looks like that solution might allow us to avoid boxing
/// the block args, however in reality its a bit trickier.
/// We would be relying on the method signature in determining what type to pass
/// to va_arg. There would be no way of telling what type we're extracting and thus
/// no way of asserting whether the user has passed the correct type in the
/// va_list. Its a ultimately a bit safer to box them up and pass them around in
/// an NSArray.

- (instancetype)initWithBlockParams:(NSArray *)params {
    self = [super init];
    if (self) {
        _params = [params copy];
    }
    return self;
}

- (void)dealloc {
    [_inv release];
    [_params release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self retain];
}

- (void)buildInvocationFromBlock:(id)block {
    
    NSMethodSignature *sig = [NSMethodSignature signatureForBlock:block];
    _inv = [NSInvocation invocationWithMethodSignature:sig];

    if (!_params) {
        return;
    }
    
    /// @note Unlike normal method signatures, args at index 0 and 1 aren't
    /// reserved for `self` and `_cmd`. The arg at index 0 is reserved for the
    /// block itself, though: (`'@?'`).
    NSAssert(
        _params.count + 1 == sig.numberOfArguments,
        @"All block arguments are require (%lu). Pass NSNull for default.",
        (unsigned long)sig.numberOfArguments - 1
    );
    void *buf = NULL;
    
    for (NSUInteger i = 0, j = 1; i < _params.count; ++i, ++j) {
        id param = _params[i];
        if ([param isKindOfClass:[NSNull class]]) {
            continue;
        }
        char const *typeEncoding = [sig getArgumentTypeAtIndex:j];
        /// @note OCMIsObjectType returns false for some reason, reverted to
        /// comparing first char to '@'.
        if (typeEncoding[0] == '@') {
            [_inv setArgument:&param atIndex:j];
        } else {
            char const *valEncoding = [param objCType];
            /// @note Allow void pointers to be passed as pointers to concrete
            /// primitives
            BOOL isVoidPtr = typeEncoding[0] == '^' && !strcmp(valEncoding, "^v");
            BOOL typesEq = isVoidPtr || !strcmp(typeEncoding, valEncoding);
            NSAssert(typesEq, @"Param type mismatch! You gave %s, block requires %s", valEncoding, typeEncoding);
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
    if (arg) {
        [self buildInvocationFromBlock:arg];
        [_inv invokeWithTarget:arg];
    }
}

@end