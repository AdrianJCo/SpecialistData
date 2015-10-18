//
//  DataAccess.h
//  LABData2
//
//  Created by Adrian Johnson on 20/07/2015.
//  Copyright (c) 2015 App Specialist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

/**
 * Datatase access class for accessing the ios internal database. Conforms to the Database protocol.
 *
 */
@interface DataAccess : NSObject<Database>

@end
