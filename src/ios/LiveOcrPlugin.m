#import "LiveOcrPlugin.h"
#import "AROverlayViewController.h"

@implementation LiveOcrPlugin
@synthesize callbackID;

- (void) recognizeText:(CDVInvokedUrlCommand*)command { 

    self.callbackID = command.callbackId;

    NSLog(@"starting scanner");
    AROverlayViewController *controller = [[AROverlayViewController alloc] initWithNibName:@"AROverlayViewController" bundle:nil];
    [controller setNumberRecognizedHandler:^(NSString *number){
    // Create Plugin Result
    CDVPluginResult* pluginResultSuccess = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsString: number ];
    CDVPluginResult* pluginResultError = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                 messageAsString: @"Der Code konnte leider nicht erkannt werden!" ];
    
        if (number == nil
        || ([number respondsToSelector:@selector(length)]
            && [(NSData *)number length] == 0)
        || ([number respondsToSelector:@selector(count)]
            && [(NSArray *)number count] == 0))
    {
        // Call  the Failure Javascript function
        [self.commandDelegate sendPluginResult:pluginResultError callbackId:self.callbackID];
    } else
    {
        // Call  the Success Javascript function
        [self.commandDelegate sendPluginResult:pluginResultSuccess callbackId:self.callbackID];
    }
    
    }];
    [self.viewController presentViewController:controller animated:YES completion:nil];
}

@end