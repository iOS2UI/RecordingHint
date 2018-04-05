//
//  HGWaterWaveDisplayLink.h
//  RecordingHint
//
//  Created by ZhuHong on 2018/4/5.
//  Copyright © 2018年 CoderHG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HGWaterWaveDisplayLink : NSObject

/**
 创建一个与 shapeLayer 关联的定时器

 @param shapeLayer 即将绘制 path 的层
 @return 返回一个定时器
 */
+ (instancetype)wwDisplayLinkWithShapeLayer:(CAShapeLayer*)shapeLayer;

/**
 启动定时器
 */
- (void)startWithVolume:(CGFloat)volume;

/**
 关闭定时器
 */
- (void)invalidate;

@end
