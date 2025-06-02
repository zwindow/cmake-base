### Git 基础项目与 CMake 公共函数集成方案

为了实现一个可复用的 CMake 基础项目，我们可以创建一个包含公共函数、宏和环境变量定义的 Git 仓库，然后通过 Git 子模块或直接引用的方式在多个子项目中使用这些公共资源。下面我将详细介绍如何设计和实现这样的系统。

### 项目结构设计

首先，让我们设计基础项目的结构：

    cmake-base/                # 基础项目仓库
    ├── cmake/                 # CMake 模块目录
    │   ├── Functions.cmake    # 公共函数定义
    │   ├── Macros.cmake       # 公共宏定义
    │   ├── Toolchains/        # 工具链文件
    │   └── Modules/           # 自定义模块
    ├── env/                   # 环境变量配置
    │   ├── common.env.cmake   # 通用环境配置
    │   ├── dev.env.cmake      # 开发环境配置
    │   └── prod.env.cmake     # 生产环境配置
    ├── templates/             # 项目模板
    │   └── project_template/
    ├── tests/                 # 测试用例
    └── CMakeLists.txt         # 基础项目CMake配置

### 基础项目实现

#### 1. 公共函数定义

在 `cmake/Functions.cmake` 中定义公共函数：

```cmake
# cmake/Functions.cmake

# 设置项目版本
function(set_project_version PROJECT_NAME)
    set(VERSION_MAJOR 1 CACHE STRING "Project major version")
    set(VERSION_MINOR 0 CACHE STRING "Project minor version")
    set(VERSION_PATCH 0 CACHE STRING "Project patch version")
    
    set(${PROJECT_NAME}_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}" PARENT_SCOPE)
    message(STATUS "Setting ${PROJECT_NAME} version to ${${PROJECT_NAME}_VERSION}")
endfunction()

# 添加编译器警告选项
function(add_compiler_warnings TARGET)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(${TARGET} PRIVATE 
            -Wall 
            -Wextra 
            -Wpedantic 
            -Wconversion 
            -Wsign-conversion
        )
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
        target_compile_options(${TARGET} PRIVATE 
            /W4 
            /permissive-
        )
    endif()
endfunction()

# 添加代码覆盖率支持
function(enable_code_coverage TARGET)
    if(CMAKE_BUILD_TYPE MATCHES "Debug" AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(${TARGET} PRIVATE --coverage)
        target_link_options(${TARGET} PRIVATE --coverage)
        message(STATUS "Code coverage enabled for ${TARGET}")
    endif()
endfunction()

# 配置预处理器定义
function(configure_preprocessor_definitions TARGET)
    if(CMAKE_BUILD_TYPE MATCHES "Debug")
        target_compile_definitions(${TARGET} PRIVATE DEBUG_BUILD)
    else()
        target_compile_definitions(${TARGET} PRIVATE RELEASE_BUILD)
    endif()
    
    # 添加环境特定的定义
    if(DEFINED ENV_SPECIFIC_DEFINITIONS)
        target_compile_definitions(${TARGET} PRIVATE ${ENV_SPECIFIC_DEFINITIONS})
    endif()
endfunction()
```

#### 2. 环境变量配置

在 `env/common.env.cmake` 中定义通用环境变量：

```cmake
# env/common.env.cmake

# 项目通用配置
set(COMMON_CXX_STANDARD 17 CACHE STRING "Common C++ standard")
set(COMMON_BUILD_DIR "${CMAKE_BINARY_DIR}/build" CACHE PATH "Common build directory")
set(COMMON_INSTALL_DIR "${CMAKE_BINARY_DIR}/install" CACHE PATH "Common install directory")

# 依赖库路径
set(BOOST_ROOT "/opt/boost" CACHE PATH "Boost library root")
set(OPENSSL_ROOT_DIR "/opt/openssl" CACHE PATH "OpenSSL root directory")

# 编译器优化选项
set(COMMON_OPTIMIZATION_FLAGS "-O2" CACHE STRING "Common optimization flags")

# 环境特定变量（将根据不同环境覆盖）
set(ENV_SPECIFIC_DEFINITIONS "" CACHE STRING "Environment specific preprocessor definitions")
```

#### 3. 基础项目的 CMakeLists.txt

```cmake
# CMakeLists.txt

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
```

### 在子项目中使用基础项目

#### 1. 将基础项目添加为子模块

```bash
# 在子项目目录中执行
git submodule add <cmake-base-repo-url> cmake-base
```

#### 2. 子项目的 CMakeLists.txt

```cmake
# 子项目 CMakeLists.txt

cmake_minimum_required(VERSION 3.15)
project(MyProject)

# 添加基础项目路径
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake-base/cmake")

# 加载环境配置（选择合适的环境）
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake-base/env/common.env.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake-base/env/dev.env.cmake OPTIONAL)

# 设置项目版本
include(Functions)
set_project_version(${PROJECT_NAME})

# 设置C++标准
set(CMAKE_CXX_STANDARD ${COMMON_CXX_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 添加可执行文件
add_executable(my_app 
    src/main.cpp
    src/module1.cpp
    src/module2.cpp
)

# 使用公共函数配置目标
add_compiler_warnings(my_app)
enable_code_coverage(my_app)
configure_preprocessor_definitions(my_app)

# 设置构建目录和安装目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${COMMON_BUILD_DIR})
set(CMAKE_INSTALL_PREFIX ${COMMON_INSTALL_DIR})

# 安装目标
install(TARGETS my_app DESTINATION bin)
```

#### 3. 子项目的构建流程

```bash
# 初始化并更新子模块
git submodule init
git submodule update

# 创建构建目录
mkdir build && cd build

# 运行CMake，指定环境配置
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake-base/cmake/Toolchains/gcc.cmake

# 编译项目
cmake --build .

# 安装项目
cmake --install .
```

### 高级用法：自定义模块和工具链

#### 1. 自定义Find模块

在 `cmake/Modules/` 目录下创建自定义查找模块，例如 `FindMyLibrary.cmake`：

```cmake
# cmake/Modules/FindMyLibrary.cmake

find_path(MYLIBRARY_INCLUDE_DIR MyLibrary.h
    PATHS ${MYLIBRARY_ROOT}/include
    NO_DEFAULT_PATH
)

find_library(MYLIBRARY_LIBRARY NAMES MyLibrary
    PATHS ${MYLIBRARY_ROOT}/lib
    NO_DEFAULT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MyLibrary
    REQUIRED_VARS MYLIBRARY_LIBRARY MYLIBRARY_INCLUDE_DIR
)

if(MyLibrary_FOUND)
    set(MyLibrary_LIBRARIES ${MYLIBRARY_LIBRARY})
    set(MyLibrary_INCLUDE_DIRS ${MYLIBRARY_INCLUDE_DIR})
    
    if(NOT TARGET MyLibrary::MyLibrary)
        add_library(MyLibrary::MyLibrary UNKNOWN IMPORTED)
        set_target_properties(MyLibrary::MyLibrary PROPERTIES
            IMPORTED_LOCATION "${MYLIBRARY_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${MYLIBRARY_INCLUDE_DIR}"
        )
    endif()
endif()
```

#### 2. 跨平台工具链配置

在 `cmake/Toolchains/` 目录下创建工具链文件，例如 `arm-none-eabi.cmake`：

```cmake
# cmake/Toolchains/arm-none-eabi.cmake

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

# 指定交叉编译工具
set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(CMAKE_AR arm-none-eabi-ar)
set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
set(CMAKE_OBJDUMP arm-none-eabi-objdump)
set(CMAKE_STRIP arm-none-eabi-strip)

# 编译选项
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16")

# 搜索路径限制
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
```

### 总结

通过这种设计，您可以实现以下目标：

1.  **集中管理**：所有CMake相关的公共资源都集中在一个基础项目中
2.  **代码复用**：多个子项目可以共享相同的CMake配置
3.  **环境隔离**：通过不同的环境配置文件，可以轻松切换开发、测试和生产环境
4.  **标准化**：确保所有项目遵循相同的构建和测试标准
5.  **简化维护**：对公共函数和配置的修改只需在基础项目中进行一次

这种架构特别适合大型组织或多项目团队，可以显著提高开发效率并减少配置错误。
