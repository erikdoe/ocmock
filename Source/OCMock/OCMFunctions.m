//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMFunctions.h"

BOOL OCMIsObjectType(const char *objCType)
{
    // TODO: see OCMReturnValueProvider for a real impl
    objCType = OCMTypeWithoutQualifiers(objCType);
    return strcmp(objCType, @encode(id)) == 0;
}


const char *OCMTypeWithoutQualifiers(const char *objCType)
{
    while(strchr("rnNoORV", objCType[0]) != NULL)
        objCType += 1;
    return objCType;
}
