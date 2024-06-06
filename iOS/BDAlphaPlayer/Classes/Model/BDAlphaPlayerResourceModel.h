//
//  BDAlphaPlayerResourceModel.h
//  BDAlphaPlayer
//
//  Created by ByteDance on 2018/8/13.
//

#import "BDAlphaPlayerResourceInfo.h"
#import "BDAlphaPlayerDefine.h"
#import "BDAlphaPlayerUtility.h"

#import <Foundation/Foundation.h>

@interface BDAlphaPlayerResourceModel : NSObject

/** Orientation of currently displaying MP4. */
@property (nonatomic, assign) BDAlphaPlayerOrientation currentOrientation;

/** The resource model for current orientation. */
@property (nonatomic, strong) BDAlphaPlayerResourceInfo *currentOrientationResourceInfo;


///cj新增
+ (instancetype)sh_resourceModelWithFileName:(NSString *)fileName;
+ (instancetype)sh_resourceModelWithLocalPath:(NSString *)localPath;

@end
