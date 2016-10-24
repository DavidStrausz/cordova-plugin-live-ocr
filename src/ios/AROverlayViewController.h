#import <UIKit/UIKit.h>
#import <TesseractOCR/TesseractOCR.h>
#import <TesseractOCR/G8TesseractDelegate.h>
#import "CaptureSessionManager.h"

@interface AROverlayViewController : UIViewController <G8TesseractDelegate, UINavigationControllerDelegate>

typedef void (^numberRecognizedHandler)(NSString *number);

- (Boolean)luhnTest:(NSString *)string;
- (void)setNumberRecognizedHandler:(numberRecognizedHandler)handler;

@property (copy) numberRecognizedHandler handler;
@property (retain) CaptureSessionManager *captureManager;
@property (nonatomic, retain) UILabel *resultLabel;
@property (nonatomic, retain) UIImageView *imageView;

@property (retain) NSDate *begincapture;

@property CGRect captureFrameScreen;

@property (nonatomic, strong) CALayer *customLayer;

@property (retain) G8Tesseract *tesseract;

@property Boolean tesseractReady;

@end
