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
- (id)andDo:(void (^)(NSInvocation *))block;
- (id)andForwardToRealObject;

- (id)classMethod;
- (id)ignoringNonObjectArgs;

- (OCMInvocationMatcher *)invocationMatcher;

- (void)addInvocationHandler:(id)aHandler;
- (NSArray *)invocationHandlers;

@end


@interface OCMockRecorder(Properties)

#define andReturn(anObject) _andReturn(anObject)
@property (nonatomic, readonly) OCMockRecorder *(^ _andReturn)(id);

#define andThrow(anException) _andThrow(anException)
@property (nonatomic, readonly) OCMockRecorder *(^ _andThrow)(NSException *);

#define andPost(aNotification) _andPost(aNotification)
@property (nonatomic, readonly) OCMockRecorder *(^ _andPost)(NSNotification *);

#define andCall(anObject, aSelector) _andCall(anObject, aSelector)
@property (nonatomic, readonly) OCMockRecorder *(^ _andCall)(id, SEL);

#define andDo(aBlock) _andDo(aBlock)
@property (nonatomic, readonly) OCMockRecorder *(^ _andDo)(void (^)(NSInvocation *));

#define andForwardToRealObject() _andForwardToRealObject()
@property (nonatomic, readonly) OCMockRecorder *(^ _andForwardToRealObject)(void);

@end



