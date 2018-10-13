/*
 *  Copyright (c) 2014-2016 Erik Doernenburg and contributors
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
#import "OCMVerifier.h"
#import "OCMockObject.h"
#import "OCMLocation.h"
#import "OCMInvocationMatcher.h"


@implementation OCMVerifier

- (id)init
{
    if ((self = [super init]))
    {
        invocationMatcher = [[OCMInvocationMatcher alloc] init];
        _success = YES;
    }
    
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [super forwardInvocation:anInvocation];
    self.success = [mockObject verifyInvocation:invocationMatcher atLocation:self.location failWithException:self.failWithException];
}

- (void)dealloc
{
	[_location release];
	[super dealloc];
}

@end
