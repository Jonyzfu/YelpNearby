//
//  ViewController.m
//  YelpNearby
//
//  Created by Behera, Subhransu on 12/5/13.
//  Copyright (c) 2013 Subh. All rights reserved.
//

#import "ViewController.h"
#import "Restaurant.h"
#import "ResultTableViewCell.h"



const unsigned char SpeechKitApplicationKey[] = {0x8a, 0xa8, 0x4a, 0x2c, 0x21, 0xa7, 0x57, 0x9a, 0xfe, 0x9d, 0x13, 0x89, 0xd3, 0x6c, 0x5f, 0x02, 0x02, 0xd7, 0x69, 0x53, 0x2a, 0x2e, 0xb1, 0x8b, 0x35, 0x88, 0x8f, 0x41, 0x42, 0xb8, 0x91, 0xcc, 0x60, 0xdb, 0xf8, 0x82, 0x82, 0x50, 0x1c, 0x80, 0xed, 0x2f, 0x09, 0xc0, 0x9b, 0x69, 0xc2, 0x9e, 0x40, 0x2c, 0xf1, 0x6a, 0x5a, 0xa3, 0xf5, 0x90, 0x2b, 0x84, 0xd1, 0x6d, 0x3c, 0x62, 0x39, 0x9d};

@interface ViewController ()

@end


@implementation ViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.messageLabel.text = @"Tap on the mic";
    self.activityIndicator.hidden = YES;
    
    if (!self.tableViewDisplayDataArray) {
        self.tableViewDisplayDataArray = [[NSMutableArray alloc] init];
    }
    
    self.appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [self.appDelegate updateCurrentLocation];
    // [self.appDelegate setupSpeechKitConnection];
    
    
    self.searchTextField.returnKeyType = UIReturnKeySearch;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



    
# pragma mark - TableView Datasource and Delegate methods
    
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableViewDisplayDataArray count];
}
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ResultTableViewCell *cell = (ResultTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchResultTableViewCell"];
    
    Restaurant *restaurantObj = (Restaurant *)[self.tableViewDisplayDataArray objectAtIndex:indexPath.row];
    
    cell.nameLabel.text = restaurantObj.name;
    cell.addressLabel.text = restaurantObj.address;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *thumbImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:restaurantObj.thumbURL]];
        NSData *ratingImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:restaurantObj.ratingURL]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.thumbImage.image = [UIImage imageWithData:thumbImageData];
            cell.ratingImage.image = [UIImage imageWithData:ratingImageData];
        });
    });
    
    return cell;
}
    
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Restaurant *restaurantObj = (Restaurant *)[self.tableViewDisplayDataArray objectAtIndex:indexPath.row];
    
    if (restaurantObj.yelpURL) {
        UIApplication *app = [UIApplication sharedApplication];
        [app openURL:[NSURL URLWithString:restaurantObj.yelpURL]];
    }
}

# pragma mark - Textfield Delegate Method and Method to handle Button Touch-up Event

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self.searchTextField isFirstResponder]) {
        [self.searchTextField resignFirstResponder];
    }
    
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([self.searchTextField isFirstResponder]) {
        [self.searchTextField resignFirstResponder];
    }
}

# pragma mark - when record button is tapped

- (IBAction)recordButtonTapped:(id)sender {
    self.recordButton.selected = !self.recordButton.isSelected;
    
    // This will initialize a new speech recognizer instance
    if (self.recordButton.isSelected) {
//        self.voiceSearch = [[SKRecognizer alloc] initWithType:SKSearchRecognizerType
//                                                    detection:SKShortEndOfSpeechDetection
//                                                     language:@"eng_USA"
//                                                     delegate:self];
        self.isVoiceSearch = [[ISSpeechRecognition alloc] init];
        [self.isVoiceSearch setDelegate:self];
        
        NSError *error;
        
        if (![self.isVoiceSearch listenAndRecognizeWithTimeout:10 error:&error]) {
            self.recordButton.selected = NO;
            self.messageLabel.text = @"Time Out";
            self.activityIndicator.hidden = YES;
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Time Out"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        
    }
    else {
        if (self.isSpeaking) {
            [self.synthesis cancel];
            self.isSpeaking = NO;
        }
//        if (self.voiceSearch) { // This will stop existing speech recognizer processes
//            [self.voiceSearch stopRecording];
//            [self.voiceSearch cancel];
//        }
    }
}

- (void)recognition:(ISSpeechRecognition *)speechRecognition didGetRecognitionResult:(ISSpeechRecognitionResult *)result {
    self.searchTextField.text = [result text];
    self.recordButton.selected = !self.recordButton.isSelected;
    
    // This will extract category filter from search text
    NSString *yelpCategoryFilter = [self getYelpCategoryFromSearchText];
    
    // This will find nearby restaurants by category
    [self findNearByRestaurantsFromYelpbyCategory:yelpCategoryFilter];
}

- (void)recognition:(ISSpeechRecognition *)speechRecognition didFailWithError:(NSError *)error {
    self.recordButton.selected = NO;
    self.messageLabel.text = @"Connection Error";
    self.activityIndicator.hidden = YES;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)recognitionDidBeginRecording:(ISSpeechRecognition *)speechRecognition {
    self.messageLabel.text = @"Listening...";
    
}

- (void)recognitionDidFinishRecording:(ISSpeechRecognition *)speechRecognition {
    self.messageLabel.text = @"Done Listening.";
}

# pragma mark - SKRecognizer Delegate Methods

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithResults:(SKRecognition *)results {
    long numOfResults = [results.results count];
    
    if (numOfResults > 0) {
        // update the text of text field with the best result from SpeechKit
        self.searchTextField.text = [results firstResult];
    }
    
    self.recordButton.selected = !self.recordButton.isSelected;
    
    if (self.voiceSearch) {
        [self.voiceSearch cancel];
    }
}

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithError:(NSError *)error suggestion:(NSString *)suggestion {
    self.recordButton.selected = NO;
    self.messageLabel.text = @"Connection Error";
    self.activityIndicator.hidden = YES;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

# pragma mark - Yelp Searching Methods

- (NSString *)getYelpCategoryFromSearchText {
    NSString *categoryFilter;
    if ([[self.searchTextField.text componentsSeparatedByString:@" restaurant"] count] > 1) {
        NSCharacterSet *separator = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSArray *trimmedWordArray = [[[self.searchTextField.text componentsSeparatedByString:@"restaurant"] firstObject] componentsSeparatedByCharactersInSet:separator];
        
        if ([trimmedWordArray count] > 2) {
            int objectIndex = (int)[trimmedWordArray count] - 2;
            categoryFilter = [trimmedWordArray objectAtIndex:objectIndex];
        } else {
            categoryFilter = [trimmedWordArray objectAtIndex:0];
        }
    } else if (([[self.searchTextField.text componentsSeparatedByString:@" restaurant"] count] <= 1) && self.searchTextField.text && self.searchTextField.text.length > 0) {
        categoryFilter = self.searchTextField.text;
    }
    
    return categoryFilter;
}


- (void)findNearByRestaurantsFromYelpbyCategory:(NSString *)categoryFilter {
    // CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
     if (categoryFilter && categoryFilter.length > 0) {
        if (([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied)
            && self.appDelegate.currentUserLocation &&
            self.appDelegate.currentUserLocation.coordinate.latitude) {
            [self.tableViewDisplayDataArray removeAllObjects];
            [self.resultTableView reloadData];
            
            self.messageLabel.text = @"Fetching results...";
            self.activityIndicator.hidden = NO;
            
            self.yelpService = [[YelpAPIService alloc] init];
            self.yelpService.delegate = self;
            
            self.searchCriteria = categoryFilter;
            
            [self.yelpService searchNearByRestaurantsByFilter:[categoryFilter lowercaseString]
                                                   atLatitude:self.appDelegate.currentUserLocation.coordinate.latitude
                                                 andLongitude:self.appDelegate.currentUserLocation.coordinate.longitude];
            
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location is Disabled"
                                                            message:@"Enable it in settings and try again"delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
     }
}

- (void)loadResultWithDataArray:(NSArray *)resultArray {
    self.messageLabel.text = @"Tap on the mic";
    self.activityIndicator.hidden = YES;
    
    self.tableViewDisplayDataArray = [resultArray mutableCopy];
    [self.resultTableView reloadData];
    
    if (self.isSpeaking) {
        [self.synthesis cancel];
    }
    
    self.isSpeaking = YES;
    
    self.synthesis.delegate = self;
    if ([self.tableViewDisplayDataArray count] > 0) {
        
        self.synthesis = [[ISSpeechSynthesis alloc] initWithText:[NSString stringWithFormat:@"I found %lu %@ restaurants",(unsigned long)[self.tableViewDisplayDataArray count],self.searchCriteria]];
        NSError *error;
        if ([self.synthesis speak:&error]) {
            if (self.isSpeaking) {
                [self.synthesis cancel];
            }
            self.isSpeaking = NO;
        }
    } else {
        self.synthesis = [[ISSpeechSynthesis alloc] initWithText:[NSString stringWithFormat:@"I could not find any %@ restaurants",self.searchCriteria]];
        NSError *error;
        if ([self.synthesis speak:&error]) {
            if (self.isSpeaking) {
                [self.synthesis cancel];
            }
            self.isSpeaking = NO;
        }
    }
    
}

@end
