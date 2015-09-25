//
//  videoCamera.h
//  FaceDetection
//
//  Created by XiangXu on 14/07/2014.
//  Copyright (c) 2014 XiangXu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#include <opencv2/highgui/cap_ios.h>
#include <opencv2/highgui/highgui_c.h>
#include <opencv2/imgproc/imgproc_c.h>
#include <opencv2/objdetect/objdetect.hpp>

#import "ScannerLineGraph.h"
#import "constants.h"
#import "findEyeCenter.h"
#import "findEyeCorner.h"


@interface VideoCamera : UIViewController<CvVideoCameraDelegate, CLLocationManagerDelegate, NSURLConnectionDelegate>
{
    IBOutlet UIImageView *imageView;
}

@end
