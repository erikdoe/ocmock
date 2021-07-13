/*
 *  Copyright (c) 2009-2021 Erik Doernenburg and contributors
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

#import "OCMPassByRefSetter.h"


@implementation OCMPassByRefSetter

// Stores a reference to each of our OCMPassByRefSetters so that OCMArg can
// check any given pointer to verify that it is an OCMPassByRefSetter.
// The pointers are stored as naked pointers with no reference counts.
// Note: all accesses protected by @synchronized(gPointerTable)
static NSHashTable *gPointerTable = NULL;

+ (void)initialize
{
    if (self == [OCMPassByRefSetter class])
    {
        gPointerTable = [[NSHashTable hashTableWithOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality] retain];
    }
}

- (id)initWithValue:(id)aValue
{
    if((self = [super init]))
    {
        value = [aValue retain];
        @synchronized(gPointerTable)
        {
            // This will throw if somehow we manage to put two of the same pointer in the table.
            NSHashInsertKnownAbsent(gPointerTable, self);
        }
    }

    return self;
}

- (void)dealloc
{
    [value release];
    @synchronized(gPointerTable)
    {
        NSAssert(NSHashGet(gPointerTable, self) != NULL, @"self should be in the hash table");
        NSHashRemove(gPointerTable, self);
    }
    [super dealloc];
}

- (void)handleArgument:(id)arg
{
    void *pointerValue = [arg pointerValue];
    if(pointerValue != NULL)
    {
        if([value isKindOfClass:[NSValue class]])
            [(NSValue *)value getValue:pointerValue];
        else
            *(id *)pointerValue = value;
    }
}

+ (BOOL)ptrIsPassByRefSetter:(void*)ptr
{
    @synchronized(gPointerTable)
    {
        return NSHashGet(gPointerTable, ptr) != NULL;
    }
}

@end
