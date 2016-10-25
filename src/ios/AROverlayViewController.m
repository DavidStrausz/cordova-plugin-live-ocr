#import "AROverlayViewController.h"

@interface AROverlayViewController ()

- (CGRect)getAbsoluteRect:(CGRect)rect;

@end

@implementation AROverlayViewController

@synthesize captureManager;
@synthesize resultLabel;
@synthesize begincapture;
@synthesize captureFrameScreen;
@synthesize imageView;
@synthesize customLayer;
@synthesize tesseract;
@synthesize tesseractReady;

- (void)closeButtonClicked:(UIButton *)button {
    tesseractReady = false;
    captureManager = nil;
    resultLabel = nil;
    begincapture = nil;
    imageView = nil;
    customLayer = nil;
    //tesseract = nil; -> this caused malloc_error_break exception in some cases
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {  
    self.customLayer = [CALayer layer];
    self.customLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.customLayer];
    
    // 'Scan'-rectangle and abort button
    captureFrameScreen = [self getAbsoluteRect:CGRectMake(0.125, 0.30, 0.75, 0.08)];
    CGRect closeButtonRect = [self getAbsoluteRect:CGRectMake(0.33, 0.87, 0.33, 0.07)];

    // Debuglabels
    CGRect resultlabelRect = [self getAbsoluteRect:CGRectMake(0.25, 0.0625, 0.5, 0.039)];
    CGRect imageViewRect = [self getAbsoluteRect:CGRectMake(0.125, 0.78125, 0.625, 0.078125)];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:closeButtonRect];
    [closeButton setTitle:@"Abbrechen" forState:UIControlStateNormal];
    [closeButton setBackgroundColor:[UIColor colorWithRed:0.0/255.0 green:78.0/255.0 blue:135.0/255.0 alpha:0.85]];
    closeButton.layer.cornerRadius = 5;
    closeButton.clipsToBounds = YES;
    [closeButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [[self view] addSubview:closeButton];
        
    UILabel *frameLabel = [[UILabel alloc] initWithFrame:captureFrameScreen];
    frameLabel.layer.borderColor = [UIColor blackColor].CGColor;
    frameLabel.layer.borderWidth = 1.5;
    [frameLabel setBackgroundColor:[UIColor clearColor]];
    [[self view] addSubview:frameLabel];
    
    self.imageView = [[UIImageView alloc] initWithFrame:imageViewRect];
    [imageView setBackgroundColor:[UIColor whiteColor]];
    
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:resultlabelRect];
    [self setResultLabel:tempLabel];
    [resultLabel setBackgroundColor:[UIColor whiteColor]];
    [resultLabel setFont:[UIFont fontWithName:@"Courier" size: 18.0]];
    [resultLabel setTextColor:[UIColor redColor]];
    [resultLabel setText:@""];
    [resultLabel setTextAlignment:NSTextAlignmentCenter];

    // Uncomment these lines for Debugging OCR
    /*[[self view] addSubview:self.imageView];
    
    [[self view] addSubview:resultLabel];*/
    
    tesseract = [[G8Tesseract alloc] initWithLanguage:@"por"];
    tesseract.delegate = self;
    
    //[tesseract setVariableValue:@"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ" forKey:@"tessedit_char_whitelist"];
    //[tesseract setVariableValue:@"0123456789*" forKey:@"tessedit_char_whitelist"];

    tesseractReady = false;
    
    [self setCaptureManager:[[CaptureSessionManager alloc] init]];
    [self.captureManager setupCapture:^(UIImage* image) {
        if (tesseractReady) {
            tesseractReady = false;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [self recognizeImageWithTesseract:image];
            });
        }
    } previewLayer:customLayer];
  }

- (void)viewDidAppear:(BOOL)animated {
    self.customLayer.frame = self.view.bounds;    
    tesseractReady = true;
}

- (void)setNumberRecognizedHandler:(numberRecognizedHandler)thehandler {
    self.handler = thehandler;
}

-(void)recognizeImageWithTesseract:(UIImage *)img {
    // captureFrameScreen = The Rectangle on the screen
    // cropRect = The Rectangle on the picture where we want to do OCR
    
    // captureFrameImage Needs to be the Frame in the Picture that resembles the one on screen, adjusted for its different size
    // because, e.g. iPad2 Resolution is 768x1024, but the captured images are 720x1280
    
    CGRect cropRect;
    CGSize imgSize = img.size;
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;

    
    float ratiox = imgSize.width / screenSize.width;
    float ratioy = imgSize.height / screenSize.height;
    
    cropRect = CGRectMake(captureFrameScreen.origin.x * ratiox, captureFrameScreen.origin.y * ratioy, captureFrameScreen.size.width * ratiox, captureFrameScreen.size.height * ratioy);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], cropRect);
    
    CIContext *context = [CIContext contextWithOptions:nil]; // 1
    CIImage *ciImage = [CIImage imageWithCGImage:imageRef]; // 2
    CIFilter *filter = [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:@"inputImage", ciImage, @"inputColor", [CIColor colorWithRed:1.f green:1.f blue:1.f alpha:1.0f], @"inputIntensity", [NSNumber numberWithFloat:1.f], nil]; // 3
    CIImage *ciResult = [filter valueForKey:kCIOutputImageKey]; // 4
    CGImageRef cgImage = [context createCGImage:ciResult fromRect:[ciResult extent]];
    img = [UIImage imageWithCGImage:cgImage];
    
    // img = [self resizeImage:[[UIImage imageWithCGImage:imageRef] blackAndWhite] scale:0.5];
    CGImageRelease(imageRef);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[self imageView] setImage:img];
    });
 
    [tesseract setImage:img];
    [tesseract recognize];
    
    NSString *recognizedText = [tesseract recognizedText];
    NSString *validNumber = [self getValidNumber:recognizedText];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [resultLabel setText:validNumber];
        if (validNumber != nil && self.handler) {
            self.handler(validNumber);
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    });
    
    if (validNumber != nil && self.handler) {
        tesseractReady = false;
    } else {
        tesseractReady = true;
    }
}

// - (UIImage *)resizeImage:(UIImage *)original scale:(CGFloat)scale
// {
//     // Calculate new size given scale factor.
//     CGSize originalSize = original.size;
//     CGSize newSize = CGSizeMake(originalSize.width * scale, originalSize.height * scale);
    
//     // Scale the original image to match the new size.
//     UIGraphicsBeginImageContext(newSize);
//     [original drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
//     UIImage* compressedImage = UIGraphicsGetImageFromCurrentImageContext();
//     UIGraphicsEndImageContext();
    
//     return compressedImage;
// }

- (NSString *)getValidNumber:(NSString *)text {
    NSLog(@"%s:%d text=%@", __func__, __LINE__, text);
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"X"];
    
    NSString *numbers = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *numberPart;
    
    NSCharacterSet *numberset = [NSCharacterSet decimalDigitCharacterSet];
    
    if ([numbers length] >= 16) {
        
        for (int i = 0; i <= [numbers length] - 16; i++) {
            numberPart = [numbers substringWithRange:NSMakeRange(i, 16)];
            
            if (![numberset isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:numberPart]]) {
                continue;
            }

            if ([self luhnTest:numberPart]) {
                NSLog(@"%s:%d numberPart=%@", __func__, __LINE__, numberPart);
                return numberPart;
            }
        }
        
    }    
    return nil;
}

- (Boolean)luhnTest:(NSString *)string {
    NSMutableString *reversedString = [NSMutableString stringWithCapacity:[string length]];
    
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length]) options:(NSStringEnumerationReverse |NSStringEnumerationByComposedCharacterSequences) usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        [reversedString appendString:substring];
    }];
    
    NSUInteger oddSum = 0, evenSum = 0;
    
    for (NSUInteger i = 0; i < [reversedString length]; i++) {
        NSInteger digit = [[NSString stringWithFormat:@"%C", [reversedString characterAtIndex:i]] integerValue];
        
        if (i % 2 == 0) {
            evenSum += digit;
        }
        else {
            oddSum += digit / 5 + (2 * digit) % 10;
        }
    }
    return (oddSum + evenSum) % 10 == 0;
}

// - (void)hideLabel:(UILabel *)label {
//     [label setHidden:YES];
// }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    self.captureManager = nil;
    resultLabel = nil;
}

// - (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    
// }

- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract*)tesseract {
    // Due to the continuous mode we may accidently take a picture that takes very long to process
    // in that case cancel the recognition
    if ([begincapture timeIntervalSinceNow] < -2) {
        return YES;
    }
    return NO;
}

- (CGRect)getAbsoluteRect:(CGRect)rect {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    return CGRectMake(rect.origin.x * screenWidth, rect.origin.y * screenHeight, rect.size.width * screenWidth, rect.size.height * screenHeight);
}

@end