//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004,2005 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>


@interface OCMockObject : NSProxy 
{
	NSMutableArray	*recorders;
	NSMutableSet	*expectations;
}

+ (id)mockForClass:(Class)aClass;
+ (id)mockForProtocol:(Protocol *)aProtocol;

- (id)init;

- (id)stub;
- (id)expect;

- (void)verify;

@end
