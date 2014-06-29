/*
 *  Copyright (c) 2014 Erik Doernenburg and contributors
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

#import "OCMVerifyMacroState.h"
#import "OCMInvocationMatcher.h"
#import "OCMLocation.h"
#import "OCMockObject.h"
#import "OCMVerifier.h"


@implementation OCMVerifyMacroState

- (id)initWithLocation:(OCMLocation *)aLocation
{
    self = [super init];
    location = aLocation;
    return self;
}

- (void)switchToClassMethod
{
    shouldVerifyClassMethod = YES;
}

- (BOOL)hasSwitchedToClassMethod
{
    return shouldVerifyClassMethod;
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
    OCMockObject *mock = [anInvocation target];
    OCMVerifier *verifier = [[[OCMVerifier alloc] initWithMockObject:mock] autorelease];
    [verifier setLocation:location];
    if(shouldVerifyClassMethod)
        [verifier classMethod];
    [verifier forwardInvocation:anInvocation];
}

@end
