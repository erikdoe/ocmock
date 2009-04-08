//---------------------------------------------------------------------------------------
//  $Id: $
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMArg.h"
#import "OCMConstraint.h"
#import "OCMPassByRefSetter.h"

@implementation OCMArg

+ (id)any
{
	return [OCMAnyConstraint constraint];
}

+ (void *)anyPointer
{
	// This magic constant is picked up in OCMockRecorder
	return (void *)0x01234567;
}

+ (id)isNil
{
	return [OCMIsNilConstraint constraint];
}

+ (id)isNotNil
{
	return [OCMIsNotNilConstraint constraint];
}

+ (id)isNotEqual:(id)value
{
	OCMIsNotEqualConstraint *constraint = [OCMIsNotEqualConstraint constraint];
	constraint->testValue = value;
	return constraint;
}

+ (id)checkWithSelector:(SEL)selector onObject:(id)anObject
{
	return [OCMConstraint constraintWithSelector:selector onObject:anObject];
}

+ (id *)setTo:(id)value;
{
	return (id *)[[OCMPassByRefSetter alloc] initWithValue:value];
}

@end
