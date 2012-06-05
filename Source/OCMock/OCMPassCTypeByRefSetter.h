//---------------------------------------------------------------------------------------
//  $Id$
//	Addition by gaustin@rhapsody.com to support byRef C types.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMPassCTypeByRefSetter : NSObject 
{
    NSValue *valueData;
}

- (id)initWithValue:(NSValue*)inValue;

- (NSValue*)value;


@end
