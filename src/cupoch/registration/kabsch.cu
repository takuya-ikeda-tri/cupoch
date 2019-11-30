#include "cupoch/registration/kabsch.h"
#include "cupoch/utility/svd3_cuda.h"
#include <Eigen/Geometry>
#include <thrust/reduce.h>
#include <thrust/inner_product.h>

using namespace cupoch;
using namespace cupoch::registration;

namespace {

struct outer_product_functor {
    outer_product_functor(const Eigen::Vector3f_u& x_offset, const Eigen::Vector3f_u& y_offset)
        : x_offset_(x_offset), y_offset_(y_offset) {};
    const Eigen::Vector3f_u x_offset_;
    const Eigen::Vector3f_u y_offset_;
    __device__
    Eigen::Matrix3f_u operator() (const Eigen::Vector3f_u x, const Eigen::Vector3f_u& y) const {
        const Eigen::Vector3f_u centralized_x = x - x_offset_;
        const Eigen::Vector3f_u centralized_y = y - y_offset_;
        Eigen::Matrix3f_u ans = centralized_x * centralized_y.transpose();
        return ans;
    }
};

}

Eigen::Matrix4f_u cupoch::registration::Kabsch(const thrust::device_vector<Eigen::Vector3f_u>& model,
                                               const thrust::device_vector<Eigen::Vector3f_u>& target) {
    //Compute the center
    Eigen::Vector3f_u model_center = thrust::reduce(model.begin(), model.end(), Eigen::Vector3f_u(0.0, 0.0, 0.0));
    Eigen::Vector3f_u target_center = thrust::reduce(target.begin(), target.end(), Eigen::Vector3f_u(0.0, 0.0, 0.0));
    float divided_by = 1.0f / model.size();
    model_center *= divided_by;
    target_center *= divided_by;

    //Centralize them
    //Compute the H matrix
    outer_product_functor func(model_center, target_center);
    const Eigen::Matrix3f_u init = Eigen::Matrix3f_u::Zero();
    Eigen::Matrix3f_u hh = thrust::inner_product(model.begin(), model.end(), target.begin(), init,
                                                 thrust::plus<Eigen::Matrix3f_u>(), func);

    //Do svd
    hh /= model.size();
    Eigen::Matrix3f uu, ss, vv;
    svd(hh(0, 0), hh(0, 1), hh(0, 2), hh(1, 0), hh(1, 1), hh(1, 2), hh(2, 0), hh(2, 1), hh(2, 2),
        uu(0, 0), uu(0, 1), uu(0, 2), uu(1, 0), uu(1, 1), uu(1, 2), uu(2, 0), uu(2, 1), uu(2, 2),
        ss(0, 0), ss(0, 1), ss(0, 2), ss(1, 0), ss(1, 1), ss(1, 2), ss(2, 0), ss(2, 1), ss(2, 2),
        vv(0, 0), vv(0, 1), vv(0, 2), vv(1, 0), vv(1, 1), vv(1, 2), vv(2, 0), vv(2, 1), vv(2, 2));
    ss = Eigen::Matrix3f::Identity();
    ss(2, 2) = (uu * vv).determinant();
    Eigen::Matrix4f_u tr = Eigen::Matrix4f_u::Identity();
    tr.block<3, 3>(0, 0) = vv * ss * uu.transpose();

    //The translation
    tr.block<3, 1>(0, 3) = target_center;
    tr.block<3, 1>(0, 3) -= tr.block<3, 3>(0, 0) * model_center;

    return tr;
}
