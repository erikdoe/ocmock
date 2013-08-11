//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCClassMockObject.h"

@interface OCPartialMockObject : OCClassMockObject 
{
	NSObject	*realObject;
	Class		realObjectReportedClass;
}

- (id)initWithObject:(NSObject *)anObject;

- (NSObject *)realObject;
- (Class)realObjectReportedClass;

- (void)stopMocking;

- (void)setupSubclassForObject:(id)anObject;
- (void)setupForwarderForSelector:(SEL)selector;

@end


extern NSString *OCMRealMethodAliasPrefix;
