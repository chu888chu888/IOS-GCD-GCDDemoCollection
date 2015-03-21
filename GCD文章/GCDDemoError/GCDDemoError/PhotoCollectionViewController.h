//
//  PhotoCollectionViewController.h
//  GCDDemoError
//
//  Created by chuguangming on 15/3/21.
//  Copyright (c) 2015年 chu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELCImagePickerController.h"
@interface PhotoCollectionViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate,UIActionSheetDelegate,ELCImagePickerControllerDelegate>
@property(nonatomic) UICollectionView *collectionView;
@end
