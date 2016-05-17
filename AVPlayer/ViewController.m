//
//  ViewController.m
//  AVPlayer
//
//  Created by getinlight on 16/5/14.
//  Copyright © 2016年 getinlight. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

/** 播放器对象 */
@property (nonatomic, strong) AVPlayer *player;

@property (weak, nonatomic) IBOutlet UIView *container;
@property (weak, nonatomic) IBOutlet UIButton *playOrPause;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UISlider *slider;

@property (nonatomic, strong) id progressObserver;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    
    [self.player play];
    
    [self addObserverToPlayItem:self.player.currentItem];
    
}

- (void)dealloc {
    [self removeNotification];
    [self.player removeTimeObserver:self.progressObserver];
    [self removeObserverFromPlayerItem:self.player.currentItem];
}

#pragma mark - 私有方法
- (void)setupUI {
    //创建播放器层
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = self.container.bounds;
    [self.container.layer addSublayer:playerLayer];
}

- (AVPlayer *)player {
    if (!_player) {
        NSString *urlStr = @"file:///Users/getinlight/Desktop/唯一的不同, 是处处都不同。_高清.mp4";
        //创建playerItem
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        _player = [AVPlayer playerWithPlayerItem:playerItem];
        
    }
    return _player;
}

#pragma mark - 播放器通知
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (void)playbackFinished:(NSNotification *)notification {
    NSLog(@"视频播放完成");
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 播放进度监控
/**
 *	进度条监控
 */
- (void)addProgressObserver {
    AVPlayerItem *playerItem = self.player.currentItem;
    //这里每秒执行一次
    __weak typeof(self) weakSelf = self;
    _progressObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds(playerItem.duration);
        NSLog(@"当前已经播放了%.2f",current);
        if (current) {
            [weakSelf.progress setProgress:(current / total) animated:YES];
            [weakSelf.slider setValue:(current / total) animated:YES];
        }
    }];
}
/**
 *	给playerItem添加监控对象
 */
- (void)addObserverToPlayItem:(AVPlayerItem *)playerItem {
    //监控状态属性: 注意AVPlayer也有一个status属性,通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if (status == AVPlayerStatusReadyToPlay) {
            NSLog(@"正在播放... 视频长度:%.2f",CMTimeGetSeconds(playerItem.duration));
            //添加各种通知和观察者
            [self addNotification];
            [self addProgressObserver];
            [self addSliderTarget];
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓存时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        NSLog(@"共缓存: %.2f",totalBuffer);
    }
}

#pragma mark - UI事件
- (IBAction)playClick:(UIButton *)sender {
    if (self.player.rate == 0) {  //暂停
        [sender setTitle:@"暂停" forState:UIControlStateNormal];
        [self.player play];
    } else if (self.player.rate == 1) {
        [self.player pause];
        [sender setTitle:@"播放" forState:UIControlStateNormal];
    }
}

- (void)addSliderTarget {
    [self.slider addTarget:self action:@selector(beginHandleSlider:) forControlEvents:UIControlEventTouchDragInside];
    [self.slider addTarget:self action:@selector(endHandleSlider:) forControlEvents:UIControlEventValueChanged];
}

- (void)beginHandleSlider:(UISlider *)slider {
    AVPlayerItem *playerItem = self.player.currentItem;
    float total = CMTimeGetSeconds(playerItem.duration);
    float current = slider.value * total;
    [self.player seekToTime:CMTimeMakeWithSeconds(current, playerItem.duration.timescale)];
    [self.player pause];
}

- (void)endHandleSlider:(UISlider *)slider {
    [self.player play];
}


@end
