//
//  OCChainTampolineProxy.h
//  OCMock
//
//  Created by jc on 25/09/2012.
//  Copyright (c) 2012 Mulle Kybernetik. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCChainTampolineProxy : NSProxy

+ (OCChainTampolineProxy*) placeholderReturningObject:(id) object
                                               forSelector:(SEL)sel;
+ (OCChainTampolineProxy*) placeholderReturningObject:(id) object
                                          forSelectorNamed:(NSString*)selName;

- (id) init;
- (id) initWithObject:(id) object forSelector:(SEL) sel;
- (id) initWithObject:(id) object forSelectorNamed:(NSString*) selName;

- (void) setObject:(id) object forSelector:(SEL) sel;
- (void) setObject:(id) object forSelectorNamed:(NSString*) selName;

- (id) objectForSelector:(SEL) sel;
- (id) objectForSelectorNamed:(NSString*) sel;

@end
