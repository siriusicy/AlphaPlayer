//
//  BDAlphaPlayerOnlineTool.m
//  BDAlphaPlayer
//
//  Created by ChenJie on 2024/6/6.
//

#import "BDAlphaPlayerOnlineTool.h"
#import <AFNetworking/AFNetworking.h>
#import <CommonCrypto/CommonDigest.h>

@interface  BDAlphaPlayerOnlineTool()


@end

@implementation BDAlphaPlayerOnlineTool

+ (instancetype)shareInstance {
    static dispatch_once_t _onceToken;
    static BDAlphaPlayerOnlineTool *manager;
    dispatch_once(&_onceToken, ^{
        manager = [[BDAlphaPlayerOnlineTool alloc] init];
        
    });
    return manager;
}

///加载线上MP4
+ (void)sh_loadOnlineMp4WithUrl:(NSString *)urlString
                       complete:(void (^)(NSString *localPath, NSError * _Nullable error))completeBlock {
    [self downloadMp4WithURLString:urlString complete:completeBlock];
}

///下载
+ (void)downloadMp4WithURLString:(NSString *)URLString
                        complete:(void (^)(NSString *localPath, NSError * _Nullable error))completeBlock {
    
    if (URLString.length <= 0 ||
        [NSURL URLWithString:URLString] == nil) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completeBlock) {
                NSError *error = [NSError errorWithDomain:@"BDAlphaPlayer" code:441 userInfo:@{NSLocalizedDescriptionKey: @"URL有误"}];
                completeBlock(@"", error);
            }
        });
        return;
    }
    
    ///
    NSString *localFilePath = [self filePathWithUrlString:URLString];
    if ([[NSFileManager defaultManager] fileExistsAtPath:localFilePath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completeBlock) {
                completeBlock(localFilePath, nil);
            }
        });
        return;
    }
    //
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSURL *url = [NSURL URLWithString:URLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request
                                                             progress:^(NSProgress * _Nonnull downloadProgress) {
        // 更新下载进度
    }
                                                          destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        // 指定下载文件的保存路径
        return [NSURL fileURLWithPath:localFilePath];
    }
                                                    completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completeBlock) {
                completeBlock(filePath, error);
            }
        });
        
        if (error) {
            NSLog(@"mp4下载 Error: %@", error.localizedDescription);
        } else {
            NSLog(@"mp4下载 to: %@", filePath);
        }
    }];
    
    [task resume];
}

///文件路径
+ (NSString *)filePathWithUrlString:(NSString *)urlString {
    NSString *cacheKey = [self MD5String:urlString];
    NSString *SVGADataCacheDir = [self dataCacheDirectory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:SVGADataCacheDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:SVGADataCacheDir withIntermediateDirectories:NO attributes:nil error:nil];
    }
    NSString *filePath = [SVGADataCacheDir stringByAppendingFormat:@"/%@.mp4", cacheKey];
    return filePath;
}

///缓存目录
+ (nullable NSString *)dataCacheDirectory {
    NSString *dicStr = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    return [dicStr stringByAppendingFormat:@"/Gift_MP4_cache"];
}

#pragma mark -  Tool
+ (NSString *)MD5String:(NSString *)str {
    const char *cstr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), result);
    return [NSString stringWithFormat:
                @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
    ];
}


@end
