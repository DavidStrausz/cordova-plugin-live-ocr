#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>


@interface CaptureSessionManager : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

typedef void (^imageHandler)(UIImage *image);

@property (retain) CALayer *previewLayer;
@property (retain) AVCaptureSession *captureSession;
@property (copy) imageHandler handler;

- (void)setupCapture:(imageHandler)thehandler previewLayer:(CALayer *)thelayer;
- (UIImage *) rotateImage:(UIImage *)image;

@end