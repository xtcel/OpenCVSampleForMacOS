//
//  CVCamera.m
//  Runner
//
//  Created by CaiDan on 2020/6/29.
//
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
    
    // 7*7滤波
    cv::Mat blurred;
    cv::blur(gimg, blurred, cv::Size(7, 7));
    
    // 自适应二值化方法
    cv::Mat adaptiveThreshold;
//    cv::adaptiveThreshold(gimg, adaptiveThreshold, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 15, 5);
    cv::adaptiveThreshold(blurred, adaptiveThreshold, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 53, 5);
    
    imshow("adaptiveThreshold", adaptiveThreshold);
    
    // canny边缘检测
    cv::Mat edges;
    cv::Canny(adaptiveThreshold, edges, 10, 100);

    // 从边缘图中寻找轮廓
    vector<vector<cv::Point>> contours;
    findContours(edges, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    
    double maxArea = 0;
    
    vector<cv::Point> approx;
    vector<cv::Point> docCnt;
    vector<cv::Point> maxAreaContour;
    // 构造变换矩阵
    cv::Point2f srcVertices[4];
    
    for (size_t i = 0; i < contours.size(); i++)
    {
        Mat c = Mat(contours[i]);
        double area = contourArea(c, false);
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
        vector<vector<cv::Point>> showContours(1);
        showContours[0] = docCnt;
        drawContours(img, showContours, -1, Scalar(208, 19, 29), 2);
        
        Moments m = moments(maxAreaContour);
        float cx = float(m.m10/m.m00);
        float cy = float(m.m01/m.m00);
        
        cv::circle(img, docCnt[0], 3, CV_RGB(255, 0, 0), -1);
        cv::circle(img, docCnt[1], 3, CV_RGB(0, 255, 0), -1);
        cv::circle(img, docCnt[2], 3, CV_RGB(0, 0, 255), -1);
        cv::circle(img, docCnt[3], 3, CV_RGB(255, 255, 255), -1);
        cv::circle(img, Point2f(cx, cy), 3, CV_RGB(255, 0, 255), -1);
        
        sortCorners(docCnt, Point2f(cx, cy), srcVertices);
    }
    
    if (docCnt.size() == 0) {
        return;
    }
    
//    for(auto array: docCnt) {
//        std::cout << array << " ";
//    }
//    std::cout << std::endl;

    double width = 692;
    double height = 926;

    Point2f dstVertex[4];
    dstVertex[0] = Point2f(0, 0);
    dstVertex[1] = Point2f(width, 0);
    dstVertex[2] = Point2f(width, height);
    dstVertex[3] = Point2f(0, height);
    // 透视变换
    Mat transform = getPerspectiveTransform(srcVertices, dstVertex);
    Mat paper;
    warpPerspective(adaptiveThreshold, paper, transform, cv::Size(width, height));
    
    [self recognitionCard:paper];
}

- (void)recognitionCard:(cv::Mat &)src {
    imshow("src", src);
    
    // 创建填涂模板
//    Mat templImage = Mat(20, 5, CV_32FC1, Scalar(0, 0, 0));
    
//    vector<cv::Rect> matchResults;
//    matchTemplate(src, templImage, matchResults, TM_CCOEFF_NORMED);
//    int threshold = 0.8;
    
//    NSImage *tplImg = [NSImage imageNamed:@"tpl"];
//    cv::Mat tpl;
//    NSImageToMat(tplImg, tpl);
//    cv::cvtColor(tpl, gtpl, COLOR_BGR2GRAY);
//
//    cv::Mat res(src.rows-gtpl.rows+1, gtpl.cols-gtpl.cols+1, CV_32FC1);
//    cv::matchTemplate(src, gtpl, res, TM_CCOEFF_NORMED);
//    cv::threshold(res, res, 0.5, 1., THRESH_TOZERO);
//
//    double minval, maxval, threshold = 0.8;
//    cv::Point minloc, maxloc;
//    cv::minMaxLoc(res, &minval, &maxval, &minloc, &maxloc);
//
//    // If it's a good enough match
//    if (maxval >= threshold)
//    {
//        // Draw a rectangle for confirmation
////        cv:Rect rect = cv::Rect(maxloc.x, maxloc.y, gtpl.cols, gtpl.rows)
//        cout << maxloc << endl;
//        cv::rectangle(src, maxloc, cv::Point(maxloc.x + gtpl.cols, maxloc.y + gtpl.rows), Scalar(0,255,0), -1);
////        cv::floodFill(res, maxloc, cv::Scalar(0), 0, cv::Scalar(.1), cv::Scalar(1.));
//        // Call our delegates callback method
////        [delegate matchedItem];
//    }
    
    
//    // 二值化
//    Mat ChQBlur;
//    threshold(src, ChQBlur, 127, 225, THRESH_BINARY);
//
//    // 中值滤波
//    Mat mdBlur;
//    medianBlur(ChQBlur, mdBlur, 9);
//
//    vector<vector<cv::Point>> contours;
//    findContours(src, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
//
//    for (size_t i = 0; i < contours.size(); i++)
//    {
//        Mat c = Mat(contours[i]);
//        double area = contourArea(c, false);
//
//        // 计算轮廓的边界框，然后利用边界框数据计算宽高比
//        cv::Rect rect = boundingRect(c); // 包覆此轮廓的最小正矩形
//        if ((rect.width > 15) && (rect.height > 3) && (area > 45)) {
//            // 绘制矩形
//            rectangle(src, rect, Scalar(208, 19, 29));
//        }
//    }
}

// 排序角点，转换为矩阵点顺序
void sortCorners(vector<cv::Point>& corners,
                 Point2f center, Point2f output[]) {
    float cx = center.x;
    float cy = center.y;
    for (auto point: corners) {
        float x = point.x;
        float y = point.y;
        if ((x < cx) && (y < cy)) {
            Point2f tl = point;
            output[0] = tl;
        } else if ((x > cx) && (y < cy)) {
            Point2f tr = point;
            output[1] = tr;
        } else if ((x > cx) && (y > cy)) {
            Point2f br = point;
            output[2] = br;
        } else if ((x < cx) && (y > cy)) {
            Point2f bl = point;
            output[3] = bl;
        }
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
    
//    printf("width = %.2f\n",self->cap.get(CAP_PROP_FRAME_WIDTH));
//    printf("height = %.2f\n",self->cap.get(CAP_PROP_FRAME_HEIGHT));
//
//    self->cap.set(CAP_PROP_FRAME_WIDTH, 1080);//宽度
//    self->cap.set(CAP_PROP_FRAME_HEIGHT, 960);//高度
    
    printf("width = %.2f\n",self->cap.get(CAP_PROP_FRAME_WIDTH));
    printf("height = %.2f\n",self->cap.get(CAP_PROP_FRAME_HEIGHT));
//    self->cap.set(CV_CAP_PROP_FPS, 30);//帧数
//    self->cap.set(CV_CAP_PROP_BRIGHTNESS, 1);//亮度 1
//    self->cap.set(CV_CAP_PROP_CONTRAST,40);//对比度 40
//    self->cap.set(CV_CAP_PROP_SATURATION, 50);//饱和度 50
//    self->cap.set(CV_CAP_PROP_HUE, 50);//色调 50
//    self->cap.set(CV_CAP_PROP_EXPOSURE, 50);//曝光 50
    
    [self->timer setFireDate:[NSDate distantPast]];
;
    
}

- (void)show_camera {
    if (self->cap.isOpened()) {
        Mat frame;
        self->cap.read(frame);
        
        // 旋转90
        Mat temp;
        transpose(frame, temp);
        flip(temp, frame, 0);
        
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
