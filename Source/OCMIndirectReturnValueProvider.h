//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMReturnValueProvider.h"

@interface OCMIndirectReturnValueProvider : OCMReturnValueProvider 
{
	id	provider;
	SEL	selector;
}

- (id)initWithProvider:(id)aProvider andSelector:(SEL)aSelector;

@end
