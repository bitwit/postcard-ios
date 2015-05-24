//
// Created by Kyle Newsome on 2013-09-25.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <AssetsLibrary/AssetsLibrary.h>
#import "CameraOptionsTableDelegate.h"
#import "UIImage+ProportionalFill.h"


CGFloat degreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
};

@interface CameraOptionsTableDelegate ()
@property(nonatomic, strong) ALAsset *latestPhoto;
@property(nonatomic, strong) ALAsset *latestVideo;
@property(nonatomic, strong) NSArray *cellInfo;
@end

@implementation CameraOptionsTableDelegate

- (id)initWithTable:(UITableView *)tableView andViewController:(PCViewController *)viewController {
    if ((self = [super initWithTable:tableView andViewController:viewController])) {
        self.cellInfo = @[
                @{
                        @"image" : @"image-recent",
                        @"title" : @"Latest photo",
                        @"description" : @"Recent image from camera roll",
                        @"selector" : @"getLatestPhoto",
                        @"activates" : @YES
                },
                @{
                        @"image" : @"image-camera",
                        @"title" : @"Take picture/video",
                        @"description" : @"using camera",
                        @"selector" : @"getPhoto",
                        @"activates" : @YES
                },
                @{
                        @"image" : @"image-library",
                        @"title" : @"Select from library",
                        @"description" : @"Browse all your media",
                        @"selector" : @"attachFromLibrary",
                        @"activates" : @YES
                },
                @{
                        @"image" : @"attachment-upload",
                        @"title" : @"Upload photo/video from Dropbox",
                        @"description" : @"Uses extra bandwidth",
                        @"selector" : @"uploadFileFromDropbox",
                        @"activates" : @YES
                }
        ];
    }
    return self;
}

- (void)makeActiveDelegateAndRevealFromRight:(BOOL)doRevealRight {
    [super makeActiveDelegateAndRevealFromRight:doRevealRight];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:(doRevealRight) ? UITableViewRowAnimationLeft : UITableViewRowAnimationRight];
}

- (IBAction)getLatestPhoto {
    BWLog(@"Get Latest Photo");
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stopGroup) {
        if (group != NULL) {
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stopAsset) {
                if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                    self.latestPhoto = result;
                }
                if (index >= (group.numberOfAssets - 1)) {
                    PCMessageMedia *media = [[PCMessageMedia alloc] init];

                    //create UIImage and get NSData too
                    ALAssetRepresentation *rep = _latestPhoto.defaultRepresentation;
                    media.image = [[UIImage alloc] initWithCGImage:rep.fullScreenImage];
                    Byte *buffer = (Byte *) malloc(rep.size);
                    NSUInteger buffered = [rep getBytes:buffer fromOffset:0 length:rep.size error:nil];
                    NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                    media.imageData = data;

                    //figure out file extension
                    NSArray *fileNameComponents = [rep.filename componentsSeparatedByString:@"."];
                    media.mimeType = [NSString stringWithFormat:@"image/%@", ([fileNameComponents.lastObject isEqualToString:@"jpg"]) ? @"jpeg" : fileNameComponents.lastObject];

                    if (![fileNameComponents.lastObject isEqualToString:@"gif"]) {
                        //we reduce the file size of non-gifs. (Gifs might be animated and are preserved as a result)
                        UIImage *reducedImage;
                        if (media.image.size.width >= media.image.size.height) {
                            //CGFloat ratio = image.size.height / image.size.width;
                            //reducedImage = [image imageScaledToFitSize:CGSizeMake(720, 720 * ratio)];
                            reducedImage = [UIImage imageWithImage:media.image scaledToWidth:720.0f];
                        } else {
                            CGFloat ratio = media.image.size.width / media.image.size.height;
                            // reducedImage = [image imageScaledToFitSize:CGSizeMake(720 * ratio, 720)];
                            reducedImage = [UIImage imageWithImage:media.image scaledToWidth:720.0f * ratio];
                        }
                        media.image = reducedImage;
                        media.imageData = UIImageJPEGRepresentation(reducedImage, 0.80f);
                        media.mimeType = @"image/jpeg";
                    }


                    self.viewController.currentPostcard.messageMedia = media;
                    self.viewController.cameraAttachmentIndicator.hidden = NO;
                    *stopGroup = YES;
                    *stopAsset = YES;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                        [self.viewController calculateCharacterCount];
                    });
                }
            }];
        }
    }
                         failureBlock:^(NSError *error) {
                             BWLog(@"failure");
                         }];
}

- (IBAction)getPhoto {
    BWLog(@"Get Photo or Video");
    PCImagePickerController *picker = [[PCImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.mediaTypes = [PCImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self.viewController presentViewController:picker animated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (IBAction)attachFromLibrary {
    BWLog(@"Get From Library");
    PCImagePickerController *picker = [[PCImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = [PCImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self.viewController presentViewController:picker animated:YES completion:nil];
}

- (void)uploadFileFromDropbox {
    [[DBChooser defaultChooser] openChooserForLinkType:DBChooserLinkTypeDirect
                                    fromViewController:(UIViewController *) self.viewController completion:^(NSArray *results) {
        for (OptionCell *cell in [self.tableView visibleCells]) {
            [cell deactivate];
        }
        if ([results count]) {
            DBChooserResult *result = results[0];
            if (result.thumbnails.count > 0) {
                BWLog(@"Name -> %@ \n Type -> %@ \n URL -> %@ \n Size-> %lld \n iconURL -> %@ \n thumbnails -> %@", result.name, result.link.pathExtension, result.link.absoluteString, result.size, result.iconURL.absoluteString, result.thumbnails);
                NSArray *supportedTypes = @[
                        @"jpg",
                        @"png",
                        @"gif",
                        @"mp4"
                ];
                NSString *extension = result.link.pathExtension;

                BOOL validType = NO;
                for (NSString *supportedType in supportedTypes) {
                    if ([supportedType caseInsensitiveCompare:extension]) {
                        validType = YES;
                        break;
                    }
                }

                if (validType) {
                    PCMessageMedia *media = [[PCMessageMedia alloc] init];
                    [media setupWithContentUrl:result.link];
                    self.viewController.currentPostcard.messageMedia = media;
                    self.viewController.cameraAttachmentIndicator.hidden = NO;
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                } else {
                    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:NSLocalizedString(@"That's not a supported image or video type :(", nil)
                                                                      message:[NSString stringWithFormat:NSLocalizedString(@"Oops, Postcard doesn't support uploading the %@ file type for upload at the moment. You can always attach it as a link instead.", nil), extension]
                                                                     delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                            otherButtonTitles:nil];
                    [alert show];
                }
            } else {
                SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:NSLocalizedString(@"That's not an image or video :(", nil)
                                                                  message:NSLocalizedString(@"Oops, you need to select an image or video file to upload it directly.", nil)
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                        otherButtonTitles:nil];
                [alert show];
            }
        } else {
            BWLog(@"cancelled");
        }
    }];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    for (OptionCell *cell in [self.tableView visibleCells]) {
        [cell deactivate];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    NSURL *assetURL = [info objectForKey:UIImagePickerControllerMediaURL];
    NSURL *referenceURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    UIImage *image = (UIImage *) [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    PCMessageMedia *media = [[PCMessageMedia alloc] init];

    BWLog(@"\nmediaType -> %@ \nassetURL -> %@ , referenceURL -> %@, \nimage -> %@\n\n", mediaType, assetURL, referenceURL, image);

    if (image) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        BWLog(@"Library image -> %@", referenceURL.absoluteString);
        if ([referenceURL.pathExtension.lowercaseString isEqualToString:@"gif"]) {
            //
            //this is a gif, so we need to grab it from the library directly to preserve animations
            //
            [library assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
                ALAssetRepresentation *rep = asset.defaultRepresentation;
                media.image = [[UIImage alloc] initWithCGImage:rep.fullScreenImage];

                Byte *buffer = (Byte *) malloc(rep.size);
                NSUInteger buffered = [rep getBytes:buffer fromOffset:0 length:rep.size error:nil];
                NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                media.mimeType = [NSString stringWithFormat:@"image/%@", ([referenceURL.pathExtension isEqualToString:@"jpg"]) ? @"jpeg" : referenceURL.pathExtension];
                media.imageData = data;

                self.viewController.currentPostcard.messageMedia = media;
                self.viewController.cameraAttachmentIndicator.hidden = NO;

            }       failureBlock:^(NSError *error) {
                SDCAlertView *alertView = [[SDCAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                      message:NSLocalizedString(@"Couldn't attach gif image from library", nil)
                                                                     delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                            otherButtonTitles:nil];
                [alertView show];
            }];
        } else {
            //save newly taken picture
            media.image = image;
            UIImage *reducedImage;
            if (image.size.width >= image.size.height) {
                //CGFloat ratio = image.size.height / image.size.width;
                //reducedImage = [image imageScaledToFitSize:CGSizeMake(720, 720 * ratio)];
                reducedImage = [UIImage imageWithImage:image scaledToWidth:720.0f];
            } else {
                CGFloat ratio = image.size.width / image.size.height;
                // reducedImage = [image imageScaledToFitSize:CGSizeMake(720 * ratio, 720)];
                reducedImage = [UIImage imageWithImage:image scaledToWidth:720.0f * ratio];
            }
            media.imageData = UIImageJPEGRepresentation(reducedImage, 0.80f);
            media.mimeType = @"image/jpeg";

            [library writeImageDataToSavedPhotosAlbum:media.imageData metadata:nil completionBlock:^(NSURL *imageAssetURL, NSError *error) {
                if (error) {
                    BWLog(@"ERROR: the image failed to be written %@", [error description]);
                }
                else {
                    BWLog(@"PHOTO SAVED - assetURL: %@", imageAssetURL);
                }
            }];
        }

        self.viewController.currentPostcard.messageMedia = media;
        self.viewController.cameraAttachmentIndicator.hidden = NO;
        [self.viewController calculateCharacterCount];
        [self.viewController dismissViewControllerAnimated:YES completion:^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    } else if ([mediaType isEqualToString:@"public.movie"]) {
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(assetURL.path)) {
            AVURLAsset *asset = [AVURLAsset assetWithURL:assetURL];
            [self exportAsset:asset];
            //UISaveVideoAtPathToSavedPhotosAlbum(assetURL.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        } else {
            BWLog(@"Not compatible to be saved to photo album, or not needed (i.e. already from library)");
            BWLog(@"Video Asset URL -> %@ type %@ absoluteString %@", referenceURL, [referenceURL class], [referenceURL absoluteString]);
            ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
            [assetLibrary assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
                BWLog(@"Asset for url -> %@", asset);
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                AVURLAsset *avUrlAsset = [AVURLAsset URLAssetWithURL:[rep url] options:nil];

                AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:avUrlAsset];

                NSArray *tracks = [avUrlAsset tracksWithMediaType:AVMediaTypeVideo];
                AVAssetTrack *track = [tracks objectAtIndex:0];

                Byte *buffer = (Byte *) malloc(rep.size);
                NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];

                PCMessageMedia *media = [[PCMessageMedia alloc] init];
                media.videoData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                media.mimeType = @"video/mp4";
                self.viewController.currentPostcard.messageMedia = media;

                generator.maximumSize = track.naturalSize;
                generator.appliesPreferredTrackTransform = YES;
                [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:kCMTimeZero]]
                                                completionHandler:^(CMTime requestedTime, CGImageRef cgImage, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
                                                    if (result == AVAssetImageGeneratorSucceeded) {
                                                        UIImage *newImage = [UIImage imageWithCGImage:cgImage];
                                                        media.image = newImage;
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            self.viewController.cameraAttachmentIndicator.hidden = NO;
                                                            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                            BWLog(@"Thumbnail image set");
                                                        });
                                                    } else {
                                                        BWLog(@"Creating thumbnail failed");
                                                    }
                                                }];

            }            failureBlock:^(NSError *err) {
                BWLog(@"Error: %@", [err localizedDescription]);
            }];
        }

        [self.viewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.viewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark  - TableView related

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.viewController.currentPostcard.messageMedia == nil) {
        NSDictionary *cellInfo = _cellInfo[(NSUInteger) indexPath.row];
        if ([cellInfo[@"activates"] boolValue]) {
            OptionCell *cell = (OptionCell *) [self.tableView cellForRowAtIndexPath:indexPath];
            [cell activate];
        }
        [self performSelector:NSSelectorFromString(cellInfo[@"selector"]) withObject:nil afterDelay:0.16f];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.viewController.currentPostcard.messageMedia != nil) {
        return 1;
    } else {
        return 4;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.viewController.currentPostcard.messageMedia != nil) {
        return 180.0f;
    } else {
        return 60.0f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.viewController.currentPostcard.messageMedia != nil) {
        ItemAttachmentDetailsCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ItemAttachmentDetailsCell"];
        [cell setWithMessageAttachment:self.viewController.currentPostcard.messageMedia];
        cell.delegate = self;
        return cell;
    } else {
        NSDictionary *info = _cellInfo[(NSUInteger) indexPath.row];
        OptionCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OptionCell"];
        UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"icon-%@", [info valueForKey:@"image"]]];
        cell.iconImageView.image = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconImageView.tintColor = [PCColorPalette darkBlueColor];
        cell.titleLabel.text = [info valueForKey:@"title"];
        cell.descriptionLabel.text = [[info valueForKey:@"description"] uppercaseString];
        return cell;
    }
}

- (void)itemCellDidRequestRemoval:(ItemAttachmentDetailsCell *)cell {
    self.viewController.currentPostcard.messageMedia = nil;
    cell.itemImageView.image = nil;

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    self.viewController.cameraAttachmentIndicator.hidden = YES;
    [self.viewController calculateCharacterCount];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.viewController navigationController:navigationController willShowViewController:viewController animated:animated];
}


#pragma mark - Video editing

- (void)exportAsset:(AVURLAsset *)urlAsset {
    //Create AVMutableComposition Object.This object will hold our multiple AVMutableCompositionTrack.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

    //VIDEO TRACK
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, urlAsset.duration) ofTrack:[[urlAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];

    //AUDIO TRACK
    AVMutableCompositionTrack *AudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [AudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, urlAsset.duration) ofTrack:[[urlAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];

    AVMutableVideoCompositionInstruction *MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, urlAsset.duration);

    BWLog(@"Natural Size - > %@", NSStringFromCGSize(videoTrack.naturalSize));

    //FIXING ORIENTATION//
    AVMutableVideoCompositionLayerInstruction *firstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    AVAssetTrack *firstAssetTrack = [[urlAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    // UIImageOrientation assetOrientation = UIImageOrientationUp;
    BOOL isVideoAssetPortrait = NO;
    CGAffineTransform firstTransform = firstAssetTrack.preferredTransform;
    if (firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0) {
        // assetOrientation = UIImageOrientationRight;
        isVideoAssetPortrait = YES;
    }
    if (firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0) {
        // assetOrientation = UIImageOrientationLeft;
        isVideoAssetPortrait = YES;
    }
    // if (firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0) {assetOrientation = UIImageOrientationUp;}
    // if (firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == -1.0) {assetOrientation = UIImageOrientationDown;}
    //CGFloat firstAssetScaleToFitRatio = 360.0 / firstAssetTrack.naturalSize.width;
    if (isVideoAssetPortrait) {
        CGFloat firstAssetScaleToFitRatio = 360.0 / firstAssetTrack.naturalSize.height;
        CGAffineTransform firstAssetScaleFactor = CGAffineTransformMakeScale(firstAssetScaleToFitRatio, firstAssetScaleToFitRatio);
        [firstlayerInstruction setTransform:CGAffineTransformConcat(firstAssetTrack.preferredTransform, firstAssetScaleFactor) atTime:kCMTimeZero];
    }

    MainInstruction.layerInstructions = [NSArray arrayWithObjects:firstlayerInstruction, nil];;

    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.renderSize = isVideoAssetPortrait ? CGSizeMake(360.0f, 480.0f) : CGSizeMake(480.0f, 360.0f);

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeVideo-%d.mp4", arc4random() % 1000]];

    NSURL *url = [NSURL fileURLWithPath:myPathDocs];

    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    exporter.outputURL = url;
    exporter.outputFileType = AVFileTypeMPEG4;
    //exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.videoComposition = MainCompositionInst;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self exportDidFinish:exporter];
        });
    }];
}

- (void)exportDidFinish:(AVAssetExportSession *)session {
    BWLog(@"Export session, %@", session);
    /*
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL
                                        completionBlock:^(NSURL *assetURL, NSError *error) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                if (error) {
                                                    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                                                    [alert show];
                                                } else {
                                                    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                                                    [alert show];
                                                }

                                            });

                                        }];
        }
    }
    */

    switch (session.status) {
        case AVAssetExportSessionStatusCompleted: {
            BWLog(@"Export Success");

            NSData *videoData = [NSData dataWithContentsOfURL:session.outputURL];
            AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:session.outputURL options:nil];

            AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];

            NSArray *tracks = [urlAsset tracksWithMediaType:AVMediaTypeVideo];
            AVAssetTrack *track = [tracks objectAtIndex:0];

            PCMessageMedia *media = [[PCMessageMedia alloc] init];
            media.videoData = videoData;
            media.mimeType = @"video/mp4";
            self.viewController.currentPostcard.messageMedia = media;

            generator.maximumSize = track.naturalSize;
            generator.appliesPreferredTrackTransform = YES;
            [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:kCMTimeZero]]
                                            completionHandler:^(CMTime requestedTime, CGImageRef cgImage, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
                                                if (result == AVAssetImageGeneratorSucceeded) {
                                                    UIImage *newImage = [UIImage imageWithCGImage:cgImage];
                                                    media.image = newImage;
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        self.viewController.cameraAttachmentIndicator.hidden = NO;
                                                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                        BWLog(@"Thumbnail image set");
                                                    });
                                                } else {
                                                    BWLog(@"Creating thumbnail failed");
                                                }
                                            }];


        }
        break;
        case AVAssetExportSessionStatusFailed:
            BWLog(@"Export failed: %@", [session error]);
            [Flurry logEvent:@"video export fail" withParameters:@{
                                                                   @"error" : (session.error != nil) ? session.error.localizedDescription : @"empty"
            }];
            break;

        case AVAssetExportSessionStatusCancelled:
            BWLog(@"Export canceled");
            break;

        default:
            break;
    }

}


@end
