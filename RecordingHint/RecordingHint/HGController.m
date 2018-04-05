//
//  HGController.m
//  RecordingHint
//
//  Created by ZhuHong on 2018/4/4.
//  Copyright © 2018年 CoderHG. All rights reserved.
//

#import "HGController.h"
#import "HGRecordingHintView.h"

@interface HGController ()

// 仅仅是一个中间视图
@property (weak, nonatomic) IBOutlet UIView *mediumView;

@property (nonatomic, weak) HGRecordingHintView* rHintView;

@end

@implementation HGController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //
    self.mediumView.backgroundColor = [UIColor clearColor];
    
    HGRecordingHintView* rHintView = [[HGRecordingHintView alloc] init];
    [rHintView showInView:self.mediumView];
    self.rHintView = rHintView;
    
}

#pragma mark -
#pragma mark -
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!self.rHintView) {
        HGRecordingHintView* rHintView = [[HGRecordingHintView alloc] init];
        [rHintView showInView:self.mediumView];
        self.rHintView = rHintView;
    }
    
    //
    self.rHintView.rHintType = indexPath.row + HGRecordingHintTypeRecordingBar;
    
}


- (IBAction)didChangedSlider:(UISlider *)slider {
    NSLog(@"%f", slider.value);
    
    
    
    self.rHintView.volume = slider.value;
}

@end
