//
//  BDAlphaPlayerResourceModel.m
//  BDAlphaPlayer
//
//  Created by ByteDance on 2018/8/13.
//

#import "BDAlphaPlayerResourceModel.h"

#import "BDAlphaPlayerUtility.h"

@interface BDAlphaPlayerResourceModel ()

@end

@implementation BDAlphaPlayerResourceModel

+ (instancetype)sh_resourceModelWithLocalPath:(NSString *)localPath {
    
    BDAlphaPlayerResourceInfo *infoModel = [[BDAlphaPlayerResourceInfo alloc] init];
    infoModel.contentMode = BDAlphaPlayerContentModeScaleAspectFit;
    infoModel.resourceFilePath = localPath ? : @"";
    infoModel.resourceFileURL = [NSURL fileURLWithPath:localPath ? : @""];
    infoModel.resourceName = [infoModel.resourceFileURL lastPathComponent];
    //
    BDAlphaPlayerResourceModel *model = [[self alloc] init];
    model.currentOrientation = BDAlphaPlayerOrientationPortrait;
    model.currentOrientationResourceInfo = infoModel;
    return model;
}


@end
