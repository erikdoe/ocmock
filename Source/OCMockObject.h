//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMockObject : NSProxy 
{
	Class			mockedClass;
	NSMutableArray	*recordedInvocations;
	NSMutableSet	*expectedInvocations;
}

+ (id)mockForClass:(Class)aClass;

- (id)initWithClass:(Class)aClass;

- (id)stub;
- (id)expect;

- (void)verify;

@end
