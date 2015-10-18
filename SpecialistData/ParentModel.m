//
//  ParentModel.m
//  LABData2
//
//  Created by Adrian Johnson on 20/07/2015.
//  Copyright (c) 2015 App Specialist. All rights reserved.
//

#import "ParentModel.h"

@implementation ParentModel

- (instancetype)initWithParams:(NSMutableDictionary*)params {
    if (self = [super init]) {
        NSEnumerator *enumerator = [params keyEnumerator];
        id key;
        while ((key = enumerator.nextObject)) {
            id aValue = [params objectForKey:key];
            [self setValue:aValue forKey:key];
        }
    }
    return self;
}

@end
