//
//  HGWaterWaveDisplayLink.m
//  RecordingHint
//
//  Created by ZhuHong on 2018/4/5.
//  Copyright © 2018年 CoderHG. All rights reserved.
//

#import "HGWaterWaveDisplayLink.h"

/**
 一个间接的 代理 Class, 为了解决 定时器引来的指针循环问题,这仅仅是其中的一种解决方案,这种方案略显别扭
 更多更详细的解决方案,可以参考这里:https://www.jianshu.com/p/f775b008532a
 */
@interface _pHGProxy : NSProxy

// 这里一定要弄成 weak 才行
@property (nonatomic, weak) id executor;

@end

@implementation _pHGProxy

// class 方法
+ (instancetype)hgProxyWithExecutor:(id)executor {
    _pHGProxy* proxy = [_pHGProxy alloc];
    proxy.executor = executor;
    return proxy;
}

// 方法转接
- (void)proxyAction {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    //
    [_executor performSelector:@selector(updatePath)];
    
#pragma clang diagnostic pop
    
}

@end

@interface HGWaterWaveDisplayLink () {
    // 定时器
    CADisplayLink* _displayLink;
    // 层
    CAShapeLayer* _shapeLayer;
    // 音量
    CGFloat _volume;
    
    // 偏移
    CGFloat _waveOffset;
}

@end

@implementation HGWaterWaveDisplayLink

- (instancetype)init {
    self = [super init];
    
    _waveOffset = 0;
    
    return self;
}

/**
 创建一个与 shapeLayer 关联的定时器
 */
+ (instancetype)wwDisplayLinkWithShapeLayer:(CAShapeLayer *)shapeLayer {
    // 创建对象
    HGWaterWaveDisplayLink* wwDisplayLink = [[self alloc] init];
    // 赋值
    wwDisplayLink->_shapeLayer = shapeLayer;
    // 返回
    return wwDisplayLink;
}

/** 启动定时器 */
- (void)startWithVolume:(CGFloat)volume {
    // 赋值音量
    _volume = volume;
    
    if (_displayLink) {
        return;
    }
    
    // 代理
    _pHGProxy* proxy = [_pHGProxy hgProxyWithExecutor:self];
    // 创建定时器
    _displayLink = [CADisplayLink displayLinkWithTarget:proxy selector:@selector(proxyAction)];
    // 添加到 Runloop 中
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

// 定时器执行方法
- (void)updatePath {
    
#ifdef DEBUG
    NSLog(@"定时器执行方法");
#endif
    // 宽度
    CGFloat width = _shapeLayer.frame.size.width;
    // 偏移
    _waveOffset += 0.5;
    
    // 尽然不能这么用 _waveOffset = _waveOffset % width;
    if (_waveOffset >= width) {
        _waveOffset = 0;
    }
    // 曲线
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(0, 0)];
    // 波的高度与宽度
    CGFloat waveHeight = 5;
    CGFloat waveWidth = width/3.0;
    
    CGFloat idx = 0;
    // 当前 layer 的高度
    CGFloat height = CGRectGetHeight(_shapeLayer.frame);
    for (NSInteger x=0; x<width; x++) {
        
        CGFloat y = waveHeight * sinf(M_PI/waveWidth*x + width*idx*0.5*M_PI/waveWidth + (_waveOffset*0.15)) + waveHeight + height*(1-_volume);
        
        [bezierPath addLineToPoint:CGPointMake(x, y)];
    }
    
    [bezierPath addLineToPoint:CGPointMake(width, height)];
    
    [bezierPath addLineToPoint:CGPointMake(0, height)];
    
    _shapeLayer.path = bezierPath.CGPath;
    
    
}

/** 关闭定时器 */
- (void)invalidate {
    if(!_displayLink) {
        return;
    }
    
    [_displayLink invalidate];
    _displayLink = nil;
}

@end
