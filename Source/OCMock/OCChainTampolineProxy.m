//
//  OCChainTampolineProxy.m
//  OCMock
//
//  Created by jc on 25/09/2012.
//  Copyright (c) 2012 Mulle Kybernetik. All rights reserved.
//

#import <OCMock/OCChainTampolineProxy.h>

@interface OCChainTampolineProxy ()
@property (strong) NSMutableDictionary *dictionary;
@end

@implementation OCChainTampolineProxy
@synthesize dictionary=_dictionary;

+ (OCChainTampolineProxy*) placeholderReturningObject:(id) object
                                               forSelector:(SEL)sel
{
    return [self placeholderReturningObject:object forSelectorNamed:NSStringFromSelector(sel)];
}

+ (OCChainTampolineProxy*) placeholderReturningObject:(id) object
                                          forSelectorNamed:(NSString*)selName
{
    return [[OCChainTampolineProxy alloc] initWithObject:object forSelectorNamed:selName];
}

- (id) initWithObject:(id) object forSelector:(SEL) sel
{
    return [self initWithObject:object forSelectorNamed:NSStringFromSelector(sel)];
}

- (id) initWithObject:(id) object forSelectorNamed:(NSString*) selName
{
    if ((self = [self init])) {
        [self setObject:object forSelectorNamed:selName];
    }
    return self;
}

- (id) init
{
    _dictionary = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)dealloc
{
    [_dictionary release];
    [super dealloc];
}

- (void) setObject:(id) object forSelector:(SEL) sel
{
    [self setObject:object forSelectorNamed:NSStringFromSelector(sel)];
}

- (void) setObject:(id) object forSelectorNamed:(NSString*) selName
{
    // should not already have an object to return for this selector
    NSParameterAssert(![self.dictionary objectForKey:selName]);
    [self.dictionary setValue:object forKey:selName];
}

- (id) objectForSelector:(SEL) sel
{
    return [self objectForSelectorNamed:NSStringFromSelector(sel)];
}

- (id) objectForSelectorNamed:(NSString*) sel
{
    id ret = [self.dictionary objectForKey:sel];
    NSAssert1(ret, @"No object for selector named %@", sel);
    return ret;
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"%@, %@", NSStringFromClass(self.class), self.dictionary];
}

#pragma mark Forwarding

- (NSMethodSignature*) methodSignatureForSelector:(SEL)sel
{
    NSAssert1([self.dictionary objectForKey:NSStringFromSelector(sel)],
              @"No object registered for selector %@", NSStringFromSelector(sel));
    return [NSMethodSignature signatureWithObjCTypes:"@@:"];
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
    id obj = [self objectForSelector:invocation.selector];
    [invocation setReturnValue:&obj];
}

@end
