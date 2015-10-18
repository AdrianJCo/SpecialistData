//
//  LABData2.m
//  LABData2
//
//  Created by Adrian Johnson on 20/07/2015.
//  Copyright (c) 2015 App Specialist. All rights reserved.
//

#import "LABData2.h"
#import "PropertyUtil.h"
#import "DataAccess.h"
#import "PParentModel.h"
#include <stdio.h>
#include <string.h>
#import <sqlite3.h>

#define SERIAL_QUEUE_NAME "co.adrianj.gcd.DataSerialDispatchQueue"
@interface LABData2 ()

// private methods

- (void) addQueryParams:(NSArray*)instructions toStatement:(sqlite3_stmt*)statement;
- (NSArray*)getModels:(Class)model fromStatement:(sqlite3_stmt*)statement;
- (id)createParamForField:(NSString*)field inObject:(id)object;
- (NSArray*) privateSelect:(Class)clazz query:(const char*)query andArgs:(NSArray*)args;
- (NSArray*) privateSelect:(const char*)query andArgs:(NSArray*)args;
- (long long) privateUpdate:(const char*)query andArgs:(NSArray*)args;
- (long long) privateInsert:(const char*)query andArgs:(NSArray*)args;
- (long long) privateDelete:(const char*)query andArgs:(NSArray*)args;
- (void) close:(sqlite3*)openDatabase;

- (instancetype)init;

@end

@implementation LABData2
- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

/**
 * Use singleton pattern to create this object.
 */
+ (id<PCRUD>)sharedInstance
{
    static id<PCRUD> sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LABData2 alloc] init];
        // Do any other initialisation stuff here
    });
    
    return sharedInstance;
}


/**
 * Insert a new object into the database. The object type represents the database table name.
 */
- (long long) insert:(id) object {
    long long row;
        Class klass = [object class];
        NSString *tableName = NSStringFromClass(klass);
        NSDictionary *dictionary = [PropertyUtil classPropsFor:klass];
        NSEnumerator *enumerator = [dictionary keyEnumerator];
        NSMutableString *sqlQuery = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ (", tableName];
        NSMutableString *placeholders = [[NSMutableString alloc] init];
        NSMutableArray *params = [[NSMutableArray alloc] init];
        NSString *field;
        while ((field = [enumerator nextObject])) {
            // do something with object...
            [sqlQuery appendFormat:@"%@,",field];
            [placeholders appendString:@"?,"];
            if ([object valueForKey:field]) {
                [params addObject:[object valueForKey:field]];
            } else {
                [params addObject:[NSNull null]];
            }
            
        }
        NSRange range = NSMakeRange(sqlQuery.length-1, 1);
        [sqlQuery replaceCharactersInRange:range withString:@") VALUES ("];
        [sqlQuery appendFormat:@"%@)",[placeholders substringToIndex:placeholders.length - 1]];
        @synchronized(self) {
            row = [self privateInsert:[sqlQuery UTF8String] andArgs:params];
        }
    return row;
}

/**
 * Execute select query with a where clause and sort field(s).
 */
- (NSArray*) select:(Class)clazz where:(NSDictionary*)where andSortBy:(NSArray*)sort {
    @synchronized(self) {
        return [self select:clazz filter:where sortBy:sort inAsc:YES];
    }
}

/**
 * Execute select query with a where clause.
 */
- (NSArray*) select:(Class)clazz where:(NSDictionary*)where {
    //@synchronized(self) {
    return [self select:clazz filter:where sortBy:nil inAsc:YES];
    //}
}

/**
 * Select all rows in the database that correspond to the specified class type.
 */
- (NSArray*) select:(Class)clazz {
    @synchronized(self) {
        return [self select:clazz filter:nil sortBy:nil inAsc:YES];
    }
}

/**
 * Execute a select query from the databae with a where clause, sorting fields and the order in which
 * to sort the results by (ascending or descending.
 */
- (NSArray*) select:(Class)clazz filter:(NSDictionary*)where sortBy:(NSArray*)sort inAsc:(BOOL)asc {
    NSArray *list = nil;
        NSString *tableName = NSStringFromClass(clazz);
        NSDictionary *dictionary = [PropertyUtil classPropsFor:clazz];
        NSEnumerator *enumerator = [where keyEnumerator];
        NSMutableString *queryString = [[NSMutableString alloc] initWithFormat:@"SELECT * FROM %@",tableName];
        NSMutableArray *params = nil;
        if (where && where.count > 0) {
            NSMutableString *whereString = [[NSMutableString alloc] initWithString:@" WHERE "];
            params = [[NSMutableArray alloc] init];
            QueryParam *field;
            while ((field = [enumerator nextObject])) {
                // do something with object...
                [whereString appendFormat:@"%@%@ AND ",field.columnName,field.anOperator];
                NSString *dataType =        [dictionary objectForKey:field.columnName];
                if ([dataType isEqualToString:@"NSString"]) {
                    NSString *value = [where objectForKey:field];
                    if (value) {
                        [params addObject:value];
                    } else {
                        [params addObject:[NSNull null]];
                    }
                } else if ([dataType isEqualToString:@"i"] || [dataType isEqualToString:@"s"] || [dataType isEqualToString:@"S"] || [dataType isEqualToString:@"c"] || [dataType isEqualToString:@"f"] || [dataType isEqualToString:@"l"] || [dataType isEqualToString:@"L"] || [dataType isEqualToString:@"d"] || [dataType isEqualToString:@"C"] || [dataType isEqualToString:@"q"] || [dataType isEqualToString:@"Q"] || [dataType isEqualToString:@"D"] || [dataType isEqualToString:@"I"]) {
                    NSNumber *value = [where objectForKey:field];
                    if (value) {
                        [params addObject:value];
                    } else {
                        [params addObject:[NSNull null]];
                    }
                }
            }
            [queryString appendString:[whereString substringToIndex:whereString.length - 5]];
        }
        if (sort && sort.count > 0) {
            NSMutableString *orderByString = [[NSMutableString alloc] initWithString:@" ORDER BY "];
            for (NSString *orderByField in sort) {
                [orderByString appendFormat:@"%@,", orderByField];
            }
            NSRange range = NSMakeRange(orderByString.length - 1, 1);
            NSString *ascDesc = asc ? @" ASC" : @" DESC";
            [orderByString replaceCharactersInRange:range withString:ascDesc];
            [queryString appendString:orderByString];
        }
        //@synchronized(self) {
        list = [self privateSelect:clazz query:queryString.UTF8String andArgs:params];
        //if (list && list.count > 0) {
            //NSObject *obj = [list objectAtIndex:0];
            //NSLog(@"who %@",[obj valueForKey:@"objectId"]);
        //}
    return list;
}

/**
 * Execute a raw sql statement against the sqlite database with an array of arguments for the parameters.
 */
- (NSArray*) select:(NSString*)sql selectionArgs:(NSArray*)selectionArgs {
    NSLog(@"Reading data with ... %s", sql.UTF8String);
    NSArray *list = nil;


        @synchronized(self) {
            list = [self privateSelect:sql.UTF8String andArgs:selectionArgs];
        }

    return list;
}

/**
 * Exceute an update statement with a where clause against the database.
 */
- (long long) update:(id)object where:(NSDictionary*)where {
    long long row;

        Class klazz = [object class];
        NSString *tableName = NSStringFromClass(klazz);
        NSDictionary *dictionary = [PropertyUtil classPropsFor:klazz];
        NSEnumerator *paramEnumerator = [dictionary keyEnumerator];
        NSMutableString *queryString = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET ",tableName];
        NSMutableArray *params = [[NSMutableArray alloc] init];;
        NSString *field;
        while ((field = [paramEnumerator nextObject])) {
            // do something with object...
            [queryString appendFormat:@"%@=?,",field];
            
            if ([object valueForKey:field]) {
                [params addObject:[object valueForKey:field]];
            } else {
                [params addObject:[NSNull null]];
            }
            
        }
        NSRange range = NSMakeRange(queryString.length-1, 1);
        [queryString replaceCharactersInRange:range withString:@""];
        NSEnumerator *whereEnumerator = [where keyEnumerator];
        if (where && where.count > 0) {
            NSMutableString *whereString = [[NSMutableString alloc] initWithString:@" WHERE "];
            
            QueryParam *field;
            while ((field = [whereEnumerator nextObject])) {
                // do something with object...
                [whereString appendFormat:@"%@%@ AND ",field.columnName, field.anOperator];
                
                NSString *dataType =        [dictionary objectForKey:field.columnName];
                if ([dataType isEqualToString:@"NSString"]) {
                    NSString *value = [where objectForKey:field];
                    [params addObject:value];
                } else if ([dataType isEqualToString:@"i"] || [dataType isEqualToString:@"s"] || [dataType isEqualToString:@"S"] || [dataType isEqualToString:@"c"] || [dataType isEqualToString:@"f"] || [dataType isEqualToString:@"l"] || [dataType isEqualToString:@"L"] || [dataType isEqualToString:@"d"] || [dataType isEqualToString:@"C"] || [dataType isEqualToString:@"q"] || [dataType isEqualToString:@"Q"] || [dataType isEqualToString:@"D"] || [dataType isEqualToString:@"I"]) {
                    NSNumber *value = [where objectForKey:field];
                    [params addObject:value];
                }
                
            }
            [queryString appendString:[whereString substringToIndex:whereString.length - 5]];
        }
        NSLog(@"Updating data with ... %s", queryString.UTF8String);
        
        @synchronized(self) {
            row = [self privateUpdate:queryString.UTF8String andArgs:params];
        }

    return row;
}

/**
 * Execute an update statement against the specified object. The objects primary key is used as
 * an identifier.
 */
- (long long) update:(id)object {
    long long row;

        Class klazz = [object class];
        NSDictionary *dictionary = [PropertyUtil getPrimaryKey:klazz];
        NSMutableDictionary *where = [[NSMutableDictionary alloc] initWithCapacity:dictionary.count];
        NSEnumerator *enumerator = [dictionary keyEnumerator];
        NSString *columnName;
        while (columnName = [enumerator nextObject]) {
            id value = [object valueForKey:columnName];
            QueryParam *paramKey = [[QueryParam alloc] initWithColumnName:columnName andAnOperator:EQUAL];
            [where setObject:value forKey:paramKey];
        }
        row = [self update:object where:where];
    return row;
}

/**
 * Execute a delete statement against the database. The query filters rows from the table that
 * corresponds to the class data type and the where clause.
 */
- (long long) delete:(Class)clazz whereClause:(NSDictionary*)whereClause {
    long long row;

        NSString *tableName = NSStringFromClass(clazz);
        NSDictionary *dictionary = [PropertyUtil classPropsFor:clazz];
        NSEnumerator *enumerator = [whereClause keyEnumerator];
        NSMutableString *queryString = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %@ WHERE ",tableName];
        NSMutableArray *params = [[NSMutableArray alloc] init];
        QueryParam *field;
        while ((field = [enumerator nextObject])) {
            // do something with object...
            [queryString appendFormat:@"%@%@ AND ",field.columnName,field.anOperator];
            
            NSString *dataType = [dictionary objectForKey:field.columnName];
            if ([dataType isEqualToString:@"NSString"]) {
                NSString *value = [whereClause objectForKey:field];
                [params addObject:value];
            } else if ([dataType isEqualToString:@"i"] || [dataType isEqualToString:@"s"] || [dataType isEqualToString:@"S"] || [dataType isEqualToString:@"c"] || [dataType isEqualToString:@"f"] || [dataType isEqualToString:@"l"] || [dataType isEqualToString:@"L"] || [dataType isEqualToString:@"d"] || [dataType isEqualToString:@"C"] || [dataType isEqualToString:@"q"] || [dataType isEqualToString:@"Q"] || [dataType isEqualToString:@"D"] || [dataType isEqualToString:@"I"]) {
                NSNumber *value = [whereClause objectForKey:field];
                [params addObject:value];
            }
            
        }
        
        NSString *query = [queryString substringToIndex:queryString.length -5];
        @synchronized(self) {
            row = [self privateDelete:[query UTF8String] andArgs:params];
        }

    return row;
}

/**
 * Execute delete query against the database. The row to delete corresponds to the specifed object
 * passed in as a parameter.
 */
- (long long) delete:(id)object {
    long long row;

        Class klass = [object class];
        NSDictionary *dictionary = [PropertyUtil getPrimaryKey:klass];
        NSMutableDictionary *where = [[NSMutableDictionary alloc] initWithCapacity:dictionary.count];
        NSEnumerator *enumerator = [dictionary keyEnumerator];
        NSString *columnName;
        while (columnName = [enumerator nextObject]) {
            QueryParam *paramKey = [[QueryParam alloc] initWithColumnName:columnName andAnOperator:EQUAL];
            id value = [object valueForKey:columnName];
            [where setObject:value forKey:paramKey];
        }
        row = [self delete:klass whereClause:where];

    return row;
}

/**
 * Obtain an array of value objects according to the specified class which is passed in as the
 * first parameter followed by the sqlite statement object.
 */
- (NSArray*)getModels:(Class)model fromStatement:(sqlite3_stmt*)statement {
    NSMutableArray *list = [[NSMutableArray alloc] init];
    int columnCount = sqlite3_column_count(statement);
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:columnCount];
    NSDictionary *dictionary = [PropertyUtil classPropsFor:model];
    while (sqlite3_step(statement) == SQLITE_ROW) {
        
        for (char i = 0; i < columnCount; i++) {
            const char* colName = sqlite3_column_name(statement, i);
            NSString *columnName = [NSString stringWithCString:colName encoding:NSUTF8StringEncoding];
            
            NSString *dataType = [dictionary objectForKey:columnName];
            if ([columnName isEqualToString:@"description"]) {
                
            } else if (sqlite3_column_type(statement, i) == SQLITE_TEXT && ([dataType isEqualToString:@"NSString"] || [dataType isEqualToString:@"id"])) {
                char *characters = (char*)sqlite3_column_text(statement, i);
                NSString *aValue = [NSString stringWithCString:characters encoding:NSUTF8StringEncoding];
                //[row setValue:aValue forKey:columnName];
                [params setObject:aValue forKey:columnName];
            }
            else if (sqlite3_column_type(statement, i) == SQLITE_INTEGER) {
                sqlite3_int64 wholeNumber = sqlite3_column_int64(statement, i);
                NSNumber *aValue = [NSNumber numberWithLongLong:wholeNumber];
                //[row setValue:aValue forKey:columnName];
                [params setObject:aValue forKey:columnName];
            }
            else if (sqlite3_column_type(statement, i) == SQLITE_BLOB) {
                NSData *data = [[NSData alloc] initWithBytes:sqlite3_column_blob(statement, i) length: sqlite3_column_bytes(statement, i)];
                // use the following to retrieve the nsdata object:-
                // [NSKeyedArchiver archivedDataWithRootObject:value]
                //[row setValue:data forKey:columnName];
                [params setObject:data forKey:columnName];
                
            } else if (sqlite3_column_type(statement, i) == SQLITE_FLOAT && [dataType isEqualToString:@"NSDate"]) {
                double timeIntervalSince1970 = sqlite3_column_double(statement, i);
                NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:timeIntervalSince1970];
                //[row setValue:date forKey:columnName];
                [params setObject:date forKey:columnName];
            } else if (sqlite3_column_type(statement, i) == SQLITE_FLOAT) {
                double decimalNumber = sqlite3_column_double(statement, i);
                NSNumber *aValue = [NSNumber numberWithDouble:decimalNumber];
                //[row setValue:aValue forKey:columnName];
                [params setObject:aValue forKey:columnName];
            }
        }
        id row = [[model alloc] initWithParams:params];
        [list addObject:row];
    }
    return [NSArray arrayWithArray:list];
}

/**
 * Insert data into sqlite database with query and arguments.
 */
- (long long) privateInsert:(const char*)query andArgs:(NSArray*)args {
    long long created = YES;
    NSLog(@"Creating data with ... %s", query);
    
    sqlite3_stmt *statement;
    sqlite3 *database = [DataAccess openConnection];
    if(sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK) {
        //NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
    }
    if (args && args.count > 0) {
        [self addQueryParams:args toStatement:statement];
    }
    
    if(SQLITE_DONE != sqlite3_step(statement)) {
        //NSAssert1(0, @"Error while inserting data. '%s'", sqlite3_errmsg(database));
        created = sqlite3_last_insert_rowid(database);
    }
    else {
        NSLog(@"Created %llu", sqlite3_last_insert_rowid(database));
        sqlite3_reset(statement);
        NSLog(@"about to finalise:");
        sqlite3_finalize(statement);
        NSLog(@"finalised:");
        [self close:database];
    }
    
    return created;
}

/**
 * Delete data into sqlite database with query and arguments.
 */
- (long long) privateDelete:(const char*)query andArgs:(NSArray*)args {
    long long deleted = 0;
    sqlite3_stmt *statement;
    sqlite3* database = [DataAccess openConnection];
    NSLog(@"Deleting data with ... %s", query);
    if(sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK) {
        NSAssert1(0, @"Error while creating delete statement. '%s'", sqlite3_errmsg(database));
    }
    
    // extract the parameters from the list (params) and add them to the database statement.
    if (args && args.count > 0) {
        [self addQueryParams:args toStatement:statement];
    }
    if(SQLITE_DONE != sqlite3_step(statement)) {
        NSAssert1(0, @"Error while removing data. '%s'", sqlite3_errmsg(database));
    }
    else {
        deleted = sqlite3_last_insert_rowid(database);
        NSLog(@"Removed %llu", deleted);
        sqlite3_reset(statement);
    }
    NSLog(@"about to finalise:");
    sqlite3_finalize(statement);
    NSLog(@"finalised:");
    [self close:database];
    return deleted;
}

/**
 * Add the additional parameters to the database query.
 *
 */
- (void) addQueryParams:(NSArray*)instructions toStatement:(sqlite3_stmt*)statement {
    for (int i = 0; i < [instructions count]; i++) {
        id param = [instructions objectAtIndex:i];
        if ([param isKindOfClass:[NSData class]]) {
            NSData *data = (NSData*)param;
            sqlite3_bind_blob(statement, i+1, [data bytes], (int)[data length], NULL);
        }
        else if ([param isKindOfClass:[NSNumber class]]) {
            NSNumber *number = (NSNumber*)param;
            const char *dataType = number.objCType;
            NSLog(@"What %s", dataType);
            
            if (strncmp(dataType, "i",1) == 0 || strncmp(dataType, "s",1) == 0 || strncmp(dataType, "c",1) == 0) {
                sqlite3_bind_int(statement, i+1, number.intValue);
            } else if (strncmp(dataType, "l",1) == 0 || strncmp(dataType, "q",1) == 0 || strncmp(dataType, "Q",1) == 0) {
                sqlite3_bind_int64(statement, i+1, number.longLongValue);
            } else if (strncmp(dataType, "d",1) == 0 || strncmp(dataType, "f",1) == 0 ) {
                sqlite3_bind_double(statement, i+1, number.doubleValue);
            }
            
        }
        else if ([param isKindOfClass:[NSDate class]]) {
            NSDate *date = param;
            sqlite3_bind_double(statement, i+1, [date timeIntervalSince1970]);
        }
        else if ([param isKindOfClass:[NSString class]]) {
            const char *characters = [param UTF8String];
            sqlite3_bind_text(statement, i+1, characters, -1, SQLITE_TRANSIENT);
        }
    }
}

/**
 * Close the database connection.
 */
- (void) close:(sqlite3*)openDatabase {
    NSLog(@"About to close Database");
    if (sqlite3_close(openDatabase) != SQLITE_OK) {
        NSAssert1(0, @"Error: failed to close database: '%s'.", sqlite3_errmsg(openDatabase));
    } else {
        NSLog(@"Closing Database");
    }
}

/**
 * Create a database table accoring to the specified class parameter, using the class name and
 * its properties to define the table name and the column names respectively.
 */
- (void)createTable:(Class)klass {
    NSString *tableName = NSStringFromClass(klass);
    NSDictionary *dictionary = [PropertyUtil classPropsFor:klass];
    NSEnumerator *enumerator = [dictionary keyEnumerator];
    NSMutableString *query = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (", tableName];
    NSString *field;
    while ((field = [enumerator nextObject])) {
        // do something with object...
        [query appendFormat:@"%@,",field];
    }
    NSArray *primaryKeys = [PropertyUtil getPrimaryKeyAsArray:klass];
    NSMutableString *primaryKey = [[NSMutableString alloc] init];
    for (int i = 0; i < primaryKeys.count; i++) {
        NSString *key = [primaryKeys objectAtIndex:i];
        if (i == (primaryKeys.count-1)) {
            [primaryKey appendFormat:@"%@)", key];
        } else {
            [primaryKey appendFormat:@"%@,", key];
        }
    }
    if (primaryKey.length > 0) {
        [query appendFormat:@"PRIMARY KEY (%@)", primaryKey];
    } else {
        NSRange range = NSMakeRange(query.length-1, 1);
        [query replaceCharactersInRange:range withString:@")"];
    }
    @synchronized(self) {
        [self privateInsert:[query UTF8String] andArgs:nil];
    }
}

/**
 * Not really necessary, but used to obtain a value from a dictionary. NEEDS TO BE REFACTORED.
 */
- (id)createParamForField:(NSString*)field inObject:(NSDictionary*)object {
    return [object valueForKey:field];
}

/**
 * Execute select query according to the specified class, query string and an array of arguments.
 */
- (NSArray*) privateSelect:(Class)clazz query:(const char*)query andArgs:(NSArray*)args {
    NSArray *list = nil;
    sqlite3_stmt *statement;
    sqlite3* database = [DataAccess openConnection];
    NSLog(@"Reading data with ... %s", query);
    int sqlResult = sqlite3_prepare_v2(database, query, -1, &statement, NULL);
    
    if (sqlResult == SQLITE_OK) {
        if (args) {
            [self addQueryParams:args toStatement:statement];
        }
        list = [self getModels:clazz fromStatement:statement];
        NSLog(@"about to finalise:");
        sqlite3_finalize(statement);
        NSLog(@"finalised:");
        [self close:database];
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d",sqlResult);
    }
    
    
    return list;
}

- (long long) privateUpdate:(const char*)query andArgs:(NSArray*)args {
    long long row = 0;
    sqlite3_stmt *statement;
    sqlite3* database = [DataAccess openConnection];
    if(sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK) {
        NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
    }
    
    [self addQueryParams:args toStatement:statement];
    if(SQLITE_DONE != sqlite3_step(statement)) {
        NSAssert1(0, @"Error while inserting data. '%s'", sqlite3_errmsg(database));
    }
    else {
        row = sqlite3_last_insert_rowid(database);
        NSLog(@"Updated %llu", row);
        sqlite3_reset(statement);
    }
    NSLog(@"about to finalise:");
    sqlite3_finalize(statement);
    NSLog(@"finalised:");
    [self close:database];
    return row;
}

/**
 * Execute select string with placeholders (?) and an array of arguments.
 */
- (NSArray*) privateSelect:(const char*)query andArgs:(NSArray*)args {
    NSMutableArray *list = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    sqlite3* database = [DataAccess openConnection];
    int sqlResult = sqlite3_prepare_v2(database, query, -1, &statement, NULL);
    
    if (sqlResult == SQLITE_OK) {
        
        if (args) {
            [self addQueryParams:args toStatement:statement];
        }
        int columnCount = sqlite3_column_count(statement);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
            for (char i = 0; i < columnCount; i++) {
                const char* colName = sqlite3_column_name(statement, i);
                NSString *columnName = [NSString stringWithCString:colName encoding:NSUTF8StringEncoding];
                if (sqlite3_column_type(statement, i) == SQLITE_TEXT) {
                    char *characters = (char*)sqlite3_column_text(statement, i);
                    [row setObject:[NSString stringWithCString:characters encoding:NSUTF8StringEncoding] forKey:columnName];
                } else
                    if (sqlite3_column_type(statement, i) == SQLITE_INTEGER) {
                        sqlite3_int64 wholeNumber = sqlite3_column_int64(statement, i);
                        [row setValue:[NSNumber numberWithLongLong:wholeNumber] forKey:columnName];
                    } else
                        if (sqlite3_column_type(statement, i) == SQLITE_BLOB) {
                            NSData *data = [[NSData alloc] initWithBytes:sqlite3_column_blob(statement, i) length: sqlite3_column_bytes(statement, i)];
                            // use the following to retrieve the nsdata object:-
                            // [NSKeyedArchiver archivedDataWithRootObject:value]
                            [row setObject:data forKey:columnName];
                            
                        } else
                            if (sqlite3_column_type(statement, i) == SQLITE_FLOAT) {
                                double decimalNumber = sqlite3_column_double(statement, i);
                                [row setObject:[NSNumber numberWithDouble:decimalNumber] forKey:columnName];
                            }
            }
            [list addObject:row];
        }
        NSLog(@"about to finalise:");
        sqlite3_finalize(statement);
        NSLog(@"finalised:");
        [self close:database];
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d",sqlResult);
    }
    
    
    return list;
}

@end
