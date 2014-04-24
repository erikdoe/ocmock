#import <Foundation/Foundation.h>

@class OCMockObject;

@interface NSObject (OCMMockAdditions)

+ (id)mock;
+ (id)niceMock;
+ (id)partialMock;

@end
