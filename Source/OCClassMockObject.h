//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2005 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMockObject.h"


@interface OCClassMockObject : OCMockObject 
{
	Class	mockedClass;
}

- (id)initWithClass:(Class)aClass;

@end
