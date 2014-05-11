//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMInvocationMatcher : NSObject
{
    NSInvocation *recordedInvocation;
    BOOL         recordedAsClassMethod;
    BOOL         ignoreNonObjectArgs;
}

- (void)setInvocation:(NSInvocation *)anInvocation;

- (void)setRecordedAsClassMethod:(BOOL)flag;
- (BOOL)recordedAsClassMethod;

- (void)setIgnoreNonObjectArgs:(BOOL)flag;


- (BOOL)matchesSelector:(SEL)aSelector;
- (BOOL)matchesInvocation:(NSInvocation *)anInvocation;

@end
