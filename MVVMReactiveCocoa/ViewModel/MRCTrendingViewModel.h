//
//  MRCTrendingViewModel.h
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 15/10/20.
//  Copyright © 2015年 leichunfeng. All rights reserved.
//

#import "MRCOwnedReposViewModel.h"

@interface MRCTrendingViewModel : MRCOwnedReposViewModel

@property (nonatomic, copy) NSString *since;
@property (nonatomic, copy) NSString *language;

@end
