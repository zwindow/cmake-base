# 防止重复包含
include_guard(GLOBAL)

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
