//
//  PropertyUtil.m
//  LABData2
//
//  Created by Adrian Johnson on 20/07/2015.
//  Copyright (c) 2015 App Specialist. All rights reserved.
//

#import "PropertyUtil.h"
#import <objc/runtime.h>

@implementation PropertyUtil

/**
 * Obtain the type of the specified property.
 */
static const char *getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    //printf("attributes=%s\n", attributes);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T' && attribute[1] != '@') {
            /*
             if it's a C primitive type: int "i", long "l", unsigned "I", struct, etc.
             */
            NSString *name = [[NSString alloc] initWithBytes:attribute + 1 length:strlen(attribute) - 1 encoding:NSASCIIStringEncoding];
            return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
        }
        else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
            // it's an ObjC id type:
            return "id";
        }
        else if (attribute[0] == 'T' && attribute[1] == '@') {
            // it's another ObjC object type:
            NSString *name = [[NSString alloc] initWithBytes:attribute + 3 length:strlen(attribute) - 4 encoding:NSASCIIStringEncoding];
            return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
        }
    }
    return "";
}

/**
 * Obtain a list of the properties in the specified class as a dictionary. The dictionary returned contains the property name and the property data type.
 */
+ (NSDictionary *)classPropsFor:(Class)klass
{
    if (klass == NULL) {
        return nil;
    }
    Class superduper = [klass superclass];
    NSString *superClassName = NSStringFromClass(superduper);
    NSArray *klazzes;
    if ([superClassName isEqualToString:@"NSObject"]) {
        klazzes = [[NSArray alloc] initWithObjects:klass, nil];
    } else {
        klazzes = [[NSArray alloc] initWithObjects:klass, superduper, nil];
    }
    
    
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    for (Class klazz in klazzes) {
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(klazz, &outCount);
        for (i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName != NULL) {
                const char *propType = getPropertyType(property);
                NSString *propertyName = [NSString stringWithUTF8String:propName];
                NSString *propertyType = [NSString stringWithUTF8String:propType];
                [results setObject:propertyType forKey:propertyName];
            }
        }
        
        free(properties);
    }
    // returning a copy here to make sure the dictionary is immutable
    return [NSDictionary dictionaryWithDictionary:results];
}

/**
 * Obtain the primary key(s) for the specified class as an array. If the class is a subclass of
 * another class other than NSObject then the superclass will be examined for primary keys also.
 * Properties that are marked as readonly qualify as a primary key. The class must contain an
 + initWithPrimaryKey: constructor.
 */
+ (NSArray *)getPrimaryKeyAsArray:(Class)klass
{
    if (klass == NULL) {
        return nil;
    }
    
    NSMutableArray *primaryKeys = [[NSMutableArray alloc] init];
    Class superduper = [klass superclass];
    NSString *superClassName = NSStringFromClass(superduper);
    NSArray *klazzes;
    if ([superClassName isEqualToString:@"NSObject"]) {
        klazzes = [[NSArray alloc] initWithObjects:klass, nil];
    } else {
        klazzes = [[NSArray alloc] initWithObjects:klass, superduper, nil];
    }
    for (Class klazz in klazzes) {
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(klazz, &outCount);
        for (i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName) {
                NSString *propertyName = [NSString stringWithUTF8String:propName];
                const char *attributes = property_getAttributes(property);
                if(strstr(attributes, ",R,") != NULL) {
                    [primaryKeys addObject:propertyName];
                }
            }
        }
        
        free(properties);
    }
    return primaryKeys;
}

/**
 * Obtain the primary key(s) in the specified class as a dictionary. The dictionary contains the
 * property name as a key and the data type as the value.
 */
+ (NSDictionary *)getPrimaryKey:(Class)klass
{
    if (klass == NULL) {
        return nil;
    }
    
    NSMutableDictionary *primaryKeys = [[NSMutableDictionary alloc] init];
    Class superduper = [klass superclass];
    NSString *superClassName = NSStringFromClass(superduper);
    NSArray *klazzes;
    if ([superClassName isEqualToString:@"NSObject"]) {
        klazzes = [[NSArray alloc] initWithObjects:klass, nil];
    } else {
        klazzes = [[NSArray alloc] initWithObjects:klass, superduper, nil];
    }
    for (Class klazz in klazzes) {
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(klazz, &outCount);
        for (i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName) {
                const char *attributes = property_getAttributes(property);
                if(strstr(attributes, ",R,") != NULL) {
                    const char *propType = getPropertyType(property);
                    NSString *propertyName = [NSString stringWithUTF8String:propName];
                    NSString *propertyType = [NSString stringWithUTF8String:propType];
                    [primaryKeys setObject:propertyType forKey:propertyName];
                }
            }
        }
        
        free(properties);
    }
    return [NSDictionary dictionaryWithDictionary:primaryKeys];
}

@end
