//
//  MHFRESTOperation.m
//  MHFoundation
//
//  Created by Malcolm Hall on 10/09/2016.
//  Copyright © 2016 Malcolm Hall. All rights reserved.
//

#import "MHFRESTOperation_Private.h"
#import "MHFAsyncOperationSubclass.h"
#import "MHFError.h"
#import "NSError+MHF.h"
#import "MHFURLSessionTaskOperation.h"
#import "NSHTTPURLResponse+MHF.h"
#import "NSMutableURLRequest+MHF.h"
#import <objc/runtime.h>
#import "NSDictionary+MHF.h"

@interface MHFRESTOperation()

@property (nonatomic, strong) NSData *HTTPBody;

@end

@implementation MHFRESTOperation

- (instancetype)initWithURLRequest:(nullable NSURLRequest *)request
{
    self = [super init];
    if (self) {
        // need to use the setter
        self.request = request;
        self.errorKeyPath = @"error";
        self.errorReasonKeyPath = @"reason";
    }
    return self;
}

- (void)setRequest:(NSURLRequest *)request{
    _request = request.copy;
    // only mutable requests will have a JSONBody.
    _request.mhf_JSONBody = request.mhf_JSONBody;
}

- (NSURLSession *)session{
    if(!_session){
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    }
    return _session;
}

- (BOOL)asyncOperationShouldRun:(NSError**)error{
    if(!self.request) {
        *error = [NSError mhf_errorWithDomain:MHFoundationErrorDomain code:MHFErrorInvalidArguments descriptionFormat:@"A request must be provided for %@", self.class];
        return NO;
    }
    else if(self.request.HTTPBody) {
        *error = [NSError mhf_errorWithDomain:MHFoundationErrorDomain code:MHFErrorInvalidArguments descriptionFormat:@"The request must not already have a HTTPBody for %@", self.class];
        return NO;
    }
    
    if(self.request.mhf_JSONBody){
        
//        if(![self.request.mhf_JSONBody isKindOfClass:NSDictionary.class]){
//            *error = [NSError mhf_errorWithDomain:MHFoundationErrorDomain code:MHFErrorInvalidArguments descriptionFormat:@"The JSONBody must be an NSDictionary for %@", self.class];
//            return NO;
//        }
        
        @try {
            id JSON = self.request.mhf_JSONBody;
            self.HTTPBody = [NSJSONSerialization dataWithJSONObject:JSON options:0 error:error]; // todo wrap this error
        }
        @catch (NSException *exception) {
            NSDictionary* userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"The bodyJSONDictionary must be JSON compatible for %@", self.class],
                                       NSLocalizedFailureReasonErrorKey : exception.reason};
            
            *error = [NSError errorWithDomain:MHFoundationErrorDomain code:MHFErrorInvalidArguments userInfo:userInfo];
        }
        @finally{
            // if we errored or exceptioned either way we didn't get a HTTPBody.
            if(!self.HTTPBody){
                return NO;
            }
        }
    }
    
    return [super asyncOperationShouldRun:error];
}

-(void)performAsyncOperation{
    [super performAsyncOperation];
    
    NSMutableURLRequest* request = self.request.mutableCopy;
    request.HTTPBody = self.HTTPBody;
    [request mhf_setContentTypeJSON];
    [request mhf_setAcceptJSON];
    
    MHFURLSessionDataTaskOperation* dataTask = [[MHFURLSessionDataTaskOperation alloc] initWithURLRequest:request];
    dataTask.session = self.session;
    
    __block NSData* taskData;
    
    [dataTask setDataTaskCompletionBlock:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error){
            [self finishWithError:error];
            return;
        }
        taskData = data;
        self.response = (NSHTTPURLResponse *)response;
    }];
    [self addOperation:dataTask];
    
    NSBlockOperation *decodeOperation = [NSBlockOperation blockOperationWithBlock:^{
        // we parse the json regardless of if there is an error code or not.
        NSError *error;
        id JSONObject;
        if(taskData.length){
            JSONObject = [NSJSONSerialization JSONObjectWithData:taskData options:0 error:&error]; // options 0 only allows dictionary and array.
            if(!JSONObject){
                // todo wrap error
                return [self finishWithError:error];
            }
        }
        if(!self.response.mhf_isSuccessful){
            error = [self errorFromJSONObject:JSONObject response:self.response];
            return [self finishWithError:error];
        }
        
        self.JSONObject = JSONObject;
    }];
    
    [self addOperation:decodeOperation];
}

- (NSError *)errorFromJSONObject:(id)JSONObject response:(NSHTTPURLResponse *)response{
    NSMutableDictionary* errorDictionary;
    if([JSONObject isKindOfClass:[NSDictionary class]]){
        errorDictionary = ((NSDictionary *)JSONObject).mutableCopy;
        
        NSString* error = [errorDictionary valueForKeyPath:self.errorKeyPath];
        NSString* reason = [errorDictionary valueForKeyPath:self.errorReasonKeyPath];
        
        errorDictionary[NSLocalizedDescriptionKey] = error;
        errorDictionary[NSLocalizedFailureReasonErrorKey] = reason;
    }
    return [response mhf_HTTPErrorWithUserInfo:errorDictionary];
}

- (void)finishOnCallbackQueueWithError:(NSError*)error{
    if(self.RESTCompletionBlock){
        self.RESTCompletionBlock(self.JSONObject, self.response, error);
    }
    [super finishOnCallbackQueueWithError:error];
}

@end

@implementation NSURLRequest (MHFRESTOperation)
                                     
-(id)mhf_JSONBody{
    return objc_getAssociatedObject(self, @selector(mhf_JSONBody));
}

-(void)mhf_setJSONBody:(id)JSONBody{
    objc_setAssociatedObject(self, @selector(mhf_JSONBody), JSONBody, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
