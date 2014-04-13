//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class OCMInvocationMatcher;


@interface OCMockRecorder : NSProxy
{
    id                   signatureResolver;
    OCMInvocationMatcher *invocationMatcher;
    NSMutableArray       *invocationHandlers;
}

- (id)initWithSignatureResolver:(id)anObject;

//- (void)releaseInvocation;

- (id)andReturn:(id)anObject;
- (id)andReturnValue:(NSValue *)aValue;
- (id)andThrow:(NSException *)anException;
- (id)andPost:(NSNotification *)aNotification;
- (id)andCall:(SEL)selector onObject:(id)anObject;
#if NS_BLOCKS_AVAILABLE
- (id)andDo:(void (^)(NSInvocation *))block; 
#endif
- (id)andForwardToRealObject;

- (id)classMethod;
- (id)ignoringNonObjectArgs;

- (OCMInvocationMatcher *)invocationMatcher;

- (void)addInvocationHandler:(id)aHandler;
- (NSArray *)invocationHandlers;

@end


@interface OCMockRecorder(Properties)

#define toReturn(anObject) _toReturn(anObject)
@property (nonatomic, readonly) OCMockRecorder *(^ _toReturn)(id);

#define toDo(aBlock) _toDo(aBlock)
@property (nonatomic, readonly) OCMockRecorder *(^ _toDo)(void (^)(NSInvocation *));

@end



