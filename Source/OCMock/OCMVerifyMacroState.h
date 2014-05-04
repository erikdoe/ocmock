//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMMacroState.h"

@class OCMLocation;


@interface OCMVerifyMacroState : OCMMacroState
{
    OCMLocation    *location;
}

- (id)initWithLocation:(OCMLocation *)aLocation;


@end
