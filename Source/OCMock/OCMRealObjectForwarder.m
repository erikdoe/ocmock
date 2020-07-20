/*
 *  Copyright (c) 2010-2020 Erik Doernenburg and contributors
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
#import "OCPartialMockObject.h"
#import "OCMRealObjectForwarder.h"
#import "OCMFunctionsPrivate.h"
#import "NSInvocation+OCMAdditions.h"


@implementation OCMRealObjectForwarder

- (void)handleInvocation:(NSInvocation *)anInvocation 
{
	id invocationTarget = [anInvocation target];

	BOOL isInInitFamily = [anInvocation methodIsInInitFamily];
	BOOL isInCreateFamily = isInInitFamily ? NO : [anInvocation methodIsInCreateFamily];
	[anInvocation setSelector:OCMAliasForOriginalSelector([anInvocation selector])];
	if ([invocationTarget isProxy])
	{
	    if (class_getInstanceMethod([invocationTarget mockObjectClass], @selector(realObject)))
	    {
	        // the method has been invoked on the mock, we need to change the target to the real object
	        [anInvocation setTarget:[(OCPartialMockObject *)invocationTarget realObject]];
	    }
	    else
	    {
	        [NSException raise:NSInternalInconsistencyException
	                    format:@"Method andForwardToRealObject can only be used with partial mocks and class methods."];
	    }
	}

	[anInvocation invoke];
	if(isInInitFamily || isInCreateFamily)
	{
	    // OCMInvocationStub does some post processing after all of the invocation actions are called
	    // to make sure that init family and create family calls are handled correctly with regards
	    // to retain/release. In the case where we are forwarded to a real object, the handling
	    // that the real object has already done needs to be "undone" so we don't over retain or under
	    // release.
	    id returnVal;
	    [anInvocation getReturnValue:&returnVal];
	    if (isInCreateFamily)
	    {
	        // methods that "create" an object will return it with an extra retain count
	        // autorelease it so that when OCMInvocationStub retains it that we balance.
	        [returnVal autorelease];
	    }
	    else if(isInInitFamily)
	    {
	        // init family methods "consume" self and retain their return value.
	        // Retain the target (that OCMInvocationStub will release) and autorelease the returnVal
	        // (that OCMInvocationStub will retain).
	        [[anInvocation target] retain];
	        [returnVal autorelease];
	    } else {
	        // avoid potential problems with the return value being release too early
	        [[returnVal retain] autorelease];
	    }
	}
}


@end
