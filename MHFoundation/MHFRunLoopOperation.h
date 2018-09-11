//
//  MHFRunLoopOperation.h
//  MHFoundation
//
//  Created by Malcolm Hall on 25/01/2016.
//  Copyright © 2016 Malcolm Hall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MHFoundation/MHFDefines.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHFRunLoopOperation : NSOperation

- (void)willRun;

@end

NS_ASSUME_NONNULL_END
