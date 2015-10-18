//
//  LABData2.h
//  LABData2
//
//  Created by Adrian Johnson on 20/07/2015.
//  Copyright (c) 2015 App Specialist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCRUD.h"
#import "QueryParam.h"

@interface LABData2 : NSObject <PCRUD>
/**
 * Create a database table by the specified class.
 */
- (void) createTable:(Class)klass;

/**
 * Create a singleton of this object.
 */
+ (id<PCRUD>)sharedInstance;

@end
