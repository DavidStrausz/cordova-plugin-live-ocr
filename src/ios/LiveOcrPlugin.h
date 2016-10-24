#import <Cordova/CDV.h>

@interface LiveOcrPlugin : CDVPlugin 
@property (nonatomic, copy) NSString* callbackID;

- (void) recognizeText:(CDVInvokedUrlCommand*)command;

@end