//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2005-2008 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCClassMockObject.h"


@implementation OCClassMockObject

//---------------------------------------------------------------------------------------
//  init and dealloc
//---------------------------------------------------------------------------------------

- (id)initWithClass:(Class)aClass
{
	[super init];
	mockedClass = aClass;
	return self;
}


//---------------------------------------------------------------------------------------
// description override
//---------------------------------------------------------------------------------------

- (NSString *)description
{
	return [NSString stringWithFormat:@"OCMockObject[%@]", NSStringFromClass(mockedClass)];
}


//---------------------------------------------------------------------------------------
//  proxy api
//---------------------------------------------------------------------------------------

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [mockedClass instanceMethodSignatureForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return [mockedClass instancesRespondToSelector:selector];
}

@end
