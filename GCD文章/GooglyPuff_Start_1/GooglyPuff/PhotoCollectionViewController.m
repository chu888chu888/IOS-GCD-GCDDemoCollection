//
//  PhotoCollectionViewController.m
//  GCDTutorial
//
//  Created by A Magical Unicorn on A Sunday Night.
//  Copyright (c) 2014 Derek Selander. All rights reserved.
//

@import AssetsLibrary;
#import "PhotoCollectionViewController.h"
#import "PhotoDetailViewController.h"
#import "ELCImagePickerController.h"

static const NSInteger kCellImageViewTag = 3;
static const CGFloat kBackgroundImageOpacity = 0.1f;

@interface PhotoCollectionViewController () <ELCImagePickerControllerDelegate,
UINavigationControllerDelegate,
UICollectionViewDataSource,
UIActionSheetDelegate>

@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, strong) UIPopoverController *popController;
@end

@implementation PhotoCollectionViewController

//*****************************************************************************/
#pragma mark - LifeCycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.library = [[ALAssetsLibrary alloc] init];
    
    // Background image setup
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
    backgroundImageView.alpha = kBackgroundImageOpacity;
    backgroundImageView.contentMode = UIViewContentModeCenter;
    [self.collectionView setBackgroundView:backgroundImageView];
   
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentChangedNotification:)
                                                 name:kPhotoManagerContentUpdateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentChangedNotification:)
                                                 name:kPhotoManagerAddedContentNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self showOrHideNavPrompt];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//*****************************************************************************/
#pragma mark - UICollectionViewDataSource Methods
//*****************************************************************************/

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = [[[PhotoManager sharedManager] photos] count];
    NSLog(@"photo count:%lu",count);
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"photoCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:kCellImageViewTag];
    NSArray *photoAssets = [[PhotoManager sharedManager] photos];
    Photo *photo = photoAssets[indexPath.row];
    
    switch (photo.status) {
        case PhotoStatusGoodToGo:
            imageView.image = [photo thumbnail];
            break;
        case PhotoStatusDownloading:
            imageView.image = [UIImage imageNamed:@"photoDownloading"];
            break;
        case PhotoStatusFailed:
            imageView.image = [UIImage imageNamed:@"photoDownloadError"];
        default:
            break;
    }
    return cell;
}

//*****************************************************************************/
#pragma mark - UICollectionViewDelegate
//*****************************************************************************/

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *photos = [[PhotoManager sharedManager] photos];
    Photo *photo = photos[indexPath.row];
    
    switch (photo.status) {
        case PhotoStatusGoodToGo: {
            UIImage *image = [photo image];
            PhotoDetailViewController *photoDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoDetailViewController"];
            [photoDetailViewController setupWithImage:image];
            [self.navigationController pushViewController:photoDetailViewController animated:YES];
            break;
        }
        case PhotoStatusDownloading: {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"下载"
                                                            message:@"图片正在下载中......"
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil, nil];
            [alert show];
            break;
        }
        case PhotoStatusFailed: //Fall through to default
        default: {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"失败"
                                                            message:@"图片创建失败........"
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }
    }
}

//*****************************************************************************/
#pragma mark - elcImagePickerControllerDelegate
//*****************************************************************************/

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    for (NSDictionary *dictionary in info) {
        NSLog(@"dictionary:%@",dictionary[UIImagePickerControllerReferenceURL] );
        
        [self.library assetForURL:dictionary[UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
            Photo *photo = [[Photo alloc] initWithAsset:asset];
            [[PhotoManager sharedManager] addPhoto:photo];
        } failureBlock:^(NSError *error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"权限拒绝"
                                                            message:@"请在设置中,保证设置正常"
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }];
    }
    
    if (isIpad()) {
        [self.popController dismissPopoverAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    if (isIpad()) {
        [self.popController dismissPopoverAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

//*****************************************************************************/
#pragma mark - IBAction Methods
//*****************************************************************************/

/// The upper right UIBarButtonItem method
- (IBAction)addPhotoAssets:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"获取图片:" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"相册", @"互联网", nil];
    [actionSheet showInView:self.view];
}

//*****************************************************************************/
#pragma mark - UIActionSheetDelegate
//*****************************************************************************/

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    static const NSInteger kButtonIndexPhotoLibrary = 0;
    static const NSInteger kButtonIndexInternet = 1;
    if (buttonIndex == kButtonIndexPhotoLibrary) {
        ELCImagePickerController *imagePickerController = [[ELCImagePickerController alloc] init];
        [imagePickerController setImagePickerDelegate:self];
        
        if (isIpad()) {
            if (![self.popController isPopoverVisible]) {
                self.popController = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
                
                [self.popController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        } else {
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
    } else if (buttonIndex == kButtonIndexInternet) {
        [self downloadImageAssets];
    }
}

//*****************************************************************************/
#pragma mark - Private Methods
//*****************************************************************************/

- (void)contentChangedNotification:(NSNotification *)notification
{
    [self.collectionView reloadData];
    [self showOrHideNavPrompt];
}

- (void)showOrHideNavPrompt
{
    // Implement me!
}

- (void)downloadImageAssets
{
    [[PhotoManager sharedManager] downloadPhotosWithCompletionBlock:^(NSError *error) {
        
        // This completion block currently executes at the wrong time
        NSString *message = error ? [error localizedDescription] : @"图片已经从互联网中下载完成....";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载完成"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }];
}

@end
