//
//  NSDictionary+MHF.h
//  MHFoundation
//
//  Created by Malcolm Hall on 18/09/2017.
//  Copyright © 2017 Malcolm Hall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MHFoundation/MHFDefines.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (MHF)

@property (readonly, copy) NSArray<KeyType> *mhf_allKeysSet;

// when fetching related data from core data using NSDictionaryResultType the dictionary keys are flat key paths
// e.g. {app.bundleIdentifier : ...} instead of {app : {bundleIdentifier : ...}}
// this method converts the flat keys into nested dictionaries.
@property (readonly, copy) NSDictionary<KeyType, ObjectType> *mhf_unflattenDictionary;

//- (NSArray<ObjectType> *)mhf_objectsForKnownKeys:(NSArray<KeyType> *)keys;

- (instancetype)mhf_dictionaryByAddingEntriesFromDictionary:(NSDictionary *)dictionary;

- (nullable ObjectType)mhf_nilIfNSNullObjectForKey:(id)aKey;

- (NSString *)mhf_prettyDescriptionWithTabLevel:(NSUInteger)tabLevel;

@end

NS_ASSUME_NONNULL_END
