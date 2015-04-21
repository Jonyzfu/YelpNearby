//
//  ViewController.h
//  YelpNearby
//
//  Created by Behera, Subhransu on 12/5/13.
//  Copyright (c) 2013 Subh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <SpeechKit/SpeechKit.h>
#import "iSpeechSDK.h"
#import "YelpAPIService.h"


@interface ViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, SpeechKitDelegate, SKRecognizerDelegate, iSpeechSDKDelegate, ISSpeechRecognitionDelegate, YelpAPIServiceDelegate, ISSpeechSynthesisDelegate>

@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
    
@property (weak, nonatomic) IBOutlet UITableView *resultTableView;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSMutableArray *tableViewDisplayDataArray;

@property (strong, nonatomic) SKRecognizer *voiceSearch;
@property (strong, nonatomic) ISSpeechRecognition *isVoiceSearch;
@property (strong, nonatomic) ISSpeechSynthesis *synthesis;
@property BOOL isSpeaking;

@property (strong, nonatomic) YelpAPIService *yelpService;
@property (strong, nonatomic) NSString *searchCriteria;

- (IBAction)recordButtonTapped:(id)sender;

@end
