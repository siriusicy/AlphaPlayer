//
//  BDAlphaPlayerOnlineTool.h
//  BDAlphaPlayer
//
//  Created by ChenJie on 2024/6/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAlphaPlayerOnlineTool : NSObject

///加载线上MP4
+ (void)sh_loadOnlineMp4WithUrl:(NSString *)urlString
                       complete:(void (^)(NSString *localPath, NSError * _Nullable error))completeBlock;

///下载
+ (void)downloadMp4WithURLString:(NSString *)URLString
                        complete:(void (^)(NSString *localPath, NSError * _Nullable error))completeBlock;
@end

NS_ASSUME_NONNULL_END
