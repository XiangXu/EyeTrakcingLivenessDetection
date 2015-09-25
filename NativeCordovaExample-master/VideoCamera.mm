//
//  videoCamera.m
//  FaceDetection
//
//  Created by XiangXu on 14/07/2014.
//  Copyright (c) 2014 XiangXu. All rights reserved.
//

#import "VideoCamera.h"
#import <AssetsLibrary/AssetsLibrary.h>
#include "opencv2/highgui/highgui.hpp"

NSString *face_cascade_name = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
cv::CascadeClassifier face_cascade;
cv::Mat skinCrCbHist = cv::Mat::zeros(cv::Size(256, 256), CV_8UC1);

cv::Point eyesPosition[2];
cv::Rect eyesRegion[2];
cv::Point regionCentre[2];

@interface VideoCamera()
{
    int randNum;
    int counter;
    
    bool changeDot;
    
    CLLocationManager *locationManager;
    NSString *longitude;
    NSString *latitude;
    NSString *imageString;
    
    bool didFinishLocation;
    
    NSMutableData *_responseData;
}

@property (nonatomic, retain) CvVideoCamera *videoCamera;
//@property (nonatomic,strong) ScannerLineGraph *scannerLine;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;
@property (strong, nonatomic) UIImage *faceImage;

@property (strong, nonatomic) UIAlertView *errorCameraOpen;
@property (strong, nonatomic) UIAlertView *errorAlert;
@property (strong, nonatomic) UIAlertView *noImageMatchedAlert;

@property (strong, nonatomic) NSDictionary *jsonDictionary;
@property (strong, nonatomic) NSData *requestData;
@property (strong, nonatomic) UIAlertView *netWorkError;
@property (strong, nonatomic) NSDictionary *responseFromServer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIcon;
@property (strong, nonatomic) NSMutableURLRequest *request;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatus;
@property (strong,nonatomic) NSURLConnection *connection;

@end

@implementation VideoCamera


//Lazy initialisation
-(NSURLConnection *)connection
{
    if(!_connection)
    {
        _connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:YES];
    }
    return _connection;
}


-(NSMutableURLRequest *)request
{
    if(!_request)
    {
        _request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString: @"http://hetzner5.hiyamail.com/facelogin"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:180.0];
    }
    return _request;
}

-(UIAlertView *)noImageMatchedAlert
{
    if(!_noImageMatchedAlert)
    {
        _noImageMatchedAlert = [[UIAlertView alloc] initWithTitle:@"Result" message:@"Sorry, no face image matched." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    }
    return _noImageMatchedAlert;
}

-(UIAlertView *)netWorkError
{
    if(!_netWorkError)
    {
        _netWorkError = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sorry, cannot connect to Server. Please try again later." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        
    }
    return _netWorkError;
}

-(UIAlertView *)errorAlert
{
    if(!_errorAlert)
    {
        _errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to Get Your Location. Please check your internet or please allow our app to use your current location in Sittings." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    }
    return _errorAlert;
}
-(UIAlertView *)errorCameraOpen
{
    if(!_errorCameraOpen)
    {
        _errorCameraOpen = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to open the front camera" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    }
    return _errorCameraOpen;
}

-(UILabel *)alertLabel
{
    if(!_alertLabel)
    {
        _alertLabel.text = @"No Face Detected";
    }
    return _alertLabel;
}

-(CvVideoCamera *)videoCamera
{
    if(!_videoCamera)
    {
        _videoCamera = [[CvVideoCamera alloc] initWithParentView: imageView];
        _videoCamera.delegate = self;
        _videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        _videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
        _videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        _videoCamera.defaultFPS = 30;
        _videoCamera.grayscaleMode = NO;
    }
    return _videoCamera;
}

//-(ScannerLineGraph *)scannerLine
//{
//    if(!_scannerLine)
//    {
//        _scannerLine = [[ScannerLineGraph alloc] initWithFrame:imageView.frame byImageView:imageView];
//
//        [_scannerLine setBackgroundColor:[UIColor clearColor]];
//
//        [imageView addSubview:_scannerLine];
//    }
//
//    return _scannerLine;
//}


//Alert button, navigate back to the login page
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //    [self.scannerLine cancelAllAnimation];
    //    self.scannerLine = nil;
    self.videoCamera = nil;
    self.connection = nil;
    self.connectionStatus.text = @"";
    
    imageView.backgroundColor = [UIColor whiteColor];
    
    //Stop loadingIcon
    self.loadingIcon.color = [UIColor whiteColor];
    self.loadingIcon.hidesWhenStopped = YES;
    [self.loadingIcon stopAnimating];
    
    self.connectionStatus.hidden = YES;
    
    if(buttonIndex == 0)
    {
        //Set up video camera
        try
        {
            [self.videoCamera start];
            //            [self.scannerLine scannerMove];
        }
        catch (NSException *error)
        {
            [self.errorCameraOpen show];
        }
    }
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    changeDot = false;
    self.connectionStatus.hidden = YES;
    
    //Stop loadingIcon
    self.loadingIcon.color = [UIColor whiteColor];
    self.loadingIcon.hidesWhenStopped = YES;
    [self.loadingIcon stopAnimating];
    
    
#ifdef __cplusplus
    if(!face_cascade.load([face_cascade_name UTF8String]))
    {
        
    }
#endif
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    imageView.backgroundColor = [UIColor whiteColor];
    counter = 0;
    
    //Set up video camera
    try
    {
        [self.videoCamera start];
        //        [self.scannerLine scannerMove];
        
    }
    catch (NSException *error)
    {
        [self.errorCameraOpen show];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.connection cancel];
    self.connection = nil;
    
    [self.videoCamera stop];
    //    [self.scannerLine cancelAllAnimation];
    //    self.scannerLine = nil;
    
    self.connectionStatus.hidden = YES;
    [self.loadingIcon stopAnimating];
    counter = 0;
}


//GPS location data fetch
-(void)getCurrentLocation : (cv::Mat&)image
{
    [self faceImageCaputre:image];
    self.connectionStatus.hidden = NO;
    self.connectionStatus.text = @"Capturing GPS";
    didFinishLocation = false;
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    
    if(IS_OS_8_OR_LATER)
    {
        [locationManager requestWhenInUseAuthorization];
    }
    
    [locationManager startUpdatingLocation];
    
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self.errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (!didFinishLocation)
    {
        didFinishLocation = YES;
        
        CLLocation *currentLocation = [locations lastObject];
        
        //Assign GPS data
        if(currentLocation != nil)
        {
            latitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
            longitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        }
        
        //Stop location manager
        [locationManager stopUpdatingLocation];
        
        [self sendDataToServer];
    }
}

//Face image capture
-(void)faceImageCaputre:(cv::Mat&)image;
{
    self.connectionStatus.text = @"Image Processing";
    //-------swap channels
    std::vector<cv::Mat> ch;
    cv::split(image,ch);
    std::swap(ch[0],ch[2]);
    cv::merge(ch,image);
    
    self.faceImage = [self imageWithCVMat:image];
    
    imageString = [UIImagePNGRepresentation(self.faceImage) base64EncodedStringWithOptions:0];
}

//Covert cvMat to UIImage
- (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                        cvMat.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * cvMat.elemSize(),                           // Bits per pixel
                                        cvMat.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

#pragma mark NSURLConnection Delegate Methods

-(void)sendDataToServer
{
    self.jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:imageString, @"imageString", latitude, @"latitude", longitude, @"longitude", nil];
    self.requestData = [NSJSONSerialization dataWithJSONObject:self.jsonDictionary options:kNilOptions error:nil];
    
    [self.request setAllowsCellularAccess:YES]; // Allow app to use celluar to send data
    [self.request setHTTPMethod: @"POST"];
    [self.request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [self.request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self.request setHTTPBody: self.requestData];
    
    self.connectionStatus.text = @"Data Sending";
    [self.connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    self.connectionStatus.text = @"Data receiving";
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to the instance variable you declared
    self.connectionStatus.text = @"Data received";
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    self.connectionStatus.text = @"Success";
    
    NSString *r = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    NSLog(@"%@",r);
    
    self.responseFromServer = [NSJSONSerialization JSONObjectWithData:_responseData options:NSJSONReadingMutableLeaves error:nil];
    NSString *serverResult = [self.responseFromServer objectForKey:@"result"];
    
    if([serverResult isEqualToString:@"true"])
    {
        counter = 0;
        
        //Passing server response from this view to phonegap view
        [[NSNotificationCenter defaultCenter] postNotificationName:@"response" object:self userInfo:self.responseFromServer];
        
        [self.loadingIcon stopAnimating];
    }
    else
    {
        counter = 0;
        [self.noImageMatchedAlert show];
        [self.loadingIcon stopAnimating];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // The request has failed for some reason!
    // Check the error var
    counter = 0;
    [self.netWorkError show];
    
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus

- (void)processImage:(cv::Mat&)image
{
    dispatch_sync(dispatch_get_main_queue(), ^
                  {
                      //After user passed liveness detection
                      if(counter == 3)
                      {
                          //Stop camera, animation and start loading icon
                          [self.loadingIcon startAnimating];
                          
                          [self.videoCamera stop];
                          //                          [self.scannerLine cancelAllAnimation];
                          counter = 0;
                          
                          //Hide alert label
                          self.alertLabel.text = @" ";
                          
                          //Change uiview background to view when send data to server
                          imageView.backgroundColor = [UIColor blackColor];
                          [self getCurrentLocation:image];
                      }
                      
                      else if([self faceDetection:image])
                      {
                          NSString *message = [NSString stringWithFormat:@"Success(3): %d", counter];
                          self.alertLabel.text = message;
                      }
                      else
                      {
                          self.alertLabel.text = @"No Face Detected";
                          counter = 0;
                      }
                  });
}

#endif

-(bool)faceDetection:(cv::Mat&)image
{
    bool faceFound = false;
    cv::vector<cv::Rect> faces;
    
    std::vector<cv::Mat>rgbChannels(3);
    cv::split(image,rgbChannels);
    cv::Mat frame_gray = rgbChannels[2];
    
    if (changeDot == true)
    {
        randNum = arc4random()%2;
        changeDot = false;
    }
    
    face_cascade.detectMultiScale(frame_gray, faces, 1.1, 2, 0 | CV_HAAR_SCALE_IMAGE, cv::Size(100, 100));
    
    for(unsigned i = 0; i < faces.size(); ++i)
    {
        rectangle(image, cv::Point(faces[i].x, faces[i].y),cv::Point(faces[i].x + faces[i].width, faces[i].y + faces[i].height),cv::Scalar(0,255,0),2);
        
        faceFound = true;
    }
    
    if(faces.size()>0)
    {
        [self findEyes:frame_gray withFace:faces[0]];
        
        // draw eyes centers
        cv::Mat faceROI = image(faces[0]);
        circle(faceROI, eyesPosition[0], 2, cv::Scalar(255,0,0),3);
        circle(faceROI, eyesPosition[1], 2, cv::Scalar(255,0,0),3);
        
        //Optimise eyes region centres position
        regionCentre[0].y = regionCentre[0].y - 7;
        regionCentre[0].x = regionCentre[0].x - 5;
        
        //draw eyes regions
        rectangle(faceROI, eyesRegion[0],cv::Scalar(0,255,0),2);
        rectangle(faceROI, eyesRegion[1],cv::Scalar(0,255,0),2);
        
        //Random change centre position
        if(randNum == 1)
        {
            regionCentre[1].x = regionCentre[1].x + 14;
            circle(faceROI, regionCentre[1], 2, cv::Scalar(0,255,0),5);
            
            if(eyesPosition[0].x >= regionCentre[1].x)
            {
                changeDot = true;
                counter++;
            }
        }
        else
        {
            regionCentre[1].x = regionCentre[1].x - 8;
            circle(faceROI, regionCentre[1], 2, cv::Scalar(0,255,0),5);
            if(eyesPosition[0].x <= regionCentre[1].x )
            {
                changeDot = true;
                counter++;
            }
        }
    }
    return faceFound;
}


-(void)findEyes:(cv::Mat)image withFace:(cv::Rect)face;
{
    cv::Mat faceROI = image(face);
    cv::Mat debugFace = faceROI;
    
    if (kSmoothFaceImage)
    {
        double sigma = kSmoothFaceFactor * face.width;
        GaussianBlur( faceROI, faceROI, cv::Size( 0, 0 ), sigma);
    }
    //-- Find eye regions and draw them
    int eye_region_width = face.width * (kEyePercentWidth/100.0);
    int eye_region_height = face.width * (kEyePercentHeight/100.0);
    int eye_region_top = face.height * (kEyePercentTop/100.0);
    
    cv::Rect leftEyeRegion(face.width*(kEyePercentSide/100.0),
                           eye_region_top,eye_region_width,eye_region_height);
    
    cv::Rect rightEyeRegion(face.width - eye_region_width - face.width*(kEyePercentSide/100.0),
                            eye_region_top,eye_region_width,eye_region_height);
    eyesRegion[0] = leftEyeRegion;
    eyesRegion[1] = rightEyeRegion;
    
    //Find Eyes region centres
    regionCentre[0] = cv::Point(face.width*(kEyePercentSide/100.0)+eye_region_width/2, eye_region_top+eye_region_height/2);
    regionCentre[1] = cv::Point(face.width - eye_region_width - face.width*(kEyePercentSide/100.0)+eye_region_width/2, eye_region_top+eye_region_height/2);
    
    //-- Finds Eye Centers
    cv::Point leftPupil = findEyeCenter(faceROI,leftEyeRegion,"Left Eye");
    cv::Point rightPupil = findEyeCenter(faceROI,rightEyeRegion,"Right Eye");
    
    // change eyes centers to face coordinates
    rightPupil.x += rightEyeRegion.x;
    rightPupil.y += rightEyeRegion.y;
    leftPupil.x += leftEyeRegion.x;
    leftPupil.y += leftEyeRegion.y;
    
    eyesPosition[0] = rightPupil;
    eyesPosition[1] = leftPupil;
    
}


@end
