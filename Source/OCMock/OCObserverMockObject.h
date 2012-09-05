//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@protocol OCMFailureHandler;

@interface OCObserverMockObject : NSObject 
{
	id <OCMFailureHandler> failureHandler;
	
	BOOL			expectationOrderMatters;
	NSMutableArray	*recorders;
}

- (void)setExpectationOrderMatters:(BOOL)flag;
- (void)setFailureHandler:(id <OCMFailureHandler>)handler; // handler is retained

- (id)expectInFile:(NSString *)filename atLine:(int)lineNumber;

- (void)verify;

- (void)handleNotification:(NSNotification *)aNotification;

@end
