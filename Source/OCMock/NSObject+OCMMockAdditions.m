#import "NSObject+OCMMockAdditions.h"
#import "OCMockObject.h"

@implementation NSObject (OCMMockAdditions)

+ (id)mock
{
    return [OCMockObject mockForClass:[self class]];
}

+ (id)niceMock
{
    return [OCMockObject niceMockForClass:[self class]];
}

+ (id)partialMock
{
    return [OCMockObject partialMockForObject:[self new]];
}

@end
