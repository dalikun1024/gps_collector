//
//  ViewController.m
//  gps_collector
//
//  Created by likun on 2023/1/29.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()<CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSString *gpsDataPath;
@property (nonatomic) NSString *gpsFolderPath;
@property (nonatomic) BOOL recording;
@property (nonatomic) UIImage *startIcon;
@property (nonatomic) UIImage *stopIcon;
@property (nonatomic) UIButton *recordButton;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // initial locationManager
    [self locationManagerInit];
    [self UIInit];
}

- (void) locationManagerInit{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.activityType    = CLActivityTypeAutomotiveNavigation;
    self.locationManager.distanceFilter  = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    if (self.locationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
}

- (void)UIInit {
    self.recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.recordButton addTarget:self
               action:@selector(recordAction:)
     forControlEvents:UIControlEventTouchUpInside];
    [self.recordButton setTitle:@"Show View" forState:UIControlStateNormal];
    
    self.recordButton.frame = CGRectMake(self.view.frame.size.width / 2 - 25.0, self.view.frame.size.height - 100, 50.0, 50.0);
    self.startIcon = [UIImage imageNamed:@"record.png"];
    self.stopIcon = [UIImage imageNamed:@"stop.png"];
    [self.recordButton setImage:self.startIcon forState:UIControlStateNormal];
    self.recording = NO;
    [self.view addSubview:self.recordButton];
    
    NSLog(@"button size: %f %f", self.recordButton.frame.size.width, self.recordButton.frame.size.height);
    NSLog(@"frame size: %f %f", self.view.frame.size.width, self.view.frame.size.height);
    NSLog(@"size: %f %f  stop: %f %f", self.startIcon.size.width, self.startIcon.size.height, self.stopIcon.size.width, self.stopIcon.size.height);
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    NSTimeInterval old_seconds = [oldLocation.timestamp timeIntervalSince1970];
    double old_ms = old_seconds*1000;
    NSTimeInterval new_seconds = [newLocation.timestamp timeIntervalSince1970];
    double new_ms = new_seconds*1000;
    NSLog(@"old location is %f, %f, %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude, old_ms);
    NSLog(@"new location is %f,%f",newLocation.coordinate.latitude, newLocation.coordinate.longitude );
    NSLog(@"time interval: %f", new_ms - old_ms);
    if (self.recording) {
        [self getWSGLikeCoordinate:newLocation];
    }
}

- (void)createDir {
    NSString *document_path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    self.gpsFolderPath = [document_path stringByAppendingPathComponent:@"gps_data"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = YES;
    BOOL existed = [fileManager fileExistsAtPath:self.gpsFolderPath isDirectory:&isDir];
    if (!existed) {
        [fileManager createDirectoryAtPath:self.gpsFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
    NSString *currentDateString = [dateFormatter stringFromDate:currentDate];
    NSLog(@"%@",currentDateString);
    self.gpsDataPath = [currentDateString stringByAppendingPathExtension:@"txt"];
    self.gpsDataPath = [self.gpsFolderPath stringByAppendingPathComponent:self.gpsDataPath];
    if ([fileManager fileExistsAtPath:self.gpsDataPath]) {
        [fileManager removeItemAtPath:self.gpsDataPath error:nil];
    }
    [fileManager createFileAtPath:self.gpsDataPath contents:nil attributes:nil];

}

- (double) degreeToRadians:(double)degree {
    double radians = degree / 180.0 * M_PI;
    return radians;
}

- (void) getWSGLikeCoordinate:(CLLocation *)location {
    double earth_radius = 6371000; //unit with meter
    double z = sin([self degreeToRadians:location.coordinate.latitude]) * earth_radius;
    double r = cos([self degreeToRadians:location.coordinate.latitude]) * earth_radius;
    double x = cos([self degreeToRadians:location.coordinate.longitude]) * r;
    double y = sin([self degreeToRadians:location.coordinate.longitude]) * r;
    
    NSLog(@"wsglike coord: x: %f, y: %f, z: %f", x, y, z);
    
    NSTimeInterval time_seconds = [location.timestamp timeIntervalSince1970];
    double time_ms = time_seconds*1000;
    
    NSString *gps_str = [NSString stringWithFormat:@"%f %f %f %f %f %f\n",time_ms, location.coordinate.latitude, location.coordinate.longitude, x, y, z];
//    NSString *path = [self.gpsFolderPath stringByAppendingPathComponent:self.gpsDataPath];
    
    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:self.gpsDataPath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[gps_str dataUsingEncoding:NSUTF8StringEncoding]];
}

- (IBAction)recordAction:(id)sender {
    NSLog(@"recordAction");
    self.recording = !self.recording;
    if (self.recording) {
        // begin to record gps data
        [self createDir];
        [self.recordButton setImage:self.stopIcon forState:UIControlStateNormal];
    } else {
        [self.recordButton setImage:self.startIcon forState:UIControlStateNormal];
    }
}



@end
