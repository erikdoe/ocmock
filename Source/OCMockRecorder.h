//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMockRecorder : NSProxy 
{
	Class			mockedClass;
	id				returnValue;
	NSInvocation	*recordedInvocation;
}

+ (id)anyArgument;

- (id)initWithClass:(Class)aClass;

- (id)andReturn:(id)anObject;

- (BOOL)matchesInvocation:(NSInvocation *)anInvocation;
- (void)setUpReturnValue:(NSInvocation *)anInvocation;

@end


#define OCMOCK_ANY [OCMockRecorder anyArgument]