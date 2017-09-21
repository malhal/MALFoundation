//
//  NSUndoManager+MHF.h
//  MHFoundation
//
//  Created by Malcolm Hall on 19/09/2017.
//  Copyright © 2017 Malcolm Hall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MHFoundation/MHFDefines.h>

@interface NSUndoManager (MHF)

- (BOOL)mhf_isUndoingOrRedoing;

@end

