cmake_minimum_required(VERSION 3.10)
project(Assignment1 VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories for the whole project
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Add subdirectories
#add_subdirectory(src)
add_subdirectory(app)