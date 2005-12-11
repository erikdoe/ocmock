//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2005 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/Protocol.h>
#import "NSMethodSignature+Private.h"
#import "OCProtocolMockObject.h"


@implementation OCProtocolMockObject

//---------------------------------------------------------------------------------------
//  init and dealloc
//---------------------------------------------------------------------------------------

- (id)initWithProtocol:(Protocol *)aProtocol
{
	[super init];
	mockedProtocol = aProtocol;
	return self;
}


//---------------------------------------------------------------------------------------
// description override
//---------------------------------------------------------------------------------------

- (NSString *)description
{
	return [NSString stringWithFormat:@"OCMockObject<%s>", [mockedProtocol name]];
}


//---------------------------------------------------------------------------------------
//  proxy api
//---------------------------------------------------------------------------------------

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	struct objc_method_description *desc = [mockedProtocol descriptionForInstanceMethod:aSelector];
	if (desc == NULL)
	   return nil;
	return [NSMethodSignature signatureWithObjCTypes:desc->types];
}


@end
