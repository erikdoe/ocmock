//
//  OCMockMacros.h
//  OCMock
//
//  Created by Ziad Khoury Hanna on 4/9/12.
//  Copyright (c) 2012 Mulle Kybernetik. All rights reserved.
//

#ifndef OCMock_OCMockMacros_h
#define OCMock_OCMockMacros_h

#define stub    stubInFile:[NSString stringWithUTF8String:__FILE__] atLine:__LINE__
#define expect  expectInFile:[NSString stringWithUTF8String:__FILE__] atLine:__LINE__
#define reject  rejectInFile:[NSString stringWithUTF8String:__FILE__] atLine:__LINE__

#endif
