//
//  ViewController.m
//  DJI RC
//
//  Created by Realank on 16/1/25.
//  Copyright © 2016年 realank. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>

#define LINE_WIDTH 20
#define SAMPLE_COUNT 5
#define BEGIN_RATE 0.15
#define END_RATE 0.8

@interface ViewController ()
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (weak, nonatomic) IBOutlet UIView *centerView;
@property (nonatomic, weak) CAShapeLayer *xLine;
@property (nonatomic, weak) CAShapeLayer *yLine;

@property (nonatomic, assign) CGFloat maxWidth;

@property (weak, nonatomic) IBOutlet UIButton *resetBtn;

@property (nonatomic, assign) BOOL stoped;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect screedBounds = [UIScreen mainScreen].bounds;
    self.maxWidth = MIN(screedBounds.size.width, screedBounds.size.height) / 2 *0.7;
    
}

- (void)viewDidAppear:(BOOL)animated {
    [self startAccelerate];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self stopAccelerate];
}

- (IBAction)resetBtnClick:(id)sender {
    self.resetBtn.selected = !self.resetBtn.selected;
    if (self.resetBtn.selected) {
        self.stoped = YES;
    }
}


- (void)startAccelerate {
    self.motionManager = [[CMMotionManager alloc]init];
    self.motionManager.accelerometerUpdateInterval = 0.01;
     __weak __typeof(self) weakSelf = self;
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        CMAcceleration acc = accelerometerData.acceleration;
//        NSLog(@"%f,%f,%f",acc.x,acc.y,acc.z);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateAccWithX:acc.x Y:acc.y Z:acc.z];
        });
    }];
}

- (void)stopAccelerate {
    [self.motionManager stopAccelerometerUpdates];
    self.motionManager = nil;
}

- (void)updateAccWithX:(double)x Y:(double)y Z:(double)z {
    static int count = 0;
    static double xSum = 0;
    static double ySum = 0;
    count++;
    if (count <= SAMPLE_COUNT) {
        xSum += x;
        ySum += y;
    }else {
        count = 0;
        double xAcc = xSum/SAMPLE_COUNT;
        xAcc = [self filterData:xAcc];
        xSum = 0;
        
        double yAcc = -ySum/SAMPLE_COUNT;
        yAcc = [self filterData:yAcc];
        ySum = 0;
        
        
        if (self.stoped) {
            if (!self.resetBtn.selected) {
                if (xAcc == 0 && yAcc == 0) {
                    self.stoped = NO;
                }
            }
            xAcc = 0;
            yAcc = 0;
        }
        
        [self drawYAcc:xAcc];
        [self drawXAcc:yAcc];
        
        if (xAcc == 0 && yAcc == 0) {
            if (self.centerView.tag != 0) {
                self.centerView.tag = 0;
                self.centerView.backgroundColor = [UIColor redColor];
            }
            
        }else{
            if (self.centerView.tag != 1){
                self.centerView.tag = 1;
                self.centerView.backgroundColor = [UIColor greenColor];
            }

        }
    }
    
}

- (double)filterData:(double) rawData{
    

    BOOL isMinus = rawData < 0;
    rawData = fabs(rawData);
    
    if (rawData < BEGIN_RATE) {
        rawData = BEGIN_RATE;
    }else if (rawData > END_RATE) {
        rawData = END_RATE;
    }
    
    rawData = (rawData-BEGIN_RATE)/(END_RATE - BEGIN_RATE);
    if (isMinus) {
        rawData = -rawData;
    }
    return rawData;
}

//－1~1
- (void)drawXAcc:(double)x {
//    NSLog(@"%lf",x);
    if (!self.xLine) {
        CAShapeLayer *line = [[CAShapeLayer alloc]init];
        self.xLine = line;
        line.frame = self.view.bounds;
        line.fillColor = [UIColor lightGrayColor].CGColor;
        line.lineCap = kCALineCapButt;
        [self.view.layer addSublayer:line];
    }
    CGPoint center = self.centerView.center;
    
    if (x > 0.01) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(center.x + LINE_WIDTH, center.y - LINE_WIDTH/2, x*self.maxWidth , LINE_WIDTH)];
        self.xLine.path = path.CGPath;
    }else if (x < -0.01){
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(center.x - LINE_WIDTH, center.y - LINE_WIDTH/2, x*self.maxWidth , LINE_WIDTH)];
        self.xLine.path = path.CGPath;
    }else {
        self.xLine.path = NULL;
    }
}

- (void)drawYAcc:(double)y {
//    NSLog(@"%lf",y);
    if (!self.yLine) {
        CAShapeLayer *line = [[CAShapeLayer alloc]init];
        self.yLine = line;
        line.frame = self.view.bounds;
        line.fillColor = [UIColor lightGrayColor].CGColor;
        line.lineCap = kCALineCapButt;
        [self.view.layer addSublayer:line];
    }
    CGPoint center = self.centerView.center;
    
    if (y < -0.01) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(center.x - LINE_WIDTH/2, center.y + LINE_WIDTH, LINE_WIDTH , -y*self.maxWidth)];
        self.yLine.path = path.CGPath;
    }else if (y > 0.01){
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(center.x - LINE_WIDTH/2, center.y - LINE_WIDTH,LINE_WIDTH, -y*self.maxWidth)];
        self.yLine.path = path.CGPath;
    }else {
        self.yLine.path = NULL;
    }
}

@end
