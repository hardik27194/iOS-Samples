//
//  ImagePreviewViewController.m
//  backendlessDemos
/*
 * *********************************************************************************************************************
 *
 *  BACKENDLESS.COM CONFIDENTIAL
 *
 *  ********************************************************************************************************************
 *
 *  Copyright 2012 BACKENDLESS.COM. All Rights Reserved.
 *
 *  NOTICE: All information contained herein is, and remains the property of Backendless.com and its suppliers,
 *  if any. The intellectual and technical concepts contained herein are proprietary to Backendless.com and its
 *  suppliers and may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade secret
 *  or copyright law. Dissemination of this information or reproduction of this material is strictly forbidden
 *  unless prior written permission is obtained from Backendless.com.
 *
 *  ********************************************************************************************************************
 */

#define IS_INDEPENDENCE_VERSION 0

#import "ImagePreviewViewController.h"
#import "BEFile.h"
#import "Backendless.h"
#import "SuccessViewController.h"
#import "BrowseViewController.h"

@interface ImagePreviewViewController ()
- (void)showAlert:(NSString *)message;
- (void)saveEntityWithName:(NSString *)path;
- (void)prepareView;
@end

@implementation ImagePreviewViewController

@synthesize mainImageView, uploadBtn, urlLable, mainImage, isUpload, file, pathField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareView];
	
	// Do any additional setup after loading the view.
}
- (void)prepareView
{
    mainImageView.image = mainImage;
    if (isUpload) {
        [uploadBtn setTitle:@"remove" forState:UIControlStateNormal];
    }
    else{
        [uploadBtn setTitle:@"upload" forState:UIControlStateNormal];
    }
    urlLable.text = file.path;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)showAlert:(NSString *)message {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error:" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [av show];
}

- (void)saveEntityWithName:(NSString *)path
{
    @try {
        file = [BEFile new];
        file.path = path;
        [backendless.persistenceService save:file];
    }
    @catch (Fault *fault)
    {
        NSLog(@"ImageViewController -> saveEntityWithIndex: FAULT = %@", fault);
        [self showAlert:fault.message];
    }
    @finally {
        
    }
}

- (void)upload:(id)sender
{
    @try {
        
        NSLog(@"ImageViewController -> upload: ");
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        if (isUpload)
        {
            [backendless.fileService remove:[NSString stringWithFormat:@"img/%@", [[file.path pathComponents] lastObject]]];
            [backendless.persistenceService remove:[BEFile class] sid:file.objectId];
            file = nil;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Image has been deleted" delegate:nil cancelButtonTitle:@"Done" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            
#if 1 // image file
            NSString *fileName = [NSString stringWithFormat:@"img/%0.0f.jpeg",[[NSDate date] timeIntervalSince1970] ];
#if IS_INDEPENDENCE_VERSION // use saveFile method
            BackendlessFile *uploadFile = [backendless.fileService saveFile:fileName content:UIImageJPEGRepresentation(mainImage, 0.1)];
#else // use upload method
            BackendlessFile *uploadFile = [backendless.fileService upload:fileName content:UIImageJPEGRepresentation(mainImage, 0.1)];
#endif
#else // binary array file (test)
            const char myByteArray[] = {0x12,0x23,0x34,0x45,0x56,0x67,0x78,0x89,0x12,0x23,0x34,0x45,0x56,0x67,0x78,0x89};
            NSData *data = [NSData dataWithBytes:myByteArray length:sizeof(myByteArray)];
            BackendlessFile *uploadFile = [backendless.fileService saveFile:@"binary101.bin" content:data overwriteIfExist:YES];
#endif
            [self saveEntityWithName:uploadFile.fileURL];
        }
        isUpload = !isUpload;
    }
    @catch (Fault *fault)
    {
        NSLog(@"ImageViewController -> upload: FAULT = %@", fault);
        [self showAlert:fault.message];
    }
    @finally {
        
        [self prepareView];
        if (isUpload)
        {
            SuccessViewController *success = (SuccessViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"SuccessViewController"];
            success.url = file.path;
            [self presentViewController:success animated:YES completion:^{}];
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}
#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
@end