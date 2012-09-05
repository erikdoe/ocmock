//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2008 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@protocol OCMFailureHandler;

@interface OCMockObject : NSProxy
{
	id <OCMFailureHandler> failureHandler;
	
	BOOL			isNice;
	BOOL			expectationOrderMatters;
	NSMutableArray	*recorders;
	NSMutableArray	*expectations;
	NSMutableArray	*rejections;
	NSMutableArray	*exceptions;
}

+ (id)mockForClass:(Class)aClass;
+ (id)mockForClassObject:(Class)aClass;
+ (id)mockForProtocol:(Protocol *)aProtocol;
+ (id)partialMockForObject:(NSObject *)anObject;

+ (id)niceMockForClass:(Class)aClass;
+ (id)niceMockForProtocol:(Protocol *)aProtocol;

+ (id)observerMock;

- (id)init;

- (void)setExpectationOrderMatters:(BOOL)flag;
- (void)setFailureHandler:(id <OCMFailureHandler>)handler; // handler is retained

- (id)stubInFile:(NSString *)filename atLine:(int)lineNumber;
- (id)expectInFile:(NSString *)filename atLine:(int)lineNumber;
- (id)rejectInFile:(NSString *)filename atLine:(int)lineNumber;

- (void)verify;

- (void)stopMocking;

// internal use only

- (id)getNewRecorder;
- (id)getNewRecorderInFile:(NSString *)filename atLine:(int)lineNumber;
- (BOOL)handleInvocation:(NSInvocation *)anInvocation;
- (void)handleUnRecordedInvocation:(NSInvocation *)anInvocation;

@end
