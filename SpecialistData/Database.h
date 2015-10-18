//
//  Database.h
//  LABData2
//
//  Created by Adrian Johnson on 20/07/2015.
//  Copyright (c) 2015 App Specialist. All rights reserved.
//

#ifndef LABData2_Database_h
#define LABData2_Database_h

#endif
#import "LABData2.h"
#import <sqlite3.h>
@protocol Database

/**
 * Class method for opening a connection to the database.
 */
+ (sqlite3*) openConnection;

@end
