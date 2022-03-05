# OpenCVSampleForMacOS



![image](https://upload-images.jianshu.io/upload_images/453533-756cabd51583e65c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

OpenCV是一个跨平台计算机视觉和机器学习软件库，可以运行在Linux、Windows、Android和Mac OS操作系统上。它轻量级而且高效——由一系列 C 函数和少量 C++ 类构成，同时提供了Python、Ruby、MATLAB等语言的接口，实现了图像处理和计算机视觉方面的很多通用算法。

最近使用Flutter开发一个OpenCV的APP，调试时需同时显示多个窗口，以显示不同输出目标，手机屏幕比较小，显示多个视图时就显得困难，即使能显示，也因为窗口太小，不好分辨目标输出内容。于是想在MacOS下先调试好，再把算法copy到iOS、Android下面。

在网上搜索了很多教程，大部分已经年代久远已经不能正常安装好。我目前使用MacOS 10.15 安装 OpenCV 4.0.1 (iOS pod库最新是4.0.1)，通过Cmake编译出farmework，可直接导入到Mac项目，使用上较导入动态库方便许多，减去了配置Search Paths的麻烦。

#### 环境配置

1.首先需要安装Mac安装包管理器[brew](https://brew.sh/)或[MacPorts](https://www.macports.org/) （已安装跳过此步骤）

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

2.再安装Cmake，使用它编译C++

```
brew install cmake
```

or

```
port install cmake
```

3.下载opencv.zip
使用浏览器到OpenCV GitHub下载页面[https://github.com/opencv/opencv/releases](https://github.com/opencv/opencv/releases)下载你需要使用的OpenCV版本，我目前使用的是[4.0.1](https://codeload.github.com/opencv/opencv/zip/4.0.1)

#### 编译framework

1、解压OpenCV.zip
2、使用终端cd到OpenCV解压目录(e.g.)

```
cd ~/Desktop/opencv-4.0.1/
```

3、使用Python脚本编译opencv2.framework

```
python platforms/osx/build_framework.py frameworks
```

我的Mac编译时出现报错，我把build_framework.py中的MACOSX_DEPLOYMENT_TARGET改为10.13就编译成功了！有可能是默认的10.9会处理有关32位的问题。
build_framework.py位于解压文件目录的platforms/osx/下
修改后文件如下：

```
#!/usr/bin/env python
"""
The script builds OpenCV.framework for OSX.
"""

from __future__ import print_function
import os, os.path, sys, argparse, traceback, multiprocessing

# import common code
sys.path.insert(0, os.path.abspath(os.path.abspath(os.path.dirname(__file__))+'/../ios'))
from build_framework import Builder

class OSXBuilder(Builder):

    def getToolchain(self, arch, target):
        return None

    def getBuildCommand(self, archs, target):
        buildcmd = [
            "xcodebuild",
            "MACOSX_DEPLOYMENT_TARGET=10.13",
            "ARCHS=%s" % archs[0],
            "-sdk", target.lower(),
            "-configuration", "Release",
            "-parallelizeTargets",
            "-jobs", str(multiprocessing.cpu_count())
        ]
        return buildcmd

    def getInfoPlist(self, builddirs):
        return os.path.join(builddirs[0], "osx", "Info.plist")


if __name__ == "__main__":
    folder = os.path.abspath(os.path.join(os.path.dirname(sys.argv[0]), "../.."))
    parser = argparse.ArgumentParser(description='The script builds OpenCV.framework for OSX.')
    parser.add_argument('out', metavar='OUTDIR', help='folder to put built framework')
    parser.add_argument('--opencv', metavar='DIR', default=folder, help='folder with opencv repository (default is "../.." relative to script location)')
    parser.add_argument('--contrib', metavar='DIR', default=None, help='folder with opencv_contrib repository (default is "None" - build only main framework)')
    parser.add_argument('--without', metavar='MODULE', default=[], action='append', help='OpenCV modules to exclude from the framework')
    parser.add_argument('--enable_nonfree', default=False, dest='enablenonfree', action='store_true', help='enable non-free modules (disabled by default)')
    args = parser.parse_args()

    b = OSXBuilder(args.opencv, args.contrib, False, False, args.without, args.enablenonfree,
        [
            (["x86_64"], "MacOSX")
        ])
    b.build(args.out)
```

#### 创建Mac项目，导入OpenCV

打开Xcode->File -> New Project，选择APP。

![image](https://upload-images.jianshu.io/upload_images/453533-5c08bf2393282e0f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
输入项目名称OpenCVSample，Language选择Swift,User Innterface选择XIB

![image](https://upload-images.jianshu.io/upload_images/453533-05b51022c62ba700.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

在APPdelegate中配置window和contentViewController。
APPdelegate.swift

```
    var mainWindowController: NSWindowController!

    lazy var window: NSWindow = {
        let w = NSWindow(contentRect: NSMakeRect(0, 0, 1007 , 641), styleMask: [.titled, .resizable, .miniaturizable, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        w.center()
        w.backgroundColor = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
        w.minSize = NSMakeSize(320, 240)

        return w
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        mainWindowController = NSWindowController(window: window)
        mainWindowController.showWindow(nil)
        mainWindowController.window?.makeKeyAndOrderFront(nil)

        NSApplication.shared.mainWindow?.title = "OpenCV Sample"
        let scanViewCtrl = ScanViewController()
        window.contentViewController = scanViewCtrl
    }
```

将MainMenu.xib中的默认window删除，删除后如下图所示：
![image](https://upload-images.jianshu.io/upload_images/453533-a031b1e13d9beed6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 测试OpenCV

创建opencv视频处理桥接文件
CVCamera.h

```
@interface CVCamera : NSObject

- (id) initWithController: (NSViewController<CVCameraDelegate>*)c andCameraImageView: (NSImageView*)iv processImage: (NSImageView *)processIv;
- (void)start;
- (void)stop;

@end
```

CVCamera.mm

```
#import <opencv2/opencv.hpp>
#include "CVCamera.h"

using namespace cv;
using namespace std;

@interface CVCamera ()

@end

@implementation CVCamera
{
    NSViewController<CVCameraDelegate> * delegate;
    NSImageView * cameraimageView;
    NSImageView * processimageView;
    VideoCapture cap;
    cv::Mat gtpl;
    int cameraIndex;
    NSTimer *timer;
}

- (id) initWithController: (NSViewController<CVCameraDelegate>*)c andCameraImageView: (NSImageView*)iv processImage:(NSImageView *)processIv
{
    delegate = c;
    cameraimageView = iv;
    processimageView = processIv;

    cameraIndex = -1;
    timer = [NSTimer timerWithTimeInterval:30/1000.0 target:self selector:@selector(show_camera) userInfo:nil repeats:true];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return self;
}

- (void)processImage:(cv::Mat &)img {
    cv::Mat gimg;

    // Convert incoming img to greyscale to match template
    cv::cvtColor(img, gimg, COLOR_BGR2GRAY);

    // 5*5滤波
    cv::Mat blurred;
    cv::blur(gimg, blurred, cv::Size(5, 5));

    imshow("blurred", blurred);

    // 自适应二值化方法
    cv::Mat adaptiveThreshold;
    cv::adaptiveThreshold(blurred, adaptiveThreshold, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 15, 5);
    // canny边缘检测
    cv::Mat edges;
    cv::Canny(adaptiveThreshold, edges, 10, 100);
    // 从边缘图中寻找轮廓
    std::vector<std::vector<cv::Point>> contours;
    findContours(edges, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

    double maxArea = 0;

    vector<cv::Point> approx;
    vector<cv::Point> docCnt;
    vector<cv::Point> maxAreaContour;
    for (size_t i = 0; i < contours.size(); i++)
    {
        double area = contourArea(contours[i]);
        if (area > maxArea) {
            maxArea = area;
            maxAreaContour = contours[i];
        }
    }

    // approximate contour with accuracy proportional
    // to the contour perimeter
    approxPolyDP(maxAreaContour, approx, arcLength(maxAreaContour, true)*0.02, true);

    // Note: absolute value of an area is used because
    // area may be positive or negative - in accordance with the
    // contour orientation
    if (approx.size() == 4 &&
            isContourConvex(Mat(approx)))
    {
        docCnt = approx;
        std::vector<std::vector<cv::Point>> showContours(1);
        showContours[0] = docCnt;
        drawContours(img, showContours, -1, Scalar(208, 19, 29), 2);
    }
}

- (void)start
{
    [self openCamera];
}

- (void)stop
{
//    videoCap.close();
}

- (void)openCamera {
    VideoCapture capture = VideoCapture(0);
    if (capture.isOpened()) {
        self->cap = capture;
        self->cameraIndex = 0;
    } else {
        VideoCapture capture_usb = VideoCapture(1);
        if (capture_usb.isOpened()) {
            self->cap = capture_usb;
            self->cameraIndex = 1;
        } else {
            printf("未找到摄像头,请检查设备连接");
            return;
        }
    }

    self->cap.set(3, 1400);
    self->cap.set(4, 1050);

    [self->timer setFireDate:[NSDate distantPast]];
;

}

- (void)show_camera {
    if (self->cap.isOpened()) {
        Mat frame;
        self->cap.read(frame);
        NSImage *image = MatToNSImage(frame);
        self->cameraimageView.image = image;

        // processImage
        Mat processFrame = frame.clone();
        [self processImage:processFrame];
        NSImage *processimage = MatToNSImage(processFrame);
        self->processimageView.image = processimage;
    }
//    if (self.recongnitioned) {
//        self.recognition()
//    }
}

/// Converts an NSImage to Mat.
static void NSImageToMat(NSImage *image, cv::Mat &mat) {

    // Create a pixel buffer.
    NSBitmapImageRep *bitmapImageRep = [NSBitmapImageRep imageRepWithData:image.TIFFRepresentation];
    NSInteger width = bitmapImageRep.pixelsWide;
    NSInteger height = bitmapImageRep.pixelsHigh;
    CGImageRef imageRef = bitmapImageRep.CGImage;
    cv::Mat mat8uc4 = cv::Mat((int)height, (int)width, CV_8UC4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);

    // Draw all pixels to the buffer.
    cv::Mat mat8uc3 = cv::Mat((int)width, (int)height, CV_8UC3);
    cv::cvtColor(mat8uc4, mat8uc3, cv::COLOR_RGBA2BGR);

    mat = mat8uc3;
}

/// Converts a Mat to NSImage.
static NSImage *MatToNSImage(cv::Mat &mat) {

    // Create a pixel buffer.
    assert(mat.elemSize() == 1 || mat.elemSize() == 3);
    cv::Mat matrgb;
    if (mat.elemSize() == 1) {
        cv::cvtColor(mat, matrgb, cv::COLOR_GRAY2RGB);
    } else if (mat.elemSize() == 3) {
        cv::cvtColor(mat, matrgb, cv::COLOR_BGR2RGB);
    }

    // Change a image format.
    NSData *data = [NSData dataWithBytes:matrgb.data length:(matrgb.elemSize() * matrgb.total())];
    CGColorSpaceRef colorSpace;
    if (matrgb.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(matrgb.cols, matrgb.rows, 8, 8 * matrgb.elemSize(), matrgb.step.p[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    NSImage *image = [NSImage new];
    [image addRepresentation:bitmapImageRep];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return image;
}

+ (NSImage *)cvtColorBGR2GRAY:(NSImage *)image {
    cv::Mat bgrMat;
    NSImageToMat(image, bgrMat);
    cv::Mat grayMat;
    cv::cvtColor(bgrMat, grayMat, cv::COLOR_BGR2GRAY);
    NSImage *grayImage = MatToNSImage(grayMat);
    return grayImage;
}

@end
```

项目中使用swift语言开发，需要创建桥接文件OpenCVSampleForMacOS-Bridging-Header.h，并且在配置中设置桥接文件。

OpenCVSampleForMacOS-Bridging-Header.h

```
#ifndef OpenCVSampleForMacOS_Bridging_Header_h
#define OpenCVSampleForMacOS_Bridging_Header_h

#import "CVCamera.h"

#endif /* OpenCVSampleForMacOS_Bridging_Header_h */
```

创建一个展示视频内容的ScanViewController：

```
import Foundation

class ScanViewController: NSViewController, CVCameraDelegate {

    lazy var previewImageView: NSImageView = {
        let imgView = NSImageView(frame: NSRect(x: 10, y: 10, width: 480, height: 320))

        return imgView
    }()

    lazy var processImageView: NSImageView = {
        let imgView = NSImageView(frame: NSRect(x: 520, y: 10, width: 480, height: 320))

        return imgView
    }()

    lazy var label: NSTextField = {
        let v = NSTextField(labelWithString: "Press the button")
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()


    lazy var button: NSButton = {
        let v = NSButton(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()

    var camera: CVCamera!

    override func loadView() {
        // 设置 ViewController 大小同 mainWindow
        guard let windowRect = NSApplication.shared.windows.first?.frame else { return }
        view = NSView(frame: windowRect)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(label)
        view.addSubview(button)
        view.addSubview(previewImageView)
        view.addSubview(processImageView)

        camera = CVCamera(controller: self, andCameraImageView: previewImageView, processImage:processImageView);

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),

            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            button.heightAnchor.constraint(equalToConstant: 30),
            button.widthAnchor.constraint(equalToConstant: 100)
            ])

        button.title = "开始"
        button.target = self
        button.action = #selector(onClickme)
    }

    func matchedItem() {

    }

    @objc func onClickme(_ sender: NSButton) {
        label.textColor = .red
        label.stringValue = "👌!"

        camera.start()
    }
}
```

#### 结果

Command+R 运行结果如下所示：
通过openCV识别出最大边框并且进行显示。
![image](https://upload-images.jianshu.io/upload_images/453533-38226a02f2596877.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 参考

- https://github.com/ura14h/OpenCVSample
- https://blog.devtang.com/2012/10/27/use-opencv-in-ios/
