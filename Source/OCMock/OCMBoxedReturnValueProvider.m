//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMBoxedReturnValueProvider.h"
#import <objc/runtime.h>

@implementation OCMBoxedReturnValueProvider

static CFNumberType OCMNumberTypeForObjCType(const char *objcType)
{
    switch (objcType[0])
    {
        case 'c': return kCFNumberCharType;
        case 'C': return kCFNumberCharType;
        case 'B': return kCFNumberCharType;
        case 's': return kCFNumberShortType;
        case 'S': return kCFNumberShortType;
        case 'i': return kCFNumberIntType;
        case 'I': return kCFNumberIntType;
        case 'l': return kCFNumberLongType;
        case 'L': return kCFNumberLongType;
        case 'q': return kCFNumberLongLongType;
        case 'Q': return kCFNumberLongLongType;
        case 'f': return kCFNumberFloatType;
        case 'd': return kCFNumberDoubleType;
    }
    
    return 0;
}

static NSNumber *OCMNumberForValue(NSValue *value)
{
#define CREATE_NUM(_type, _meth) ({ _type _v; [value getValue:&_v]; [NSNumber _meth _v]; })
    switch ([value objCType][0])
    {
        case 'c': return CREATE_NUM(char,               numberWithChar:);
        case 'C': return CREATE_NUM(unsigned char,      numberWithUnsignedChar:);
        case 'B': return CREATE_NUM(bool,               numberWithBool:);
        case 's': return CREATE_NUM(short,              numberWithShort:);
        case 'S': return CREATE_NUM(unsigned short,     numberWithUnsignedShort:);
        case 'i': return CREATE_NUM(int,                numberWithInt:);
        case 'I': return CREATE_NUM(unsigned int,       numberWithUnsignedInt:);
        case 'l': return CREATE_NUM(long,               numberWithLong:);
        case 'L': return CREATE_NUM(unsigned long,      numberWithUnsignedLong:);
        case 'q': return CREATE_NUM(long long,          numberWithLongLong:);
        case 'Q': return CREATE_NUM(unsigned long long, numberWithUnsignedLongLong:);
        case 'f': return CREATE_NUM(float,              numberWithFloat:);
        case 'd': return CREATE_NUM(double,             numberWithDouble:);
    }
    
    return nil;
}

static BOOL OCMGetOutputValue(NSValue *inputValue, const char *targetType, void *outputBuf)
{
    /* If the types match exactly, use it */
    if (strcmp(targetType, [inputValue objCType]) == 0)
    {
        [inputValue getValue:outputBuf];
        return YES;
    }

    /*
     * See if they are similar number types, and if we can convert losslessly between them.
     * For the most part, we set things up to use CFNumberGetValue, which returns false if
     * conversion will be lossy.
     */
    CFNumberType inputType = OCMNumberTypeForObjCType([inputValue objCType]);
    CFNumberType outputType = OCMNumberTypeForObjCType(targetType);
    
    if (inputType == 0 || outputType == 0) // one or both are non-number types
        return NO;
    

    NSNumber *inputNumber = [inputValue isKindOfClass:[NSNumber class]]? (id)inputValue : OCMNumberForValue(inputValue);
    
    /*
     * Due to some legacy, back-compatible requirements in CFNumber.c, CFNumberGetValue can return true for
     * some conversions which should not be allowed (by reading source, conversions from integer types to
     * 8-bit or 16-bit integer types).  So, check ourselves.
     */
    long long min = LLONG_MIN;
    long long max = LLONG_MAX;
    long long val = [inputNumber longLongValue];
    switch (targetType[0])
    {
        case 'B':
        case 'c': min = CHAR_MIN; max =  CHAR_MAX; break;
        case 'C': min =        0; max = UCHAR_MAX; break;
        case 's': min = SHRT_MIN; max =  SHRT_MAX; break;
        case 'S': min =        0; max = USHRT_MAX; break;
    }
    if (val < min || val > max)
        return NO;

    /* Get the number, and return NO if the value was out of range or conversion was lossy */
    return CFNumberGetValue((CFNumberRef)inputNumber, outputType, outputBuf);
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
	const char *returnType = [[anInvocation methodSignature] methodReturnType];
    NSUInteger returnTypeSize = [[anInvocation methodSignature] methodReturnLength];
    char valueBuffer[returnTypeSize];
    NSValue *value = (NSValue *)returnValue;
    
    if (OCMGetOutputValue(value, returnType, valueBuffer))
    {
        [anInvocation setReturnValue:valueBuffer];
    }
    else
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Return value does not match method signature; signature declares '%s' but value is '%s'.", returnType, [value objCType]] userInfo:nil];
    }
}

@end
