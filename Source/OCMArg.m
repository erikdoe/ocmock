//---------------------------------------------------------------------------------------
//  $Id: $
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMArg.h"
#import "OCMPassByRefSetter.h"


@implementation OCMArg

+ (id *)setTo:(id)value;
{
	return (id *)[[OCMPassByRefSetter alloc] initWithValue:value];
}

@end
