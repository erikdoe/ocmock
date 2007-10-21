
#import <Foundation/Foundation.h>


@interface OCMConstraint : NSObject 
{
}

+ (id)constraint;

+ (id)constraintWithSelector:(SEL)aSelector onObject:(id)anObject;
+ (id)constraintWithSelector:(SEL)aSelector onObject:(id)anObject withValue:(id)aValue;

+ (id)any;
+ (id)isNil;
+ (id)isNotNil;
+ (id)isNotEqual:(id)value;

- (BOOL)evaluate:(id)value;

@end

#define CONSTRAINT(aSelector) [OCMConstraint constraintWithSelector:aSelector onObject:self]
#define CONSTRAINTV(aSelector, aValue) [OCMConstraint constraintWithSelector:aSelector onObject:self withValue:(aValue)]
