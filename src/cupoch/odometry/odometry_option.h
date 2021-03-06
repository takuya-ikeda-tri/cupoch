#pragma once

#include <vector>

namespace cupoch {
namespace odometry {

class OdometryOption {
public:
    OdometryOption(
            const std::vector<int> &iteration_number_per_pyramid_level =
                    {20, 10,
                     5} /* {smaller image size to original image size} */,
            float max_depth_diff = 0.03,
            float min_depth = 0.0,
            float max_depth = 4.0)
        : iteration_number_per_pyramid_level_(
                  iteration_number_per_pyramid_level),
          max_depth_diff_(max_depth_diff),
          min_depth_(min_depth),
          max_depth_(max_depth) {}
    ~OdometryOption() {}

public:
    std::vector<int> iteration_number_per_pyramid_level_;
    float max_depth_diff_;
    float min_depth_;
    float max_depth_;
};

}  // namespace odometry
}  // namespace cupoch