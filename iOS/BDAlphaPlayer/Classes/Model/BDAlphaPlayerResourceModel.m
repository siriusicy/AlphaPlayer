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

///cj新增
+ (instancetype)sh_resourceModelWithFileName:(NSString *)fileName {
    
    if ([fileName hasSuffix:@".mp4"]) {
        fileName = [fileName substringToIndex:fileName.length - 4];
    }
    
    BDAlphaPlayerResourceInfo *infoModel = [[BDAlphaPlayerResourceInfo alloc] init];
    infoModel.contentMode = BDAlphaPlayerContentModeFitRight;
    infoModel.resourceName = fileName;
    infoModel.resourceFilePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mp4"];
    infoModel.resourceFileURL = [NSURL fileURLWithPath:infoModel.resourceFilePath ? : @""];
    
    //
    BDAlphaPlayerResourceModel *model = [[self alloc] init];
    model.currentOrientation = BDAlphaPlayerOrientationPortrait;
    model.currentOrientationResourceInfo = infoModel;
    return model;
}

@end
