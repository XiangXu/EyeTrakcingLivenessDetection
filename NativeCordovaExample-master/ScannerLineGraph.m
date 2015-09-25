//
//  ScannerLineGraph.m
//  FaceDetection
//
//  Created by XiangXu on 16/07/2014.
//  Copyright (c) 2014 XiangXu. All rights reserved.
//

#import "ScannerLineGraph.h"

@implementation ScannerLineGraph

-(id)initWithFrame:(CGRect)frame byImageView:(UIImageView *)view
{
    self = [super initWithFrame:frame];
    
    if(self)
    {
        self.imageView = view;
    }
    return self;
}

-(void)cancelAllAnimation
{
    [self.layer removeAllAnimations];
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 12.0);
    CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
  
    CGContextBeginPath(context);
    
    //First line is used to set start point point and second line is used to set end point position.
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, self.imageView.frame.size.height, 0);
    
    CGContextStrokePath(context);
}

-(void)scannerMove
{
    
    [UIView animateWithDuration:2.5 delay:0 options:(UIViewAnimationOptionRepeat) animations:^
     {
         self.transform = CGAffineTransformMakeTranslation(0, self.imageView.frame.size.height);
     }
     
                     completion:^(BOOL finished)
     {
         self.transform = CGAffineTransformMakeTranslation(0, -self.imageView.frame.size.height);
     }];

}

@end
