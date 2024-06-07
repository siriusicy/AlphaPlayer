//
//  ViewController.m
//  BDAlphaPlayerDemo
//
//  Created by ByteDance on 2020/12/21.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>

#import <BDAlphaPlayer/BDAlphaPlayer.h>

@interface ViewController () <BDAlphaPlayerMetalViewDelegate>

@property (nonatomic, strong) BDAlphaPlayerMetalView *metalView;
@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UIButton *stopBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    
    //
    self.startBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 60, 60)];
    self.startBtn.backgroundColor = [UIColor orangeColor];
    [self.startBtn setTitle:@"start" forState:UIControlStateNormal];
    [self.startBtn addTarget:self action:@selector(startBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startBtn];
    
    self.stopBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, CGRectGetMaxY(self.startBtn.frame) + 10, 60, 60)];
    self.stopBtn.backgroundColor = [UIColor orangeColor];
    [self.stopBtn setTitle:@"stop" forState:UIControlStateNormal];
    [self.stopBtn addTarget:self action:@selector(stopBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.stopBtn];


    
}

- (void)startBtnClicked:(UIButton *)sender
{
    
    //
    [self.view insertSubview:self.metalView atIndex:0];
    [self.metalView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.centerX.mas_equalTo(0);
        make.height.mas_equalTo(self.metalView.mas_width).multipliedBy(988/450.0);
    }];

    self.startBtn.hidden = YES;
    self.stopBtn.alpha = 0.3;
    
//    BDAlphaPlayerMetalConfiguration *configuration = [BDAlphaPlayerMetalConfiguration defaultConfiguration];
//    NSString *testResourcePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"TestResource"];
//    NSString *directory = [testResourcePath stringByAppendingPathComponent:@"heartbeats"];
//    configuration.directory = directory;
//    configuration.renderSuperViewFrame = self.view.frame;
//    configuration.orientation = BDAlphaPlayerOrientationPortrait;
////    configuration.orientation = BDAlphaPlayerOrientationLandscape;
//
//    [self.metalView playWithMetalConfiguration:configuration];
    
    #pragma mark -  模拟多线程调用
    for (int i = 0; i<2; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
#pragma mark -  1.加载网络地址
            [self.metalView sh_playWithUrl:@"http://static.dhsf.996box.com/box/gift_animation/guard_silver_450_974.mp4"];
            
//            {
//                NSString *path = [[NSBundle mainBundle] pathForResource:@"heartbeats" ofType:@"mp4"];
//                [self.metalView sh_playWithLocalPath:path];
//            }
#pragma mark -  2.加载本地
            {
                NSString *path = [[NSBundle mainBundle] pathForResource:@"2024" ofType:@"mp4"];
                [self.metalView sh_playWithLocalPath:path];
            }
        });
        
    }
    
//#pragma mark -  1.加载网络地址
////    [self.metalView sh_playWithUrl:@"http://static.dhsf.996box.com/box/gift_animation/guard_silver_450_974.mp4"];
//#pragma mark -  2.加载本地
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"2024" ofType:@"mp4"];
//    [self.metalView sh_playWithLocalPath:path];

}

- (void)stopBtnClicked:(UIButton *)sender {
    [self.metalView stopWithFinishPlayingCallback];
//    [self.metalView removeFromSuperview];
//    self->_metalView = nil;
}

#pragma mark -  BDAlphaPlayerMetalViewDelegate
- (void)metalView:(BDAlphaPlayerMetalView *)metalView didFinishPlayingWithError:(NSError *)error {
    if (error) {
        NSLog(@"%@", error.localizedDescription);
    }
    self.startBtn.hidden = NO;
    self.stopBtn.alpha = 1;
}
///完成所有播放任务
- (void)sh_metalViewDidFinishAll:(BDAlphaPlayerMetalView *)metalView {
    [self.metalView removeFromSuperview];
    self->_metalView = nil;
}

#pragma mark -  set/get

- (BDAlphaPlayerMetalView *)metalView{
    if (_metalView == nil) {
        BDAlphaPlayerMetalView *view = [[BDAlphaPlayerMetalView alloc] initWithDelegate:self];
        view.layer.borderColor = [UIColor redColor].CGColor;
        view.layer.borderWidth = 1;
        
        _metalView = view;
    }
    return _metalView;
}



@end
