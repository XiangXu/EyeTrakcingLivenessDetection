//
//  ScannerLineGraph.h
//  FaceDetection
//
//  Created by XiangXu on 16/07/2014.
//  Copyright (c) 2014 XiangXu. All rights reserved.
//  

#import <UIKit/UIKit.h>

@interface ScannerLineGraph : UIView

@property(nonatomic) UIImageView *imageView;


-(id)initWithFrame:(CGRect)frame byImageView:(UIImageView *)view;

-(void)drawRect:(CGRect)rect;

-(void)scannerMove;

-(void)cancelAllAnimation;

@end
