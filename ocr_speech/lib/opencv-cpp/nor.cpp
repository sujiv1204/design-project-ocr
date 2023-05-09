#include <iostream>
#include <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

Mat transform_img(char *imagePath) {
    Mat img = imread(imagePath, IMREAD_COLOR);
    cvtColor(img, img, COLOR_BGR2RGB);
    resize(img, img, Size(512, 512));
    img.convertTo(img, CV_32F, 1.0 / 255);
    // img = img.reshape(1, 1);
    return img;
}

void normalizeImage(char *imagePath) {
    // string path = "path/to/image.jpg";
    Mat transformed_img = transform_img(imagePath);

    // Convert image back to 3 channels and save
    // transformed_img = transformed_img.reshape(3, 512);
    // transformed_img.convertTo(transformed_img, CV_8UC3, 255);
    imwrite(imagePath, transformed_img);

}
