#include <opencv2/opencv.hpp>
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/highgui.hpp>
#include <vector>
#include <cmath>
#include <iostream>
#include <vector>
#include <string>
#include <unordered_map>
#include <algorithm>
#include <any>

using namespace cv;
using namespace std;

std::vector<std::vector<cv::Point>> _find_characters(cv::Mat im, int max_area)
{
    cv::Ptr<cv::MSER> mser = cv::MSER::create(5, 60, max_area);
    cv::Mat gray;
    cv::cvtColor(im, gray, cv::COLOR_BGR2GRAY);
    std::vector<vector<Point>> characters;
    vector<cv::Rect> mser_bbox;
    mser->detectRegions(gray, characters, mser_bbox);
    return characters;
}

void _remove_characters(std::vector<std::vector<cv::Point>> characters, cv::Mat mask)
{
    for (auto &character : characters)
    {
        for (auto &point : character)
        {
            int x = point.x;
            int y = point.y;
            mask.at<uchar>(y, x) = 0;
        }
    }
}

vector<Vec2f> _group_similar(vector<Vec2f> &lines, float thr)
{
    sort(lines.begin(), lines.end(), [](Vec2f a, Vec2f b)
         { return a[0] < b[0]; });
    vector<Vec2f> lines_unique;
    for (const auto &to_add : lines)
    {
        if (lines_unique.empty())
        {
            lines_unique.push_back(to_add);
        }
        else
        {
            bool is_duplicate = false;
            for (const auto &unique_line : lines_unique)
            {
                if (abs(to_add[0] - unique_line[0]) < thr && abs(to_add[1] - unique_line[1]) < thr)
                {
                    is_duplicate = true;
                    break;
                }
            }
            if (!is_duplicate)
            {
                lines_unique.push_back(to_add);
            }
        }
    }
    return lines_unique;
}

vector<Vec2f> _cvhoughlines2list(vector<Vec2f> &lines)
{
    vector<Vec2f> lines_list;
    for (const auto &line : lines)
    {
        lines_list.push_back(Vec2f(line[0], line[1]));
    }
    return lines_list;
}

vector<Vec2f> detect_lines(Mat im, float hough_thr = 65, float group_similar_thr = 30)
{
    vector<Vec2f> lines;
    HoughLines(im, lines, 1, CV_PI / 90, hough_thr);
    if (lines.empty())
    {
        return {};
    }
    lines = _cvhoughlines2list(lines);

    if (group_similar_thr != 0)
    {
        lines = _group_similar(lines, group_similar_thr);
    }
    return lines;
}

cv::Mat detect_edges(cv::Mat im, int blur_radius = 0, int thr1 = 100, int thr2 = 200, bool remove_text = true)
{
    cv::Mat saturation;
    cv::cvtColor(im, saturation, cv::COLOR_BGR2HSV);
    std::vector<cv::Mat> hsv_channels;
    cv::split(saturation, hsv_channels);
    saturation = hsv_channels[2];
    if (blur_radius != 0)
    {
        cv::medianBlur(saturation, saturation, blur_radius);
    }

    cv::Mat edges;
    cv::Canny(saturation, edges, thr1, thr2);

    if (remove_text)
    {

        int height = im.rows;
        int width = im.cols;

        std::vector<std::vector<cv::Point>> characters = _find_characters(im, static_cast<int>((width * height) / 1e2));
        _remove_characters(characters, edges);
    }
    return edges;
}

float lines_angle(Vec2f line1, Vec2f line2)
{
    return abs(line1[1] - line2[1]) * 180 / CV_PI;
}

bool _angles_are_similar(Vec2f line1, Vec2f line2, float angle_thr)
{
    return lines_angle(line1, line2) < angle_thr;
}

cv::Point2f _find_intersection_coords(cv::Vec2f line1, cv::Vec2f line2)
{
    float rho1 = line1[0], theta1 = line1[1];
    float rho2 = line2[0], theta2 = line2[1];
    cv::Mat a = (cv::Mat_<float>(2, 2) << cos(theta1), sin(theta1), cos(theta2), sin(theta2));
    cv::Mat b = (cv::Mat_<float>(2, 1) << rho1, rho2);
    cv::Mat x;
    cv::solve(a, b, x, cv::DECOMP_SVD);
    float x_val = x.at<float>(0, 0), y_val = x.at<float>(1, 0);
    return cv::Point2f(round(x_val), round(y_val));
}

bool _coords_are_valid(cv::Point2f coords, int width, int height)
{
    return coords.x > 0 && coords.x < width && coords.y > 0 && coords.y < height;
}

template <typename T>
T any_cast(const any &operand)
{
    if (operand.type() != typeid(T))
    {
        throw bad_any_cast();
    }
    return *reinterpret_cast<const T *>(std::addressof(operand));
}

bool common_line_exists(std::vector<cv::Vec2f> &lines1, std::vector<cv::Vec2f> &lines2)
{

    for (const auto &line1 : lines1)
    {
        for (const auto &line2 : lines2)
        {
            if (line1[0] == line2[0] && line1[1] == line2[1])
            {
                return true;
            }
        }
    }

    return false;
}

map<int, vector<int>> build_graph(vector<map<string, any>> &intersections)
{
    map<int, vector<int>> graph;

    for (auto intersection1 : intersections)
    {
        for (auto intersection2 : intersections)
        {
            if (intersection1["id"].type() == typeid(int) && intersection2["id"].type() == typeid(int) &&
                any_cast<int>(intersection1["id"]) != any_cast<int>(intersection2["id"]) &&
                intersection1["lines"].type() == typeid(std::vector<cv::Vec2f>) && intersection2["lines"].type() == typeid(std::vector<cv::Vec2f>) &&
                common_line_exists(any_cast<std::vector<cv::Vec2f> &>(intersection1["lines"]), any_cast<std::vector<cv::Vec2f> &>(intersection2["lines"])))
            {
                graph[any_cast<int>(intersection1["id"])].push_back(any_cast<int>(intersection2["id"]));
            }
        }
    }

    return graph;
}

void _add_if_loop(int current, map<int, vector<int>> &neighbours, vector<int> &seen, vector<tuple<int, int, int, int>> &cycles)
{
    if (find(neighbours[current].begin(), neighbours[current].end(), seen[0]) != neighbours[current].end())
    {
        cycles.push_back(make_tuple(seen[0], seen[1], seen[2], seen[3]));
    }
}

void _bounded_dfs(map<int, vector<int>> &neighbours, int current, vector<tuple<int, int, int, int>> &loops, vector<int> &seen)
{

    if (find(seen.begin(), seen.end(), current) != seen.end())
    {
        return;
    }
    seen.push_back(current);
    if (seen.size() == 4)
    {
        _add_if_loop(current, neighbours, seen, loops);
    }
    else
    {
        for (auto neighbour : neighbours[current])
        {
            _bounded_dfs(neighbours, neighbour, loops, seen);
        }
    }
    seen.pop_back();
}

cv::Point2f _node2coords(int node, std::vector<std::map<std::string, std::any>> &intersections)
{
    for (auto corner : intersections)
    {
        if (std::any_cast<int>(corner["id"]) == node)
        {
            return std::any_cast<cv::Point2f>(corner["coords"]);
        }
    }
    throw std::runtime_error("Intersection not found for node");
}

std::vector<std::vector<cv::Point2f>> _cycles2coords(std::vector<std::tuple<int, int, int, int>> &cycles, std::vector<std::map<std::string, std::any>> &intersections)
{
    std::vector<std::vector<cv::Point2f>> result;

    for (const auto &quadrilateral : cycles)
    {
        std::vector<cv::Point2f> quadrilateral_coords;
        /*  for (int i = 0; i < 4; i++) {
              int node = std::get<0>(quadrilateral);
              cv::Point2f coords = _node2coords(node, intersections);
              quadrilateral_coords.push_back(coords);
          }*/
        int node1 = std::get<0>(quadrilateral);
        cv::Point2f coords1 = _node2coords(node1, intersections);
        quadrilateral_coords.push_back(coords1);
        int node2 = std::get<1>(quadrilateral);
        cv::Point2f coords2 = _node2coords(node2, intersections);
        quadrilateral_coords.push_back(coords2);
        int node3 = std::get<2>(quadrilateral);
        cv::Point2f coords3 = _node2coords(node3, intersections);
        quadrilateral_coords.push_back(coords3);
        int node4 = std::get<3>(quadrilateral);
        cv::Point2f coords4 = _node2coords(node4, intersections);
        quadrilateral_coords.push_back(coords4);

        result.push_back(quadrilateral_coords);
    }

    return result;
}

std::vector<std::vector<cv::Point2f>> find_quadrilaterals(vector<map<string, any>> &intersections)
{
    map<int, vector<int>> graph = build_graph(intersections);

    vector<tuple<int, int, int, int>> loops;
    for (const auto &[node, neighbors] : graph)
    {
        vector<int> seen;
        _bounded_dfs(graph, node, loops, seen);
    }

    return _cycles2coords(loops, intersections);
}

std::pair<int, int> _find_intersection_coords(std::pair<double, double> line1, std::pair<double, double> line2)
{
    double rho1, theta1, rho2, theta2;
    std::tie(rho1, theta1) = line1;
    std::tie(rho2, theta2) = line2;

    double cos_theta1 = std::cos(theta1);
    double sin_theta1 = std::sin(theta1);
    double cos_theta2 = std::cos(theta2);
    double sin_theta2 = std::sin(theta2);

    double det = cos_theta1 * sin_theta2 - sin_theta1 * cos_theta2;
    if (std::abs(det) < 1e-6)
    {
        // singular matrix
        return {-1, -1};
    }

    double inv_det = 1.0 / det;
    double x = (rho2 * sin_theta1 - rho1 * sin_theta2) * inv_det;
    double y = (-rho2 * cos_theta1 + rho1 * cos_theta2) * inv_det;

    return {static_cast<int>(std::round(x)), static_cast<int>(std::round(y))};
}

bool _already_present(const cv::Point2f &coords, const std::vector<cv::Point2f> &intersections)
{
    for (const auto &intersection : intersections)
    {
        if (intersection == coords)
        {
            return true;
        }
    }
    return false;
}

std::vector<std::map<std::string, std::any>> find_intersections(std::vector<cv::Vec2f> &lines, cv::Mat &im, double angle_thr = 45)
{
    int height = im.rows, width = im.cols;
    std::vector<std::map<std::string, std::any>> intersections;

    std::vector<cv::Point2f> intersections_coord;

    int vertex_id = 0;

    for (int i = 0; i < lines.size(); i++)
    {
        for (int j = i + 1; j < lines.size(); j++)
        {

            cv::Vec2f line1 = lines[i], line2 = lines[j];
            if (_angles_are_similar(line1, line2, angle_thr))
            {
                continue;
            }
            cv::Point2f coords = _find_intersection_coords(line1, line2);
            if (_coords_are_valid(coords, width, height) && !_already_present(coords, intersections_coord))
            {
                std::map<std::string, std::any> intersection;
                intersections_coord.push_back(coords);
                intersection["id"] = vertex_id;
                intersection["lines"] = std::vector<cv::Vec2f>{line1, line2};
                intersection["coords"] = coords;
                intersections.push_back(intersection);
                vertex_id++;
            }
        }
    }

    return intersections;
}

double _area(const std::vector<cv::Point2f> &rect)
{
    std::vector<double> x, y;
    for (const auto &p : rect)
    {
        x.push_back(p.x);
        y.push_back(p.y);
    }
    double width = *std::max_element(x.begin(), x.end()) - *std::min_element(x.begin(), x.end());
    double height = *std::max_element(y.begin(), y.end()) - *std::min_element(y.begin(), y.end());
    return width * height;
}

void draw_rect(cv::Mat &im, const std::vector<cv::Point2f> &rect, const cv::Scalar &col = cv::Scalar(255, 0, 0), int thickness = 5)
{
    for (int i = 0; i < rect.size(); i++)
    {
        cv::line(im, rect[i], rect[(i + 1) % rect.size()], col, thickness);
    }
}

cv::Mat draw(const std::vector<std::vector<cv::Point2f>> &rects, cv::Mat &im, bool debug = false)
{
    if (rects.empty())
    {
        return im;
    }
    if (debug)
    {
        for (const auto &rect : rects)
        {
            draw_rect(im, rect, cv::Scalar(0, 255, 0), 2);
        }
    }
    std::vector<cv::Point2f> best = *std::max_element(rects.begin(), rects.end(), [](const std::vector<cv::Point2f> &rect1, const std::vector<cv::Point2f> &rect2)
                                                      { return _area(rect1) < _area(rect2); });
    if (!best.empty())
    {
        draw_rect(im, best);
    }
    return im;
}

cv::Mat crop_image(const std::vector<std::vector<cv::Point2f>> &rects, cv::Mat &im, bool debug = false)
{
    if (rects.empty())
    {
        return im;
    }
    if (debug)
    {
        for (const auto &rect : rects)
        {
            draw_rect(im, rect, cv::Scalar(0, 255, 0), 2);
        }
    }
    std::vector<cv::Point2f> best = *std::max_element(rects.begin(), rects.end(), [](const std::vector<cv::Point2f> &rect1, const std::vector<cv::Point2f> &rect2)
                                                      { return _area(rect1) < _area(rect2); });
    if (!best.empty())
    {
        cv::Rect roi_rect = cv::boundingRect(best);
        cv::Mat cropped_im = im(roi_rect);
        return cropped_im;
    }
    return im;
}

// std::vector<std::vector<cv::Point2f>> convert_rects(const std::vector<std::vector<std::pair<double, double>>>& rects) {
//     std::vector<std::vector<cv::Point2f>> output;
//     for (const auto& rect : rects) {
//         std::vector<cv::Point2f> cv_rect;
//         for (const auto& point : rect) {
//             cv_rect.emplace_back(point.first, point.second);
//         }
//         output.push_back(cv_rect);
//     }
//     return output;
// }

void cropImage(char *imagePath)
{
    Mat im = imread(imagePath);
    Mat inverted_im;
    bitwise_not(im, inverted_im);
    Mat edges = detect_edges(inverted_im, 7);
    std::vector<cv::Vec2f> lines = detect_lines(edges);
    std::vector<std::map<std::string, std::any>> _intersections = find_intersections(lines, im);
    std::vector<std::vector<cv::Point2f>> rects = find_quadrilaterals(_intersections);
    // cv::Mat res = draw(rects, im);
    cv::Mat res = crop_image(rects, im);
    // cv::Mat res2;
    // res.convertTo(res2, CV_16F, 1.0 / 255, 0);
    // normalize(res, res2, 1.0, 0.0, NORM_MINMAX);
    // res2 = resize(res2,(512,512));

    cv::imwrite(imagePath, res);
}
