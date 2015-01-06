//
// Created by Alexander Orlov on 06.01.15.
// Copyright (c) 2015 Alexander Orlov. All rights reserved.
//

#import "NSString+EncodingFixing.h"

@implementation NSString (EncodingFixing)
- (NSString *)fixedEncodingString {
    if ([self canBeConvertedToEncoding:NSWindowsCP1252StringEncoding]) {
        const char *cString = [self cStringUsingEncoding:NSWindowsCP1252StringEncoding];
        return [NSString stringWithCString:cString encoding:NSWindowsCP1251StringEncoding];
    }

    return self;
}
@end