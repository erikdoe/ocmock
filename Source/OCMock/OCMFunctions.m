//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMFunctions.h"

BOOL OCMIsObjectType(const char *objCType)
{
    objCType = OCMTypeWithoutQualifiers(objCType);

    if(strcmp(objCType, @encode(id)) == 0)
        return YES;

    // if the returnType is a typedef to an object, it has the form ^{OriginClass=#}
    NSString *regexString = @"^\\^\\{(.*)=#.*\\}";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:NULL];
    NSString *type = [NSString stringWithCString:objCType encoding:NSASCIIStringEncoding];
    if([regex numberOfMatchesInString:type options:0 range:NSMakeRange(0, type.length)] > 0)
        return YES;

    return NO;
}


const char *OCMTypeWithoutQualifiers(const char *objCType)
{
    while(strchr("rnNoORV", objCType[0]) != NULL)
        objCType += 1;
    return objCType;
}
