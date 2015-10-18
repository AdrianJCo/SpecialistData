//
//  QueryParam.m
//  LABData2
//
//  Created by Adrian Johnson on 20/07/2015.
//  Copyright (c) 2015 App Specialist. All rights reserved.
//

#import "QueryParam.h"

@implementation QueryParam

/**
 * Instantiate this object with a column name and a DBOp to indicate the type of where clause to perform
 * in order to filter the query result.
 */
- (instancetype)initWithColumnName:(NSString *)columnName andAnOperator:(DBOp)anOperator {
    if (self = [super init]) {
        
        switch (anOperator) {
            case LIKE:
                _anOperator = @" LIKE ?";
                break;
            case EQUAL:
                _anOperator = @" = ?";
                break;
            case GREATER_THAN:
                _anOperator = @" > ?";
                break;
            case GREATER_THAN_AND_EQUAL_TO:
                _anOperator =  @" >= ?";
                break;
            case LESS_THAN:
                _anOperator = @" < ?";
                break;
            case LESS_THAN_AND_EQUAL_TO:
                _anOperator = @" <= ?";
                break;
            case IS:
                _anOperator = @" IS ?";
                break;
            default:
                _anOperator = @"";
                break;
        }
        _columnName = columnName;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] alloc] init];
    if (copy) {
        NSString *copyColumnName = [_columnName copyWithZone:zone];
        NSString *copyAnOperator = [_anOperator copyWithZone:zone];
        [copy setValue:copyColumnName forKey:@"columnName"];
        [copy setValue:copyAnOperator forKey:@"anOperator"];
    }
    return copy;
}

/**
 * Overide the isEqual: method to check only for equality of the columnName property.
 */
- (BOOL)isEqual:(id)object {
    return [_columnName isEqual:object];
}

/**
 * Should do this when overriding the isEqual: method. The hash method only returns the hash value of
 * the columnName property;
 */
- (NSUInteger)hash {
    return [_columnName hash];
}
@end
