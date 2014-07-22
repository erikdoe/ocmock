/*
 *  Copyright (c) 2009-2014 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import "OCMBoxedReturnValueProvider.h"
#import "OCMFunctions.h"

@implementation OCMBoxedReturnValueProvider


/*
 * Sometimes an external type is an opaque struct (which will have an @encode of "{structName}"
 * or "{structName=}") but the actual method return type, or property type, will know the contents
 * of the struct (so will have an objcType of say "{structName=iiSS}".  This function will determine
 * those are equal provided they have the same structure name, otherwise everything else will be
 * compared textually.  This can happen particularly for pointers to such structures, which still
 * encode what is being pointed to.
 */
static BOOL OCMTypesEqualAllowOpaqueStructs(const char *type1, const char *type2)
{
    type1 = OCMTypeWithoutQualifiers(type1);
    type2 = OCMTypeWithoutQualifiers(type2);

    switch (type1[0])
    {
        case '{':
        case '(':
        {
            if (type2[0] != type1[0])
                return NO;
            char endChar = type1[0] == '{'? '}' : ')';
            
            const char *type1End = strchr(type1, endChar);
            const char *type2End = strchr(type2, endChar);
            const char *type1Equals = strchr(type1, '=');
            const char *type2Equals = strchr(type2, '=');
            
            /* Opaque types either don't have an equals sign (just the name and the end brace), or
             * empty content after the equals sign.
             * We want that to compare the same as a type of the same name but with the content.
             */
            BOOL type1Opaque = (type1Equals == NULL || (type1End < type1Equals) || type1Equals[1] == endChar);
            BOOL type2Opaque = (type2Equals == NULL || (type2End < type2Equals) || type2Equals[1] == endChar);
            const char *type1NameEnd = (type1Equals == NULL || (type1End < type1Equals)) ? type1End : type1Equals;
            const char *type2NameEnd = (type1Equals == NULL || (type2End < type2Equals)) ? type2End : type2Equals;
            intptr_t type1NameLen = type1NameEnd - type1;
            intptr_t type2NameLen = type2NameEnd - type2;
            
            /* If the names are not equal, return NO */
            if (type1NameLen != type2NameLen || strncmp(type1, type2, type1NameLen))
                return NO;
            
            /* If the same name, and at least one is opaque, that is close enough. */
            if (type1Opaque || type2Opaque)
                return YES;
            
            /* Otherwise, compare all the elements.  Use NSGetSizeAndAlignment to walk through the struct elements. */
            type1 = type1Equals + 1;
            type2 = type2Equals + 1;
            while (type1[0] != endChar && type1[0] != '\0')
            {
                if (!OCMTypesEqualAllowOpaqueStructs(type1, type2))
                    return NO;
                type1 = NSGetSizeAndAlignment(type1, NULL, NULL);
                type2 = NSGetSizeAndAlignment(type2, NULL, NULL);
            }
            return YES;
        }
        case '^':
            /* for a pointer, make sure the other is a pointer, then recursively compare the rest */
            if (type2[0] != type1[0])
                return NO;
            return OCMTypesEqualAllowOpaqueStructs(type1+1, type2+1);
        
        case '\0':
            return type2[0] == '\0';

        default:
        {
            // Move the type pointers past the current types, then compare that region
            const char *afterType1 =  NSGetSizeAndAlignment(type1, NULL, NULL);
            const char *afterType2 =  NSGetSizeAndAlignment(type2, NULL, NULL);
            intptr_t type1Len = afterType1 - type1;
            intptr_t type2Len = afterType2 - type2;
            
            return (type1Len == type2Len && (strncmp(type1, type2, type1Len) == 0));
        }
    }
}


- (void)handleInvocation:(NSInvocation *)anInvocation
{
	const char *returnType = [[anInvocation methodSignature] methodReturnType];
    NSUInteger returnTypeSize = [[anInvocation methodSignature] methodReturnLength];
    char valueBuffer[returnTypeSize];
    NSValue *value = (NSValue *)returnValue;
    
    if ([self getBytes:valueBuffer forValue:value compatibleWithType:returnType])
    {
        [anInvocation setReturnValue:valueBuffer];
    }
    else
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Return value does not match method signature; signature declares '%s' but value is '%s'.", returnType, [value objCType]];
    }
}

- (BOOL)isMethodReturnType:(const char *)returnType compatibleWithValueType:(const char *)valueType
{
    /* Allow void* for methods that return id, mainly to be able to handle nil */
    if(strcmp(returnType, @encode(id)) == 0 && strcmp(valueType, @encode(void *)) == 0)
        return YES;
    
    /* Same types are obviously compatible */
    if(strcmp(returnType, valueType) == 0)
        return YES;
    
    @try {
        if(OCMTypesEqualAllowOpaqueStructs(returnType, valueType))
            return YES;
    }
    @catch (NSException *e) {
        /* Probably a bitfield or something that NSGetSizeAndAlignment chokes on, oh well */
        return NO;
    }

    return NO;
}


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

- (BOOL)getBytes:(void *)outputBuf forValue:(NSValue *)inputValue compatibleWithType:(const char *)targetType
{
    /* If the types are directly compatible, use it */
    if ([self isMethodReturnType:targetType compatibleWithValueType:[inputValue objCType]])
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

@end
