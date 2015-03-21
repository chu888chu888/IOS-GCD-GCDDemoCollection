//
//  PhotoCollectionViewController.m
//  GCDDemoError
//
//  Created by chuguangming on 15/3/21.
//  Copyright (c) 2015年 chu. All rights reserved.
//

#import "PhotoCollectionViewController.h"
#import "PhotoManager.h"
#import "Utils.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCImagePickerController.h"
#import "KMMoviePosterCell.h"
#define kVerticalMarginForCollectionViewItems 0
#define fDeviceWidth [UIScreen mainScreen].bounds.size.width
#define fDeviceHeight [UIScreen mainScreen].bounds.size.height
static const NSInteger kCellImageViewTag = 3;
static const CGFloat kBackgroundImageOpacity = 0.1f;
@interface PhotoCollectionViewController ()
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, strong) UIPopoverController *popController;
@end

@implementation PhotoCollectionViewController

#pragma mark - LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.library = [[ALAssetsLibrary alloc] init];
    //设置刷新按钮
    self.navigationController.navigationBar.barTintColor = [UIColor lightGrayColor];
    self.navigationItem.title=@"相册";
    UIBarButtonItem *addBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPhotoAssets)];
    self.navigationItem.rightBarButtonItem = addBarButton;
    
    
    UICollectionViewFlowLayout *flowLayout=[[UICollectionViewFlowLayout alloc]init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    self.collectionView=[[UICollectionView alloc]initWithFrame:[UIScreen mainScreen].bounds collectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.view addSubview:self.collectionView];
    [self.collectionView registerClass:[KMMoviePosterCell class] forCellWithReuseIdentifier:@"KMMoviePosterCell"];
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark -UICollectionViewDataSource Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count=[[[PhotoManager sharedManager]photos] count];
    return count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"KMMoviePosterCell";
    KMMoviePosterCell *cell = (KMMoviePosterCell*)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:kCellImageViewTag];
    NSArray *photoAssets = [[PhotoManager sharedManager] photos];
    Photo *photo = photoAssets[indexPath.row];
    NSLog(@"photo %@",photo.image);
    switch (photo.status) {
        case PhotoStatusGoodToGo:
            cell.moviePosterImageView.image = [photo thumbnail];
            break;
        case PhotoStatusDownloading:
            cell.moviePosterImageView.image=[UIImage imageNamed:@"photoDownloading"];
            break;
        case PhotoStatusFailed:
            cell.moviePosterImageView.image = [UIImage imageNamed:@"photoDownloadError"];
        default:
            break;
    }
    
    
    return cell;
}
#pragma mark --UICollectionViewDelegateFlowLayout


//定义每个UICollectionView 的大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //边距占5*4=20 ，2个
    //图片为正方形，边长：(fDeviceWidth-20)/2-5-5 所以总高(fDeviceWidth-20)/2-5-5 +20+30+5+5 label高20 btn高30 边
    return CGSizeMake(fDeviceWidth/2,fDeviceHeight/3);
}
//定义每个UICollectionView 的间距
-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0,0);
}
//定义每个UICollectionView 纵向的间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}
//*****************************************************************************/
#pragma mark - UIBarButtonItem method
//*****************************************************************************/

/// The upper right UIBarButtonItem method
- (void)addPhotoAssets
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
        //[self downloadImageAssets];
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
