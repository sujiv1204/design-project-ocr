#include <opencv2/opencv.hpp>
#include <opencv2/imgproc/types_c.h>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>
#include <vector>
#include <stdexcept>

using namespace cv;
using namespace std;

extern "C"
{

    Mat preprocess(Mat im, int blur_radius)
    {
        Mat saturation;
        cvtColor(im, saturation, COLOR_BGR2HSV);
        saturation = saturation.rowRange(0, 3).colRange(1, 2);
        if (blur_radius != 0)
            medianBlur(saturation, saturation, blur_radius);
        return saturation;
    }

    vector<Rect> find_characters(Mat im, int max_area)
    {
        Ptr<MSER> mser = MSER::create(max_area = max_area);
        Mat gray;
        cvtColor(im, gray, COLOR_BGR2GRAY);
        vector<Rect> characters;
        mser->detectRegions(gray, mser, characters);
        return characters;
    }

    void remove_characters(vector<Rect> &characters, Mat &mask)
    {
        for (Rect character : characters)
        {
            for (int x = character.x; x < character.x + character.width; x++)
            {
                for (int y = character.y; y < character.y + character.height; y++)
                {
                    mask.at<uchar>(y, x) = 0;
                }
            }
        }
    }

    Mat detect_edges(Mat im, int blur_radius = 0, int thr1 = 100, int thr2 = 200, bool remove_text = true)
    {
        Mat enhanced_im = preprocess(im, blur_radius);
        Mat edges;
        Canny(enhanced_im, edges, thr1, thr2);
        if (remove_text)
        {
            int height = im.rows;
            int width = im.cols;
            vector<Rect> characters = find_characters(im, (width * height) / 100);
            remove_characters(characters, edges);
        }
        return edges;
    }

    bool is_duplicated(Vec2f line, vector<Vec2f> &lines, int thr)
    {
        for (Vec2f _line : lines)
        {
            if (abs(line[0] - _line[0]) < thr)
                return true;
        }
        return false;
    }

    vector<Vec2f> group_similar(vector<Vec2f> &lines, int thr)
    {
        sort(lines.begin(), lines.end(), [](Vec2f a, Vec2f b)
             { return a[0] < b[0]; });
        vector<Vec2f> lines_unique;
        for (Vec2f to_add : lines)
        {
            if (!is_duplicated(to_add, lines_unique, thr))
                lines_unique.push_back(to_add);
        }
        return lines_unique;
    }

    vector<Vec2f> cvhoughlines2list(vector<Vec2f> &lines)
    {
        vector<Vec2f> out;
        for (size_t i = 0; i < lines.size(); i++)
        {
            float rho = lines[i][0];
            float theta = lines[i][1];
            out.push_back(Vec2f(rho, theta));
        }
        return out;
    }

    bool lines_are_same(Vec2f line1, Vec2f line2)
    {
        return line1 == line2;
    }

    double lines_angle(Vec2f line1, Vec2f line2)
    {
        return abs(line1[1] - line2[1]) * 180 / CV_PI;
    }

    vector<Vec2f> detect_lines(Mat im, int hough_thr = 65, int group_similar_thr = 30)
    {
        vector<Vec2f> lines;
        HoughLines(im, lines, 1, CV_PI / 90, hough_thr);
        if (lines.empty())
            return {};
        lines = cvhoughlines2list(lines);
        if (group_similar_thr != 0)
            lines = group_similar(lines, group_similar_thr);
        return lines;
    }

    Point find_intersection_coords(Vec2f line1, Vec2f line2, int width, int height)
    {
        float rho1 = line1[0], theta1 = line1[1];
        float rho2 = line2[0], theta2 = line2[1];
        Mat A(2, 2, CV_32F);
        A.at<float>(0, 0) = cos(theta1);
        A.at<float>(0, 1) = sin(theta1);
        A.at<float>(1, 0) = cos(theta2);
        A.at<float>(1, 1) = sin(theta2);
        Mat b(2, 1, CV_32F);
        b.at<float>(0) = rho1;
        b.at<float>(1) = rho2;
        Mat x;
        solve(A, b, x);
        return Point(round(x.at<float>(0)), round(x.at<float>(1)));
    }

    bool already_present(Point coords, vector<map<int, vector<int>>> intersections)
    {
        for (map<int, vector<int>> intersection : intersections)
        {
            if (intersection["coords"][0] == coords.x && intersection["coords"][1] == coords.y)
                return true;
        }
        return false;
    }

    bool angles_are_similar(Vec2f line1, Vec2f line2, int angle_thr)
    {
        return lines_angle(line1, line2) < angle_thr;
    }

    bool coords_are_valid(Point coords, int width, int height)
    {
        return 0 < coords.x && coords.x < width && 0 < coords.y && coords.y < height;
    }

    vector<map<int, vector<int>>> find_intersections(vector<Vec2f> &lines, Mat im, int angle_thr = 45)
    {
        int height = im.rows;
        int width = im.cols;
        vector<map<int, vector<int>>> intersections;
        int vertex_id = 0;
        for (Vec2f line1 : lines)
        {
            for (Vec2f line2 : lines)
            {
                if (angles_are_similar(line1, line2, angle_thr))
                    continue;
                Point coords = find_intersection_coords(line1, line2, width, height);
                if (coords_are_valid(coords, width, height) && !already_present(coords, intersections))
                {
                    map<int, vector<int>> intersection;
                    intersection[vertex_id] = {line1[0], line1[1], line2[0], line2[1]};
                    intersection["coords"] = {coords.x, coords.y};
                    intersections.push_back(intersection);
                    vertex_id++;
                }
            }
        }
        return intersections;
    }

    bool common_line_exists(map<int, vector<int>> l1, map<int, vector<int>> l2)
    {
        set<int> s1(l1.begin(), l1.end());
        set<int> s2(l2.begin(), l2.end());
        set<int> common_lines = set_intersection(s1, s2);
        return !common_lines.empty();
    }

    map<int, vector<int>> build_graph(vector<map<int, vector<int>>> intersections)
    {
        map<int, vector<int>> graph;
        for (map<int, vector<int>> i1 : intersections)
        {
            for (map<int, vector<int>> i2 : intersections)
            {
                if (common_line_exists(i1, i2))
                    graph[i1["id"]].push_back(i2["id"]);
            }
        }
        return graph;
    }

    void add_if_loop(int current, map<int, vector<int>> neighbours, vector<int> &seen, vector<vector<int>> &cycles)
    {
        if (find(neighbours[current].begin(), neighbours[current].end(), seen[0]) != neighbours[current].end())
        {
            cycles.push_back(vector<int>(seen.begin(), seen.end()));
        }
    }

    void bounded_dfs(map<int, vector<int>> neighbours, int current, vector<vector<int>> &loops, vector<int> seen = {})
    {
        if (find(seen.begin(), seen.end(), current) != seen.end())
            return; // avoid loops
        seen.push_back(current);
        if (seen.size() == 4)
        { // found a loop of size 4
            add_if_loop(current, neighbours, seen, loops);
        }
        else
        {
            for (int neighbour : neighbours[current])
            {
                bounded_dfs(neighbours, neighbour, loops, seen); // recur for each neighbor
            }
        }
        seen.pop_back(); // backtrack
    }

    vector<Point> cycles2coords(vector<vector<int>> cycles, vector<map<int, vector<int>>> intersections)
    {
        vector<Point> result;
        for (vector<int> cycle : cycles)
        {
            vector<Point> rect;
            for (int node : cycle)
            {
                rect.push_back(intersections[node]["coords"]);
            }
            result.push_back(rect);
        }
        return result;
    }

    vector<vector<Point>> find_quadrilaterals(vector<map<int, vector<int>>> intersections)
    {
        map<int, vector<int>> graph = build_graph(intersections);
        vector<vector<int>> loops;
        for (auto node : graph)
            bounded_dfs(graph, node.first, loops);
        return cycles2coords(loops, intersections);
    }

    vector<vector<Point>> process(Mat im)
    {
        bitwise_not(im, im);
        Mat edges = detect_edges(im, 7);
        vector<Vec2f> lines_unique = detect_lines(edges);
        vector<map<int, vector<int>>> intersections = find_intersections(lines_unique, im);
        return find_quadrilaterals(intersections);
    }

    int area(vector<Point> rect)
    {
        auto x = rect[0].x;
        auto y = rect[0].y;
        int width = *max_element(rect.begin(), rect.end(), [](Point a, Point b)
                                 { return a.x < b.x; }) -
                    x;
        int height = *max_element(rect.begin(), rect.end(), [](Point a, Point b)
                                  { return a.y < b.y; }) -
                     y;
        return width * height;
    }

    void draw_rect(Mat im, vector<Point> rect, Scalar col = Scalar(255, 0, 0), int thickness = 5)
    {
        for (int i = 0; i < rect.size(); i++)
        {
            line(im, rect[i], rect[(i + 1) % rect.size()], col, thickness);
        }
    }

    Mat draw(vector<vector<Point>> rects, Mat im, bool debug = false)
    {
        if (rects.empty())
            return im;
        if (debug)
        {
            for (vector<Point> rect : rects)
                draw_rect(im, rect, Scalar(0, 255, 0), 2);
        }
        vector<Point> best = *max_element(rects.begin(), rects.end(), [](vector<Point> a, vector<Point> b)
                                          { return area(a) < area(b); });
        if (best.size())
            draw_rect(im, best);
        return im;
    }

    void cropImage(char *imagePath)
    {
        
        Mat img = imread(imagePath);
        vector<vector<Point>> res = process(img);
        Mat res2 = draw(res, img);
        // imwrite(imagePath, res2);
        // Mat img = imread(filename);

        // Mat gray;
        // cvtColor(img, gray, COLOR_BGR2GRAY);
        // medianBlur(gray, gray, 5);

        // Mat grad_x, grad_y, grad_mag;
        // Sobel(gray, grad_x, CV_64F, 1, 0);
        // Sobel(gray, grad_y, CV_64F, 0, 1);
        // magnitude(grad_x, grad_y, grad_mag);

        // Mat edges;
        // threshold(grad_mag, edges, 50, 255, THRESH_BINARY);
        // edges.convertTo(edges, CV_8U);

        // vector<vector<Point>> contours;
        // vector<Vec4i> hierarchy;
        // findContours(edges, contours, hierarchy, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);

        // int h = img.rows;
        // int w = img.cols;
        // int cx = w / 2;
        // int cy = h / 2;

        // vector<Point> max_contour;
        // double max_area = 0.0;
        // for (auto& c : contours) {
        //     double area = contourArea(c);
        //     if (area > max_area && pointPolygonTest(c, Point2f(cx, cy), true) >= 0) {
        //         max_area = area;
        //         max_contour = c;
        //     }
        // }

        // RotatedRect rect = minAreaRect(max_contour);
        // Point2f box_points[4];
        // rect.points(box_points);

        // int x1 = INT_MAX;
        // int x2 = INT_MIN;
        // int y1 = INT_MAX;
        // int y2 = INT_MIN;
        // for (int i = 0; i < 4; i++) {
        //     x1 = min(x1, (int)box_points[i].x);
        //     x2 = max(x2, (int)box_points[i].x);
        //     y1 = min(y1, (int)box_points[i].y);
        //     y2 = max(y2, (int)box_points[i].y);
        // }

        // Mat crop_img = img(Rect(x1, y1, x2 - x1 + 1, y2 - y1 + 1));

        // try
        // {
        //     // Read the image
        //     Mat img = imread(imagePath);
        //     if (img.empty())
        //     {
        //         throw runtime_error("Error reading image");
        //     }

        //     // Convert the image to grayscale
        //     Mat gray;
        //     cvtColor(img, gray, COLOR_BGR2GRAY);

        //     // Apply a median blur to the image to remove noise
        //     medianBlur(gray, gray, 5);

        //     // Compute the gradient magnitude of the image
        //     Mat grad_x, grad_y;
        //     Sobel(gray, grad_x, CV_64F, 1, 0);
        //     Sobel(gray, grad_y, CV_64F, 0, 1);
        //     Mat grad_mag;
        //     magnitude(grad_x, grad_y, grad_mag);

        //     // Threshold the gradient magnitude to detect edges
        //     Mat edges;
        //     threshold(grad_mag, edges, 50, 255, THRESH_BINARY);
        //     edges.convertTo(edges, CV_8U);

        //     // Find the contours in the edges image
        //     vector<vector<Point>> contours;
        //     vector<Vec4i> hierarchy;
        //     findContours(edges, contours, hierarchy, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);

        //     // Find the center of the image
        //     int cx = img.cols / 2;
        //     int cy = img.rows / 2;

        //     // Find the contour with the largest area that is also located near the center of the image
        //     vector<Point> c;
        //     double max_area = 0;
        //     for (const auto &contour : contours)
        //     {
        //         double area = contourArea(contour);
        //         if (area > max_area)
        //         {
        //             double dist = pointPolygonTest(contour, Point2f(cx, cy), true);
        //             if (dist >= 0)
        //             {
        //                 max_area = area;
        //                 c = contour;
        //             }
        //         }
        //     }

        //     if (c.empty())
        //     {
        //         // throw runtime_error("No suitable contour found");
        //         cout << "No countour found" << endl;
        //         imwrite(imagePath, img);

        //     }

        //     // Get a rotated bounding rectangle that better fits the selected contour
        //     RotatedRect rect = minAreaRect(c);
        //     vector<Point2f> box(4);
        //     rect.points(box.data());

        //     // Compute the coordinates of the bounding rectangle
        //     int x1 = static_cast<int>(min({box[0].x, box[1].x, box[2].x, box[3].x}));
        //     int x2 = static_cast<int>(max({box[0].x, box[1].x, box[2].x, box[3].x}));
        //     int y1 = static_cast<int>(min({box[0].y, box[1].y, box[2].y, box[3].y}));
        //     int y2 = static_cast<int>(max({box[0].y, box[1].y, box[2].y, box[3].y}));

        //     // Crop the image using the bounding rectangle
        //     Mat crop_img = img(Rect(x1, y1, x2 - x1 + 1, y2 - y1 + 1));

        //     // Write the cropped image to file
        //     // imwrite("cropped_image.jpg", crop_img);
        //     imwrite(imagePath, crop_img);
        // }
        // catch (const exception &e)
        // {
        //     cerr << "Error: " << e.what() << endl;
        //     // throw;
        // }
    }
}

// #include <opencv2/imgproc/imgproc.hpp>
// #include <opencv2/highgui/highgui.hpp>
// #include <iostream>

// extern "C"
// {

//     cv::Point2f center(0, 0);

//     cv::Point2f computeIntersect(cv::Vec4i a,
//                                  cv::Vec4i b)
//     {
//         int x1 = a[0], y1 = a[1], x2 = a[2], y2 = a[3], x3 = b[0], y3 = b[1], x4 = b[2], y4 = b[3];
//         float denom;

//         if (float d = ((float)(x1 - x2) * (y3 - y4)) - ((y1 - y2) * (x3 - x4)))
//         {
//             cv::Point2f pt;
//             pt.x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / d;
//             pt.y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / d;
//             return pt;
//         }
//         else
//             return cv::Point2f(-1, -1);
//     }

//     void sortCorners(std::vector<cv::Point2f> &corners,
//                      cv::Point2f center)
//     {
//         std::vector<cv::Point2f> top, bot;

//         for (int i = 0; i < corners.size(); i++)
//         {
//             if (corners[i].y < center.y)
//                 top.push_back(corners[i]);
//             else
//                 bot.push_back(corners[i]);
//         }
//         corners.clear();

//         if (top.size() == 2 && bot.size() == 2)
//         {
//             cv::Point2f tl = top[0].x > top[1].x ? top[1] : top[0];
//             cv::Point2f tr = top[0].x > top[1].x ? top[0] : top[1];
//             cv::Point2f bl = bot[0].x > bot[1].x ? bot[1] : bot[0];
//             cv::Point2f br = bot[0].x > bot[1].x ? bot[0] : bot[1];

//             corners.push_back(tl);
//             corners.push_back(tr);
//             corners.push_back(br);
//             corners.push_back(bl);
//         }
//     }

//     void cropImage(char *imagePath)
//     {
//         cv::Mat src = cv::imread(imagePath);
//         // if (src.empty())
//         // 	return -1;

//         cv::Mat bw;
//         cv::cvtColor(src, bw, cv::COLOR_BGR2GRAY);
//         cv::blur(bw, bw, cv::Size(3, 3));
//         cv::Canny(bw, bw, 100, 100, 3);

//         std::vector<cv::Vec4i> lines;
//         cv::HoughLinesP(bw, lines, 1, CV_PI / 180, 70, 30, 10);

//         // Expand the lines
//         for (int i = 0; i < lines.size(); i++)
//         {
//             cv::Vec4i v = lines[i];
//             lines[i][0] = 0;
//             lines[i][1] = ((float)v[1] - v[3]) / (v[0] - v[2]) * -v[0] + v[1];
//             lines[i][2] = src.cols;
//             lines[i][3] = ((float)v[1] - v[3]) / (v[0] - v[2]) * (src.cols - v[2]) + v[3];
//         }

//         std::vector<cv::Point2f> corners;
//         for (int i = 0; i < lines.size(); i++)
//         {
//             for (int j = i + 1; j < lines.size(); j++)
//             {
//                 cv::Point2f pt = computeIntersect(lines[i], lines[j]);
//                 if (pt.x >= 0 && pt.y >= 0)
//                     corners.push_back(pt);
//             }
//         }

//         std::vector<cv::Point2f> approx;
//         cv::approxPolyDP(cv::Mat(corners), approx, cv::arcLength(cv::Mat(corners), true) * 0.02, true);

//         if (approx.size() != 4)
//         {
//             std::cout << "The object is not quadrilateral!" << std::endl;
//             // return -1;
//         }

//         // Get mass center
//         for (int i = 0; i < corners.size(); i++)
//             center += corners[i];
//         center *= (1. / corners.size());

//         sortCorners(corners, center);
//         if (corners.size() == 0)
//         {
//             std::cout << "The corners were not sorted correctly!" << std::endl;
//             // return -1;
//         }
//         cv::Mat dst = src.clone();

//         // Draw lines
//         for (int i = 0; i < lines.size(); i++)
//         {
//             cv::Vec4i v = lines[i];
//             cv::line(dst, cv::Point(v[0], v[1]), cv::Point(v[2], v[3]), CV_RGB(0, 255, 0));
//         }

//         // Draw corner points
//         cv::circle(dst, corners[0], 3, CV_RGB(255, 0, 0), 2);
//         cv::circle(dst, corners[1], 3, CV_RGB(0, 255, 0), 2);
//         cv::circle(dst, corners[2], 3, CV_RGB(0, 0, 255), 2);
//         cv::circle(dst, corners[3], 3, CV_RGB(255, 255, 255), 2);

//         // Draw mass center
//         cv::circle(dst, center, 3, CV_RGB(255, 255, 0), 2);

//         cv::Mat quad = cv::Mat::zeros(300, 220, CV_8UC3);

//         std::vector<cv::Point2f> quad_pts;
//         quad_pts.push_back(cv::Point2f(0, 0));
//         quad_pts.push_back(cv::Point2f(quad.cols, 0));
//         quad_pts.push_back(cv::Point2f(quad.cols, quad.rows));
//         quad_pts.push_back(cv::Point2f(0, quad.rows));

//         cv::Mat transmtx = cv::getPerspectiveTransform(corners, quad_pts);
//         cv::warpPerspective(src, quad, transmtx, quad.size());

//         // cv::imshow("image", dst);
//         cv::imwrite(imagePath, quad);
//         // cv::waitKey();
//     }
// }
