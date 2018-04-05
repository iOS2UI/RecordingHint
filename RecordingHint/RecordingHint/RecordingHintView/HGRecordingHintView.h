//
//  HGRecordingHintView.h
//  RecordingHint
//
//  Created by ZhuHong on 2018/4/4.
//  Copyright © 2018年 CoderHG. All rights reserved.
//

#import <UIKit/UIKit.h>

// 录音状态
typedef NS_ENUM(NSInteger, HGRecordingHintType) {
    /** 正在录音 条形的样式 */
    HGRecordingHintTypeRecordingBar = 1000,
    /** 正在录音 扁平水柱的样式 */
    HGRecordingHintTypeRecordingFlat,
    /** 正在录音 带边框的水柱的样式 */
    HGRecordingHintTypeRecordingWaterBorder,
    /** 正在录音 带边框的水波样式 */
    HGRecordingHintTypeRecordingWaterWave,
    /** 即将取消录音 */
    HGRecordingHintTypeWillCancel,
    /** 取消录音 */
    HGRecordingHintTypeDidCancel
};

// 取消回调
typedef void(^CancelBlock)(void);

@interface HGRecordingHintView : UIView

/**
 录音状态 : 正在录音(默认) / 取消录音
 */
@property (nonatomic, assign) HGRecordingHintType rHintType;

/**
 音量的强度 (0 ~ 1.0)
 */
@property (nonatomic, assign) CGFloat volume;

/**
 是否有 border 默认: NO
 */
@property (nonatomic, assign) BOOL border;

/**
 水柱颜色 默认 红色
 */
@property (nonatomic, strong) UIColor* fillWaterColor;

/**
 取消时候处理其它状态
 */
@property (nonatomic, copy) CancelBlock cancelBlock;


/**
 在 inView 居中显示出来
 
 @param inView 父亲视图
 */
- (void)showInView:(UIView*)inView;

@end
