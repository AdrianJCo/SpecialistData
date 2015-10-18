//
//  PropertyUtil.h
//  LABData2
//
//  Created by Adrian Johnson on 20/07/2015.
//  Copyright (c) 2015 App Specialist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PropertyUtil : NSObject

/**
 * Obtain a list of the properties in the specified class as a dictionary.
 */
+ (NSDictionary *)classPropsFor:(Class)klass;

/**
 * Obtain the primary key(s) for the specified class as an array.
 */
+ (NSArray *)getPrimaryKeyAsArray:(Class)klass;

/**
 * Obtain the primary key(s) in the specified class as a dictionary.
 */
+ (NSDictionary *)getPrimaryKey:(Class)klass;

@end
