//---------------------------------------------------------------------------------------
//  $Id: MKConsoleWindow.h,v 1.4 2004/02/15 18:55:05 erik Exp $
//  Copyright (c) 2004 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMockObject : NSObject 
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
