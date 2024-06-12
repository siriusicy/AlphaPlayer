//
//  BDAlphaPlayerMetalView.m
//  BDAlphaPlayer
//
//  Created by ByteDance on 2020/7/5.
//

#import "BDAlphaPlayerMetalView.h"

#import "BDAlphaPlayerAssetReaderOutput.h"
#import "BDAlphaPlayerMetalRenderer.h"
#import "BDAlphaPlayerMetalShaderType.h"

#import <MetalKit/MetalKit.h>
#import <pthread.h>
#import "BDAlphaPlayerOnlineTool.h"


#ifndef bd_dispatch_queue_async_safe
#define bd_dispatch_queue_async_safe(queue, block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
        block();\
    } else {\
        dispatch_async(queue, block);\
    }
#endif

@interface BDAlphaPlayerMetalView ()

@property (nonatomic, strong) NSMutableArray<BDAlphaPlayerResourceModel *> *taskArray;
@property (nonatomic, strong) dispatch_queue_t queue;
//
@property (nonatomic, strong, readwrite) BDAlphaPlayerResourceModel *model;
@property (nonatomic, assign, readwrite) BDAlphaPlayerPlayState state;

@property (nonatomic, weak, nullable) id<BDAlphaPlayerMetalViewDelegate> delegate;

@property (nonatomic, assign) CGRect renderSuperViewFrame;
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) BDAlphaPlayerMetalRenderer *metalRenderer;

@property (nonatomic, strong) BDAlphaPlayerAssetReaderOutput *output;

@property (atomic, assign) BOOL hasDestroyed;

@end

@implementation BDAlphaPlayerMetalView

- (void)dealloc {
    NSLog(@"-=-=-= dealloc %@", NSStringFromClass(self.class));
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithDelegate:nil];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(id<BDAlphaPlayerMetalViewDelegate>)delegate
{
    if (self = [super initWithFrame:CGRectZero]) {
        self.contentScaleFactor = [UIScreen mainScreen].scale;
        self.backgroundColor = [UIColor clearColor];
        
        self.delegate = delegate;
        [self setupMetal];
        
        self.queue = dispatch_queue_create("MP4Lock", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

#pragma mark - Public Method
///cj新增
- (void)sh_playWithLocalPath:(NSString *)localPath {
    
    BDAlphaPlayerResourceModel *model = [BDAlphaPlayerResourceModel sh_resourceModelWithLocalPath:localPath];
    dispatch_barrier_sync(self.queue, ^{ ///< 写操作 加锁
        [self.taskArray addObject:model];
    });
    [self sh_playNext];
    
}
///cj新增 加载网络mp4
- (void)sh_playWithUrl:(NSString *)urlString {
    __weak typeof(self) weakSelf = self;
    [BDAlphaPlayerOnlineTool sh_loadOnlineMp4WithUrl:urlString complete:^(NSString * _Nonnull localPath, NSError * _Nullable error) {
        if (error) {
            NSLog(@"-=-=-= 播放失败 : %@", error.localizedDescription);
            return;
        }
        if (localPath.length > 0) {
            [weakSelf sh_playWithLocalPath:localPath];
        }
    }];
}

- (void)sh_playNext {
    bd_dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
        [self sh_doPlayNext];
    });
}

- (void)sh_doPlayNext {
    
    if (self.state == BDAlphaPlayerPlayStatePlay) {
        return;
    }
    __block BDAlphaPlayerResourceModel *nextModel = nil;
    dispatch_sync(self.queue, ^{
        nextModel = self.taskArray.firstObject;
    });
    if (nextModel == nil) {
        return;
    }
    //
    self.renderSuperViewFrame = self.superview.frame;
    self.model = nextModel;
    [self configRenderViewContentModeFromModel];
    [self play];
    
}

//- (void)playWithMetalConfiguration:(BDAlphaPlayerMetalConfiguration *)configuration {
//    NSAssert(!CGRectIsEmpty(configuration.renderSuperViewFrame), @"You need to initialize renderSuperViewFrame before playing");
//    NSError *error = nil;
//    self.renderSuperViewFrame = configuration.renderSuperViewFrame;
//    self.model = [BDAlphaPlayerResourceModel resourceModelFromDirectory:configuration.directory 
//                                                            orientation:configuration.orientation
//                                                                  error:&error];
//    if (error) {
//        [self didFinishPlayingWithError:error];
//        return;
//    }
//    [self configRenderViewContentModeFromModel];
//    [self play];
//}

- (NSTimeInterval)totalDurationOfPlayingEffect
{
    if (self.output) {
        return self.output.videoDuration;
    } else {
        return 0.0;
    }
}

- (void)stop
{
    [self destroyMTKView];
}

- (void)stopWithFinishPlayingCallback
{
    [self stop];
    [self renderCompletion];
}

#pragma mark - Private Method

- (void)configRenderViewContentModeFromModel
{
    BDAlphaPlayerContentMode mode = self.model.currentOrientationResourceInfo.contentMode;
    self.model.currentOrientationResourceInfo.contentMode = mode;
}

#pragma mark Callback

- (void)didFinishPlayingWithError:(NSError *)error
{
    self.state = BDAlphaPlayerPlayStateStop;
    if (self.delegate && [self.delegate respondsToSelector:@selector(metalView:didFinishPlayingWithError:)]) {
        [self.delegate metalView:self didFinishPlayingWithError:error];
    }
    
    ///cj_add
    dispatch_barrier_sync(self.queue, ^{ ///< 写操作 加锁
        if ([self.taskArray containsObject:self.model]) {
            [self.taskArray removeObject:self.model];
        }
    });
    if (self.taskArray.count > 0) {
        [self sh_playNext];
    } else {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(sh_metalViewDidFinishAll:)]) {
            [self.delegate sh_metalViewDidFinishAll:self];
        }
    }
    
}

#pragma mark Player

- (void)play
{
    NSURL *url = [self.model.currentOrientationResourceInfo resourceFileURL];
    NSError *error = nil;
    BDAlphaPlayerAssetReaderOutput *output = [[BDAlphaPlayerAssetReaderOutput alloc] initWithURL:url error:&error];
    CGRect rederFrame = [BDAlphaPlayerUtility frameFromVideoSize:output.videoSize renderSuperViewFrame:self.renderSuperViewFrame resourceModel:self.model];
    self.frame = rederFrame;
    
    if (error) {
        NSError *finishError = nil;
        switch (error.code) {
            case BDAlphaPlayerAssetReaderOutputErrorFileNotExists:
            case BDAlphaPlayerAssetReaderOutputErrorCannotReadFile:
                finishError = [NSError errorWithDomain:BDAlphaPlayerErrorDomain code:BDAlphaPlayerErrorCodeFile userInfo:error.userInfo];
                break;
            case BDAlphaPlayerAssetReaderOutputErrorVideoTrackNotExists:
                finishError = [NSError errorWithDomain:BDAlphaPlayerErrorDomain code:BDAlphaPlayerErrorCodePlay userInfo:@{NSLocalizedDescriptionKey:@"does not have video track"}];
                break;
            default:
                finishError = error;
                break;
        }
        [self didFinishPlayingWithError:finishError];
        return;
    }
    
    ///cj 将要开始播放
    if (self.delegate && 
        [self.delegate respondsToSelector:@selector(sh_metalViewWillStartPlay:)]) {
        [self.delegate sh_metalViewWillStartPlay:self];
    }
    
    self.state = BDAlphaPlayerPlayStatePlay;
    __weak __typeof(self) weakSelf = self;
    [self renderOutput:output resourceModel:self.model completion:^{
        [weakSelf renderCompletion];
    }];
}

- (void)renderCompletion
{
    [self didFinishPlayingWithError:nil];
}

- (void)renderOutput:(BDAlphaPlayerAssetReaderOutput *)output resourceModel:(BDAlphaPlayerResourceModel *)resourceModel completion:(BDAlphaPlayerRenderOutputCompletion)completion
{
    if (!self.mtkView) {
        [self setupMetal];
    }
    self.output = output;
    BDAlphaPlayerRenderOutputCompletion renderCompletion = [completion copy];
    
    __weak __typeof(self) wSelf = self;
    [self.metalRenderer renderOutput:output resourceModel:resourceModel completion:^{
        if (!wSelf) {
            return;
        }
        [wSelf destroyMTKView];
        if (renderCompletion) {
            renderCompletion();
        }
    }];
}

- (void)destroyMTKView
{
    self.mtkView.paused = YES;
    [self.mtkView removeFromSuperview];
    [self.mtkView releaseDrawables];
    [self.metalRenderer drainSampleBufferQueue];
    self.mtkView = nil;
    self.hasDestroyed = YES;
}

#pragma mark SetupMetal

- (void)setupMetal
{
    // Init MTKView
    if (!self.mtkView) {
        self.mtkView = [[MTKView alloc] initWithFrame:CGRectZero];
        self.mtkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.mtkView.backgroundColor = UIColor.clearColor;
        self.mtkView.device = MTLCreateSystemDefaultDevice();
        [self addSubview:self.mtkView];
        
        self.metalRenderer = [[BDAlphaPlayerMetalRenderer alloc] initWithMetalKitView:self.mtkView];
        __weak __typeof(self) weakSelf = self;
        self.metalRenderer.framePlayDurationCallBack = ^(NSTimeInterval duration) {
            if (weakSelf && [weakSelf.delegate respondsToSelector:@selector(frameCallBack:)]) {
                [weakSelf.delegate frameCallBack:duration];
            }
        };
        
        self.mtkView.frame = self.bounds;
        self.hasDestroyed = NO;
    }
}

#pragma mark -  set/get

- (NSMutableArray<BDAlphaPlayerResourceModel *> *)taskArray {
    if (_taskArray == nil) {
        NSMutableArray *muArr = [NSMutableArray array];
        
        _taskArray = muArr;
    }
    return _taskArray;
}


@end
