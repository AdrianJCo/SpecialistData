//
//  QueryParam.h
//  LABData2
//
//  Created by Adrian Johnson on 20/07/2015.
//  Copyright (c) 2015 App Specialist. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Enumeration of operators used in sql queries.
 */
typedef enum {
    LIKE, LESS_THAN, GREATER_THAN, EQUAL, LESS_THAN_AND_EQUAL_TO, GREATER_THAN_AND_EQUAL_TO, IS
} DBOp;

@interface QueryParam : NSObject <NSCopying>

/**
 * Name of the database table column.
 */
@property (nonatomic, strong, readonly) NSString *columnName;

/**
 * The operation to be executed on a database query.
 */
@property (nonatomic, strong, readonly) NSString *anOperator;

/**
 * Instantiate this object with a column name and a DBOp to indicate the type of where clause to perform
 * in order to filter the query result.
 */
- (instancetype)initWithColumnName:(NSString*)columnName andAnOperator:(DBOp)anOperator;

@end
