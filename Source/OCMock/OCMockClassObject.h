//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2012 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMockObject.h>

@interface OCMockClassObject : OCMockObject
{
	Class	             mockedClass;
    NSMutableDictionary *mockedImpTable;
}

@property (nonatomic, assign) IMP originalForwardIMP;

+ (OCMockClassObject *)existingMockForClass:(Class)aClass;

- (id)initWithClass:(Class)aClass;

- (Class)mockedClass;

- (void)setupClass:(Class)aClass;
- (void)setupForwarderForSelector:(SEL)selector;

@end
