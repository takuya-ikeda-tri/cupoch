#include <gtest/gtest.h>
#include "cupoch/utility/device_vector.h"

int main(int argc, char **argv) {
    testing::InitGoogleTest(&argc, argv);
    cupoch::utility::InitializeAllocator();

    return RUN_ALL_TESTS();
}