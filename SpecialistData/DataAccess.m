//
//  DataAccess.m
//  LABData2
//
//  Created by Adrian Johnson on 20/07/2015.
//  Copyright (c) 2015 App Specialist. All rights reserved.
//

#import "DataAccess.h"

#define DATABASE_SCHEMA @"mydatabase.db"


/**
 * Datatase access class for accessing the ios internal database. Conforms to the Database protocol.
 *
 */
@implementation DataAccess

/**
 * If the database is not in the document directory then copy the schema from the main
 * bundle to the document directory. Only if the database is in the document directory will
 * it be writable.
 *
 */

+ (sqlite3*) openConnection {
    //sqlite3* database = NULL;
    sqlite3* database = NULL;
    BOOL success = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    NSString *writableDB = [documentsDir stringByAppendingPathComponent:DATABASE_SCHEMA];
    NSLog(@"DATABASE DOCUMENT PATH %@", writableDB);
    success = [fileManager fileExistsAtPath:writableDB];
    if (success) {
        if (sqlite3_open([writableDB UTF8String], &database) == SQLITE_OK) {
            NSLog(@"Opening Database");
        } else {
            sqlite3_close(database);
            //NSAssert1(0, @"Failed to open database: '%s'.", sqlite3_errmsg(database));
        }
        return database;
    } else {
        success = [fileManager createFileAtPath:writableDB contents:nil attributes:nil];
        if (!success) {
            NSAssert1(0, @"Failed to create writable database file:'%@'.", [error localizedDescription]);
        } else {
            if (sqlite3_open([writableDB UTF8String], &database) == SQLITE_OK) {
                NSLog(@"Opening Database");
            } else {
                sqlite3_close(database);
                NSAssert1(0, @"Failed to open database: '%s'.", sqlite3_errmsg(database));
            }
        }

    }
        return database;
}

@end
