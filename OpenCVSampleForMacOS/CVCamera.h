//
//  CVCamera.h
//  Runner
//
//  Created by CaiDan on 2020/6/29.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// Protocol for callback action
@protocol CVCameraDelegate <NSObject>

- (void)matchedItem;

@end

// Public interface for camera. ViewController only needs to init, start and stop.
@interface CVCamera : NSObject

- (id) initWithController: (NSViewController<CVCameraDelegate>*)c andCameraImageView: (NSImageView*)iv processImage: (NSImageView *)processIv;
- (void)start;
- (void)stop;

@end
