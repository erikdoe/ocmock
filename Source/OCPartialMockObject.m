//---------------------------------------------------------------------------------------
//  $Id: OCPartialMockObject.m $
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCPartialMockObject.h"

@interface OCMockObject(Private)
+ (id)_makeNice:(OCMockObject *)mock;
- (BOOL)_handleRecordedInvocations:(NSInvocation *)anInvocation;
- (NSString *)_recorderDescriptions:(BOOL)onlyExpectations;
@end

@implementation OCPartialMockObject

//---------------------------------------------------------------------------------------
//  init and dealloc
//---------------------------------------------------------------------------------------

- (id)initWithObject:(NSObject *)anObject
{
	[super initWithClass:[anObject class]];
	realObject = [anObject retain];
	return self;
}

- (void)dealloc
{
	[realObject release];
	[super dealloc];
}


//---------------------------------------------------------------------------------------
//	overrides
//---------------------------------------------------------------------------------------

- (NSString *)description
{
	return [NSString stringWithFormat:@"OCPartialMockObject[%@]", NSStringFromClass(mockedClass)];
}

- (void)_handleUnRecordedInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:realObject];
}

@end
