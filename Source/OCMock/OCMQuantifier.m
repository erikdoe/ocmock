/*
 *  Copyright (c) 2016 Erik Doernenburg and contributors
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

#import <Foundation/Foundation.h>
#import "OCMMacroState.h"
#import "OCMVerifier.h"
#import "OCMQuantifier.h"

@interface OCMAtLeastQuantifier : OCMQuantifier

@property NSUInteger count;

@end

@interface OCMAtMostQuantifier : OCMQuantifier

@property NSUInteger count;

@end



@implementation OCMQuantifier

+ (instancetype)atLeastOnce
{
    return [self atLeast:1];
}

+ (instancetype)atLeast:(NSUInteger)count
{
    OCMAtLeastQuantifier *quantifier = [[[OCMAtLeastQuantifier alloc] init] autorelease];
    quantifier.count = count;
    return quantifier;
}


+ (instancetype)never
{
    return [self atMost:0];
}

+ (instancetype)atMost:(NSUInteger)count
{
    OCMAtMostQuantifier *quantifier = [[[OCMAtMostQuantifier alloc] init] autorelease];
    quantifier.count = count;
    return quantifier;
}


- (instancetype)init
{
    if((self = [super init]) != nil)
    {
        [(OCMVerifier *)[[OCMMacroState globalState] recorder] setQuantifier:self];
    }
    return self;
}


- (BOOL)isValidCount:(NSUInteger)count
{
    return NO;
}

- (NSString *)description
{
    [NSException raise:NSInternalInconsistencyException format:@"Subclass should have implemented method description."];
    return nil; // keep compiler happy
}

@end


@implementation OCMAtLeastQuantifier

- (BOOL)isValidCount:(NSUInteger)count
{
    return count >= self.count;
}

- (NSString *)description
{
    return (self.count == 1) ? @"at least once" : [NSString stringWithFormat:@"at least %ld times", self.count];
}

@end


@implementation OCMAtMostQuantifier

- (BOOL)isValidCount:(NSUInteger)count
{
    return count <= self.count;
}

- (NSString *)description
{
    switch(self.count)
    {
        case 0:  return @"never";
        case 1:  return @"at most once";
        default: return [NSString stringWithFormat:@"at most %ld times", self.count];
    }
}

@end

