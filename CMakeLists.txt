cmake_minimum_required(VERSION 3.15)
project(CMakeBase LANGUAGES NONE)

# 添加CMake模块路径
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules")

# 导出基础项目配置
install(
    DIRECTORY cmake env templates
    DESTINATION .
)

# 测试配置
enable_testing()
add_subdirectory(tests)
