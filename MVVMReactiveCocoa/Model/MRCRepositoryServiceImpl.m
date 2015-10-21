//
//  MRCRepositoryServiceImpl.m
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 15/1/27.
//  Copyright (c) 2015年 leichunfeng. All rights reserved.
//

#import "MRCRepositoryServiceImpl.h"

@implementation MRCRepositoryServiceImpl

- (RACSignal *)requestRepositoryReadmeHTML:(OCTRepository *)repository reference:(NSString *)reference {
    return [[[RACSignal
        createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            NSString *accessToken   = [SSKeychain accessToken];
            NSString *authorization = [NSString stringWithFormat:@"token %@", accessToken];
            
            MKNetworkEngine *networkEngine = [[MKNetworkEngine alloc] initWithHostName:@"api.github.com"
                                                                    customHeaderFields:@{ @"Authorization": authorization}];
            
            NSString *path = [NSString stringWithFormat:@"repos/%@/%@/readme", repository.ownerLogin, repository.name];
            MKNetworkOperation *operation = [networkEngine operationWithPath:path
                                                                      params:@{ @"ref": reference }
                                                                  httpMethod:@"GET"
                                                                         ssl:YES];
            [operation addHeaders:@{ @"Accept": @"application/vnd.github.VERSION.html" }];
            [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [subscriber sendNext:completedOperation.responseString];
                    [subscriber sendCompleted];
                });
            } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [subscriber sendError:error];
                });
            }];
            
            [networkEngine enqueueOperation:operation];
            
            return [RACDisposable disposableWithBlock:^{
                [operation cancel];
            }];
        }]
        replayLazily]
        setNameWithFormat:@"-requestRepositoryReadmeHTML: %@ reference: %@", repository, reference];
}

- (RACSignal *)requestTrendingRepositoriesSince:(NSString *)since language:(NSString *)language {
    since    = since.lowercaseString;
    language = language.lowercaseString;
    
    if ([since isEqualToString:@"today"]) {
        since = @"daily";
    } else if ([since isEqualToString:@"this week"]) {
        since = @"weekly";
    } else if ([since isEqualToString:@"this month"]) {
        since = @"monthly";
    }
    
    if ([language isEqualToString:@"all languages"]) {
        language = nil;
    }
    
    return [[[RACSignal
        createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            MKNetworkEngine *networkEngine = [[MKNetworkEngine alloc] initWithHostName:@"trending.codehub-app.com" apiPath:@"v2" customHeaderFields:nil];

            MKNetworkOperation *operation = [networkEngine operationWithPath:@"trending"
                                                                      params:@{ @"since": since ?: @"",
                                                                                @"language": language ?: @"" }];

            [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSArray *JSONArray = completedOperation.responseJSON;
                    if (JSONArray.count > 0) {
                        NSError *error = nil;
                        NSArray *repositories = [MTLJSONAdapter modelsOfClass:[OCTRepository class] fromJSONArray:JSONArray error:&error];

                        if (error) {
                        		NSLog(@"Error: %@", error);
                        } else {
                            [subscriber sendNext:repositories];
                        }
                    }
                    [subscriber sendCompleted];
                });
            } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                	[subscriber sendError:error];
                });
            }];

            [networkEngine enqueueOperation:operation];

            return [RACDisposable disposableWithBlock:^{
            	[operation cancel];
            }];
        }]
        replayLazily]
        setNameWithFormat:@"-requestTrendingRepositoriesSince: %@ language: %@", since, language];
}

@end
