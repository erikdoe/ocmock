/*
 *  Copyright (c) 2010-2021 Erik Doernenburg and contributors
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

#import <Foundation/Foundation.h>

@interface OCMBlockCaller : NSObject
{
    id block;
}

/*
 * Call blocks can have one of four types:
 * a) A simple block ^{ NSLog(@"hi"); }.
 * b) The new style ^(id localSelf, type0 arg0, type1 arg1) { ... }
 *    where types and args match the arguments passed to the selector we are
 *    stubbing.
 * c) The deprecated style ^(NSInvocation *anInvocation) { ... }. This case
 *    cannot have a return value. If a return value is desired it must be set
 *    on `anInvocation`.
 * d) nil
 *
 * If it is (a) or (b) and there is a return value it must match the return type
 * of the selector. If there is no return value then the method will return 0.
 */
- (id)initWithCallBlock:(id)theBlock;

- (void)handleInvocation:(NSInvocation *)anInvocation;

@end
