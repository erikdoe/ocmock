//---------------------------------------------------------------------------------------
//  $Id$
//	Addition by gaustin@rhapsody.com to support byRef C types.
//---------------------------------------------------------------------------------------

#import "OCMPassCTypeByRefSetter.h"

@implementation OCMPassCTypeByRefSetter

- (id)initWithValue:(NSValue*)inValue {
    self = [super init];
    if (self) {
        valueData = [inValue retain];
    }
    return self;
}

- (void)dealloc {
    [valueData release];
    [super dealloc];
}

- (NSValue*)value {
    return valueData;
}

@end
