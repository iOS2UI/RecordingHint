//
//  HGRecordingHintView.m
//  RecordingHint
//
//  Created by ZhuHong on 2018/4/4.
//  Copyright © 2018年 CoderHG. All rights reserved.
//

#import "HGRecordingHintView.h"

// RGB颜色
#define HGColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

// 录音时的 话筒与音量强度 父控件的尺寸
static CGFloat const k_VOLUME_WIDTH = 90.0;
static CGFloat const k_VOLUME_HEIGHT = 70.0;

@interface HGRecordingHintView ()

// volume 的父控件
@property (nonatomic, weak) CALayer* volumeSuperLayer;

// 音量强度 layer
@property (nonatomic, weak) CALayer* volumeLayer;

// 带 border 的水柱
@property (nonatomic, weak) CALayer* waterBorderLayer;

// 即将取消录音时的 layer 显示
@property (nonatomic, weak) CALayer* willCancelLayer;

// 带边框水柱的父 layer
@property (nonatomic, weak) CALayer* borderSuperLayer;

// 带边框的 填充水柱 layer
@property (nonatomic, weak) CAShapeLayer* volumeBorderFillLayer;

// 提示文字 : 手指上滑, 取消发送 / 松开手指, 取消发送
@property (nonatomic, weak) UILabel* tipLabel;

// 显示的颜色 默认白色
@property (nonatomic, strong) UIColor* contentColor;

@end

@implementation HGRecordingHintView

#pragma mark -
#pragma mark - 构造方法
- (instancetype)initWithFrame:(CGRect)frame {
    
    // 暂时先 强制弄成 固定的尺寸
    frame.size = CGSizeMake(150, 150);
    
    // 父类方法
    self = [super initWithFrame:frame];
    
    // 默认为白色
    self.contentColor = [UIColor whiteColor];
    // 水柱默认 红色
    self.fillWaterColor = [UIColor redColor];
    // 设置所有的子 Layer
    [self setupAllSubLayer];
    // 默认正在录音
    self.rHintType = HGRecordingHintTypeRecordingBar;
    // 提示文本
    [self setupTipLabel];
    
    // 整体样式的设置
    self.layer.cornerRadius = 5.0;
    self.clipsToBounds = YES;
    self.backgroundColor = HGColor(100, 100, 100, 0.8);
    
    return self;
}

/**
 在 inView 居中显示出来
 */
- (void)showInView:(UIView*)inView {
    // 尺寸
    CGFloat width = CGRectGetWidth(inView.frame);
    CGFloat height = CGRectGetHeight(inView.frame);
    // 居中
    self.center = CGPointMake(width*0.5, height*0.5);
    
    // 显示
    [inView addSubview:self];
}

#pragma mark -
#pragma mark - setter
- (void)setRHintType:(HGRecordingHintType)rHintType {
    if (_rHintType == rHintType) {
        // 在实际开发中, 应该不会出现这种现象
        return;
    }
    // 赋值
    _rHintType = rHintType;
    
    // 取消录音
    if (rHintType == HGRecordingHintTypeDidCancel) {
        // 处理后事
        if (self.cancelBlock) {
            self.cancelBlock();
        }
        // 动画消失
        [self animationRemoveFromSuperview];
    } else {
        // 正在录音 / 即将取消录音
        [self setupRecordingView];
        
        // 提示文本放到单独的方法中处理
        [self setupTipLableStyle];
        
        // 重新修改 音量的强度
        [self volumeMask];
    }
}

- (void)setBorder:(BOOL)border {
    if (self.rHintType == HGRecordingHintTypeRecordingFlat) {
        _border = border;
    } else {
        // 强制弄成 NO
        _border = NO;
    }
    
    self.waterBorderLayer.hidden = !border;
}

- (void)setFillWaterColor:(UIColor *)fillWaterColor {
    if (_fillWaterColor == fillWaterColor) {
        return;
    }
    _fillWaterColor = fillWaterColor;
    
    self.volumeBorderFillLayer.fillColor = _fillWaterColor.CGColor;
}

// 音量强度
- (void)setVolume:(CGFloat)volume {
    if ((self.rHintType == HGRecordingHintTypeWillCancel) || self.rHintType == HGRecordingHintTypeDidCancel) {
        // 没有在录音, 直接返回
        return;
    }
    
    if (_volume == volume) {
        // 如果当前值是一样的, 就别折腾了
        return;
    }
    
    // 正常赋值
    _volume = volume;
    
    // 重新修改 音量的强度
    [self volumeMask];
}

// 音量的强度
- (void)volumeMask {
    if (self.rHintType == HGRecordingHintTypeRecordingBar) {
        // 条形
        self.volumeLayer.mask = [self volumeBarMask];
    } else if (self. rHintType == HGRecordingHintTypeRecordingFlat) {
        // 扁平水柱
        self.volumeLayer.mask = [self volumeWaterFlatMask];
    } else if (self.rHintType == HGRecordingHintTypeRecordingWaterBorder) {
        // 带边框的水柱
        self.volumeBorderFillLayer.path = [self volumeBorderFillLayerPath].CGPath;
    }
}

// 设置提示文本的样式
- (void)setupTipLableStyle {
    if (self.rHintType == HGRecordingHintTypeWillCancel) {
        self.tipLabel.text = @"松开手指, 取消发送";
        self.tipLabel.backgroundColor = HGColor(176, 60, 67, 1.0);
    } else if(self.rHintType != HGRecordingHintTypeDidCancel) {
        // 其实就是 Recording 的那些
        self.tipLabel.text = @"手指上滑, 取消发送";
        self.tipLabel.backgroundColor = [UIColor clearColor];
    }
    //    else {
    // TODO: 不用处理
    //    }
}

#pragma mark -
#pragma mark - 设置所有的子 Layer
- (void)setupAllSubLayer {
    // 正在录音时的 layer 显示
    CALayer* volumeSuperLayer = [CALayer layer];
    // 位置, 尺寸
    volumeSuperLayer.frame = CGRectMake(35, 30, k_VOLUME_WIDTH, k_VOLUME_HEIGHT);
    
    { // 这里是话筒
        // 话筒父控件的尺寸
        CGFloat voiceWidth = 50;
        CGFloat voiceHeight = k_VOLUME_HEIGHT;
        // 话筒的父 layer
        CALayer* voiceLayer = [CALayer layer];
        voiceLayer.frame = CGRectMake(0, 0, voiceWidth, voiceHeight);
        voiceLayer.backgroundColor = [UIColor clearColor].CGColor;
        [volumeSuperLayer addSublayer:voiceLayer];
        
        { // 圆筒
            CALayer* cylinderLayer = [CALayer layer];
            cylinderLayer.frame = CGRectMake(0, 0, voiceWidth, voiceHeight);
            cylinderLayer.backgroundColor = self.contentColor.CGColor;
            cylinderLayer.mask = [self cylinderMask];
            [voiceLayer addSublayer:cylinderLayer];
        }
        
        { // 话柄
            CALayer* handleLayer = [CALayer layer];
            handleLayer.frame = CGRectMake(0, 0, voiceWidth, voiceHeight);
            handleLayer.backgroundColor = self.contentColor.CGColor;
            handleLayer.mask = [self handleMask];
            [voiceLayer addSublayer:handleLayer];
        }
    }
    
    { // 这里是音量强度
        {
            CALayer* waterBorderLayer = [CALayer layer];
            waterBorderLayer.frame = CGRectMake(65, 5, 25, 60);
            waterBorderLayer.borderColor = self.contentColor.CGColor;
            waterBorderLayer.borderWidth = 1.0;
            [volumeSuperLayer addSublayer:waterBorderLayer];
            waterBorderLayer.hidden = YES;
            self.waterBorderLayer = waterBorderLayer;
        }
        
        {
            CALayer* volumeLayer = [CALayer layer];
            volumeLayer.frame = CGRectMake(65.0, 0, 25, k_VOLUME_HEIGHT);
            volumeLayer.backgroundColor = self.contentColor.CGColor;
            volumeLayer.mask = [self volumeBarMask];
            [volumeSuperLayer addSublayer:volumeLayer];
            self.volumeLayer = volumeLayer;
        }
    }
    
    [self.layer addSublayer:volumeSuperLayer];
    self.volumeSuperLayer = volumeSuperLayer;
    
    // ======== 优雅的分割线 =========
    // ======== 即将要取消时 =========
    CGFloat widht = CGRectGetWidth(self.frame);
    
    // 即将取消录音时的 layer 显示
    CALayer* willCancelLayer = [CALayer layer];
    // 尺寸占据上半部分
    willCancelLayer.frame = CGRectMake(0, 0, widht, 100);
    
    {
        // 弯曲的线
        CALayer* bendingLayer = [CALayer layer];
        bendingLayer.frame = CGRectMake((widht-34.0)*0.5, 30, 34, 55.0);
        bendingLayer.backgroundColor = self.contentColor.CGColor;
        // mask
        bendingLayer.mask = [self bendingMask];
        
        [willCancelLayer addSublayer:bendingLayer];
        
    }
    
    { // 小三角
        CALayer* smallTriangleLayer = [CALayer layer];
        smallTriangleLayer.frame = CGRectMake((widht-34.0)*0.5-7, 80, 18, 10);
        smallTriangleLayer.backgroundColor = self.contentColor.CGColor;
        smallTriangleLayer.mask = [self smallTriangleMask];
        [willCancelLayer addSublayer:smallTriangleLayer];
    }
    
    [self.layer addSublayer:willCancelLayer];
    self.willCancelLayer = willCancelLayer;
    
    // ======== 优雅的分割线 =========
    // ======== 待变快的水柱 =========
    // 带边框水柱的父 layer
    CALayer* borderSuperLayer = [CALayer layer];
    borderSuperLayer.frame = willCancelLayer.frame;
    {
        // 具体的边框 与 填充 需要用不同的 layer
        {
            // 正在录音时的 layer 显示 这个主要是为了显示边框
            CALayer* volumeBorderLayer = [CALayer layer];
            // 位置, 尺寸
            volumeBorderLayer.frame = CGRectMake(35, 30, k_VOLUME_WIDTH, k_VOLUME_HEIGHT);
            volumeBorderLayer.backgroundColor = self.contentColor.CGColor;
            
            volumeBorderLayer.mask = [self recordingMaskWithBorder:YES];
            [borderSuperLayer addSublayer:volumeBorderLayer];
        }
        
        {
            // 正在录音时的 layer 显示
            CAShapeLayer* volumeBorderFillLayer = [CAShapeLayer layer];
            // 位置, 尺寸
            volumeBorderFillLayer.frame = CGRectMake(35, 30, k_VOLUME_WIDTH, k_VOLUME_HEIGHT);
            volumeBorderFillLayer.fillColor = self.fillWaterColor.CGColor;
            // TODO: PATH
            volumeBorderFillLayer.mask = [self recordingMaskWithBorder:NO];
            [borderSuperLayer addSublayer:volumeBorderFillLayer];
            self.volumeBorderFillLayer = volumeBorderFillLayer;
        }
    }
    
    // 添加
    [self.layer addSublayer:borderSuperLayer];
    self.borderSuperLayer = borderSuperLayer;
}

#pragma mark -
#pragma mark - 手指上滑, 取消发送
// 正在录音 子视图
- (void)setupRecordingView {
    if (self.rHintType == HGRecordingHintTypeDidCancel) {
        // 这里不应该有任何的处理才对, 否则就是业务层的逻辑有问题
        return;
    }
    
    // 是否取消
    BOOL cancelIng = (self.rHintType == HGRecordingHintTypeWillCancel) || (self.rHintType == HGRecordingHintTypeDidCancel);
    // 交换显示
    self.willCancelLayer.hidden = !cancelIng;
    
    if (cancelIng) {
        self.volumeSuperLayer.hidden = YES;
        self.borderSuperLayer.hidden = YES;
        return;
    }
    
    BOOL waterBorder = (self.rHintType == HGRecordingHintTypeRecordingWaterBorder);
    
    self.volumeSuperLayer.hidden = waterBorder;
    self.borderSuperLayer.hidden = !waterBorder;
}

// 提示文本
- (void)setupTipLabel {
    CGFloat x = 9;
    UILabel* tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 113, CGRectGetWidth(self.frame) - 2*x, 20)];
    tipLabel.textColor = self.contentColor;
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.font = [UIFont systemFontOfSize:14];
    tipLabel.text = @"手指上滑, 取消发送";
    tipLabel.clipsToBounds = YES;
    tipLabel.layer.cornerRadius = 4;
    [self addSubview:tipLabel];
    self.tipLabel = tipLabel;
}

#pragma mark -
#pragma mark - 各种 Mask
// 圆筒 Mask
- (CAShapeLayer*)cylinderMask {
    // 圆筒尺寸
    CGFloat voiceBackWidth = 24;
    CGFloat voiceBackHeight = 45;
    // 椭圆
    UIBezierPath* bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(13, 0, voiceBackWidth, voiceBackHeight) cornerRadius:voiceBackWidth*0.5];
    
    // layer
    CAShapeLayer* shapLayer = [CAShapeLayer layer];
    // 线
    shapLayer.path = bezierPath.CGPath;
    
    return shapLayer;
}

// 话柄
- (CAShapeLayer*)handleMask {
    // 曲线 上半圆
    UIBezierPath* bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(25.0, 45-12.0) radius:20 startAngle:M_PI endAngle:0 clockwise:NO];
    // 竖线
    [bezierPath moveToPoint:CGPointMake(25.0, 45-12 + 20)];
    [bezierPath addLineToPoint:CGPointMake(25, k_VOLUME_HEIGHT - 3)];
    
    // layer
    CAShapeLayer* shapLayer = [CAShapeLayer layer];
    // 样式
    shapLayer.lineWidth = 5;
    shapLayer.lineJoin = kCALineJoinRound;
    shapLayer.lineCap = kCALineCapRound;
    shapLayer.fillColor = [UIColor clearColor].CGColor;
    shapLayer.strokeColor = self.contentColor.CGColor;
    // 线
    shapLayer.path = bezierPath.CGPath;
    
    // 返回
    return shapLayer;
}

// 音量的强度显示 条形
- (CAShapeLayer*)volumeBarMask {
    // 十个条
    CGFloat maxLineCount = 10;
    // 有一个比例, 最长是最短的2倍
    CGFloat maxWidht = 22;
    CGFloat minWidth = maxWidht*0.5;
    // 每条线的跨度
    CGFloat margin = (maxWidht - minWidth) / (maxLineCount-1);
    
    // 所有长度的集合
    NSMutableArray* allWidthArrM = [NSMutableArray array];
    // 最短的那条
    [allWidthArrM addObject:@(minWidth)];
    for (NSInteger i=1; i<maxLineCount-1; i++) {
        [allWidthArrM addObject:@(minWidth + i*margin)];
    }
    // 最长的那条
    [allWidthArrM addObject:@(maxWidht)];
    
    // 日志输出
#ifdef DEBUG
    NSLog(@"%@", allWidthArrM);
#endif
    // 线条的宽度
    CGFloat lineWidth = 2.0;
    // 曲线
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    // 上下间隔
    CGFloat marginY = 8.0;
    // 音量强度调控 保证在[1, 10]之间
    NSInteger volume = self.volume*10;
    volume = MAX(1, volume);
    volume = MIN(10, volume);
    // 画线
    for (NSInteger i=0; i<volume; i++) {
        // 长度
        CGFloat curWidth =  [allWidthArrM[i] floatValue];
        // 起始点
        CGPoint startLinePoint = CGPointMake(0, (allWidthArrM.count - i - 1)*3*lineWidth + marginY);
        // 结束点
        CGPoint endLinePoint = CGPointMake(curWidth, (allWidthArrM.count - i - 1)*3*lineWidth+marginY);
        // 连起来
        [bezierPath moveToPoint:startLinePoint];
        [bezierPath addLineToPoint:endLinePoint];
    }
    
    // layer
    CAShapeLayer* shapLayer = [CAShapeLayer layer];
    // 样式设置
    shapLayer.lineWidth = lineWidth;
    shapLayer.fillColor = [UIColor clearColor].CGColor;
    shapLayer.strokeColor = self.contentColor.CGColor;
    // 线
    shapLayer.path = bezierPath.CGPath;
    // 返回
    return shapLayer;
}

// 音量的强度显示  扁平水柱
- (CAShapeLayer*)volumeWaterFlatMask {
    // 线条的宽度
    CGFloat lineWidth = 25.0;
    CGFloat margin = 5;
    // 直线
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(lineWidth*0.5, k_VOLUME_HEIGHT-margin)];
    [bezierPath addLineToPoint:CGPointMake(lineWidth*0.5, margin)];
    
    
    // 音量强度调控 保证在[1, 10]之间
    CGFloat volume = MAX(0.05, self.volume);
    volume = MIN(1.0, volume);
    
    // layer
    CAShapeLayer* shapLayer = [CAShapeLayer layer];
    // 样式设置
    shapLayer.lineWidth = lineWidth;
    shapLayer.fillColor = [UIColor clearColor].CGColor;
    shapLayer.strokeColor = self.contentColor.CGColor;
    // 线
    shapLayer.path = bezierPath.CGPath;
    
    shapLayer.strokeEnd = volume;
    // 返回
    return shapLayer;
}

// 弯曲的曲线 (34, 55)
- (CAShapeLayer*)bendingMask {
    
    CGFloat lineWidth = 5;
    
    // 曲线
    UIBezierPath* bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(17, 18) radius:15 startAngle:0 endAngle:M_PI clockwise:NO];
    
    [bezierPath moveToPoint:CGPointMake(2, 18.0)];
    [bezierPath addLineToPoint:CGPointMake(2, 50.0)];
    
    [bezierPath moveToPoint:CGPointMake(32, 18.0)];
    [bezierPath addLineToPoint:CGPointMake(32, 55.0)];
    
    // layer
    CAShapeLayer* shapLayer = [CAShapeLayer layer];
    // 样式设置
    shapLayer.lineWidth = lineWidth;
    shapLayer.fillColor = [UIColor clearColor].CGColor;
    shapLayer.strokeColor = self.contentColor.CGColor;
    shapLayer.lineCap = kCALineCapRound;
    // 线
    shapLayer.path = bezierPath.CGPath;
    // 返回
    return shapLayer;
}

// 小三角 Small triangle
- (CAShapeLayer*)smallTriangleMask {
    // 三角
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(0, 0)];
    [bezierPath addLineToPoint:CGPointMake(18, 0)];
    [bezierPath addLineToPoint:CGPointMake(9, 10)];
    [bezierPath closePath];
    
    // layer
    CAShapeLayer* shapLayer = [CAShapeLayer layer];
    // 线
    shapLayer.path = bezierPath.CGPath;
    
    return shapLayer;
}

// 是否带边框 带边框则为白边框
- (CAShapeLayer*)recordingMaskWithBorder:(BOOL)border {
    // 圆筒
    UIBezierPath* bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(13, 1, 24, 45) cornerRadius:24*0.5];
    
    // 圆心 的 x 坐标
    CGFloat r_x = 25.0;
    // 小圆半径
    CGFloat smallR = 18;
    // 大圆半径
    CGFloat maxR = 22;
    
    // 大小之间
    CGFloat max_min_margin_r = (maxR - smallR) * 0.5;
    
    // 话柄
    // 内环最右边的起始点
    [bezierPath moveToPoint:CGPointMake(r_x+smallR, 45-12)];
    // 内环 从右到左
    [bezierPath addArcWithCenter:CGPointMake(r_x, 45-12.0) radius:smallR startAngle:0 endAngle:M_PI clockwise:YES];
    // 内环接到外环的最左边
    [bezierPath addArcWithCenter:CGPointMake(r_x - smallR - max_min_margin_r, 45-12) radius:max_min_margin_r startAngle:0 endAngle:M_PI clockwise:NO];
    
    // 圆心角 (估算的一个值)
    CGFloat marginAngle = 0.13;
    // 外环, 从左到右
    [bezierPath addArcWithCenter:CGPointMake(r_x, 45-12.0) radius:maxR startAngle:M_PI endAngle:(M_PI_2+marginAngle) clockwise:NO];
    // 外环 闭合 至 内环
    //    [bezierPath addLineToPoint:CGPointMake(45.0, 45-12)];
    
    // 开始画下面的那一竖
    [bezierPath addLineToPoint:CGPointMake(r_x-max_min_margin_r, 45.0-12+maxR + 1)];
    [bezierPath addLineToPoint:CGPointMake(r_x-max_min_margin_r, k_VOLUME_HEIGHT -3)];
    // 这一点 是最下面的 最右边的点
    [bezierPath addArcWithCenter:CGPointMake(r_x, k_VOLUME_HEIGHT-3) radius:max_min_margin_r startAngle:M_PI endAngle:0 clockwise:NO];
    
    [bezierPath addLineToPoint:CGPointMake(r_x+max_min_margin_r, 45.0-12+maxR + 1)];
    [bezierPath addArcWithCenter:CGPointMake(r_x, 45-12.0) radius:maxR startAngle:(M_PI_2-marginAngle) endAngle:0 clockwise:NO];
    // 最右边的圆顶
    [bezierPath addArcWithCenter:CGPointMake(r_x+smallR+max_min_margin_r, 45-12) radius:max_min_margin_r startAngle:0 endAngle:M_PI clockwise:NO];
    
    // 左边的音量变化 画一个标准的带圆角的长方形
    {
        CGRect rectangle = CGRectMake(65, 5, 22, k_VOLUME_HEIGHT-2*5);
        UIBezierPath* rectangleBezierPath = [UIBezierPath bezierPathWithRoundedRect:rectangle cornerRadius:3];
        [bezierPath appendPath:rectangleBezierPath];
    }
    
    // layer
    CAShapeLayer* shapeLayer = [CAShapeLayer layer];
    shapeLayer.lineCap = kCALineCapRound;
    shapeLayer.lineJoin = kCALineJoinRound;
    if (border) {
        // 样式
        shapeLayer.lineWidth = 1;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        shapeLayer.strokeColor = self.contentColor.CGColor;
    } else {
        // 样式
        shapeLayer.fillColor = [UIColor yellowColor].CGColor;
    }
    
    // 曲线
    shapeLayer.path = bezierPath.CGPath;
    
    // 返回
    return shapeLayer;
}

/** 带边框水柱的 path */
- (UIBezierPath*)volumeBorderFillLayerPath {
    // 让 volume 的值在 [0.05, 1.0] 区间
    CGFloat volume = MAX(0.05, self.volume);
    volume = MIN(1.0, volume);
    
    CGFloat y = volume*k_VOLUME_HEIGHT;
    CGRect rect = CGRectMake(0, k_VOLUME_HEIGHT-y, k_VOLUME_WIDTH, k_VOLUME_HEIGHT);
    // 长方形
    return [UIBezierPath bezierPathWithRect:rect];
}

// 动画消失
- (void)animationRemoveFromSuperview {
    [UIView animateWithDuration:.35 animations:^{
        self.transform = CGAffineTransformMakeScale(0.000001, 0.000001);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
