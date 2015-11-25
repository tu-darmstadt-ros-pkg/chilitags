################################################################################
#   Copyright 2013-2014 EPFL                                                   #
#   Copyright 2013-2014 Quentin Bonnard                                        #
#                                                                              #
#   This file is part of chilitags.                                            #
#                                                                              #
#   Chilitags is free software: you can redistribute it and/or modify          #
#   it under the terms of the Lesser GNU General Public License as             #
#   published by the Free Software Foundation, either version 3 of the         #
#   License, or (at your option) any later version.                            #
#                                                                              #
#   Chilitags is distributed in the hope that it will be useful,               #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#   GNU Lesser General Public License for more details.                        #
#                                                                              #
#   You should have received a copy of the GNU Lesser General Public License   #
#   along with Chilitags.  If not, see <http://www.gnu.org/licenses/>.         #
################################################################################

cmake_minimum_required(VERSION 2.8)

project(chilitags)

set(CPACK_PACKAGE_VERSION_MAJOR "2")
set(CPACK_PACKAGE_VERSION_MINOR "0")
set(CPACK_PACKAGE_VERSION_PATCH "0")
CMAKE_MINIMUM_REQUIRED (VERSION 2.8.3)
SET(CMAKE_VERBOSE_MAKEFILE ON)


add_definitions(-std=c++11)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")
find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})
message(STATUS "OpenCV version: ${OpenCV_VERSION}")

##########################################
##           Options                   ###
##########################################

option(WITH_SAMPLES                     "Build demos" OFF)
option(WITH_TESTS                       "Build tests" OFF)

if(DEFINED ANDROID) #OPENCV has a nice macro for this: OCV_OPTION, consider using it.
    option(WITH_PTHREADS                "Multithreading support with pthreads" ON)
    option(WITH_TOOLS                   "provides the marker generation tool" OFF)

    #Set Android install path
    set(ANDROID_PROJECT_ROOT "/path/to/android/project" CACHE STRING "The path to the root of the target Android project")

    #Environment variables required by OpenCV for Android
    if(NOT DEFINED ENV{ANDROID_STANDALONE_TOOLCHAIN})
        message(FATAL_ERROR "Please set the ANDROID_STANDALONE_TOOLCHAIN environment variable to your standalone toolchain root first, e.g /opt/android-toolchain")
    endif()
    if(NOT DEFINED ENV{ANDROID_NATIVE_API_LEVEL})
        message(FATAL_ERROR "Please set the ANDROID_NATIVE_API_LEVEL environment variable first, e.g 14")
    endif()
    if(NOT DEFINED ENV{ANDROID_ABI})
        message(FATAL_ERROR "Please define the ANDROID_ABI environment variable first, e.g armeabi-v7a")
    endif()
    if(NOT DEFINED ENV{ANDROID_TOOLCHAIN_NAME})
        message(FATAL_ERROR "Please define the ANDROID_TOOLCHAIN_NAME environment variable first, e.g arm-linux-androideabi-4.8")
    endif()
elseif(UNIX)
    option(WITH_PTHREADS                "Multithreading support with pthreads" ON)
    option(WITH_TOOLS                   "provides the marker generation tool" ON)
else()
    option(WITH_PTHREADS                "Multithreading support with pthreads" OFF)
    option(WITH_TOOLS                   "provides the marker generation tool" ON)
endif()

##########################################
##           Chilitags lib             ###
##########################################

if(WITH_PTHREADS)
    add_definitions(-DHAS_MULTITHREADING)
endif()

if(${OpenCV_VERSION} VERSION_GREATER 2.9.0)
    add_definitions(-DOPENCV3)
endif()

# Add Sources
SET(SOURCES  ${PROJECT_SOURCE_DIR}/src/Chilitags3D.cpp
             ${PROJECT_SOURCE_DIR}/src/Chilitags.cpp
             ${PROJECT_SOURCE_DIR}/src/Codec.cpp
             ${PROJECT_SOURCE_DIR}/src/Codec.hpp
             ${PROJECT_SOURCE_DIR}/src/Decode.cpp
             ${PROJECT_SOURCE_DIR}/src/Decode.hpp
             ${PROJECT_SOURCE_DIR}/src/Detect.cpp
             ${PROJECT_SOURCE_DIR}/src/Detect.hpp
             ${PROJECT_SOURCE_DIR}/src/EnsureGreyscale.cpp
             ${PROJECT_SOURCE_DIR}/src/EnsureGreyscale.hpp
             ${PROJECT_SOURCE_DIR}/src/EstimatePose3D.cpp
             ${PROJECT_SOURCE_DIR}/src/EstimatePose3D.hpp
             ${PROJECT_SOURCE_DIR}/src/Filter3D.cpp
             ${PROJECT_SOURCE_DIR}/src/Filter3D.hpp
             ${PROJECT_SOURCE_DIR}/src/Filter.cpp
             ${PROJECT_SOURCE_DIR}/src/Filter.hpp
             ${PROJECT_SOURCE_DIR}/src/FindQuads.cpp
             ${PROJECT_SOURCE_DIR}/src/FindQuads.hpp
             ${PROJECT_SOURCE_DIR}/src/GrowRoi.cpp
             ${PROJECT_SOURCE_DIR}/src/GrowRoi.hpp
             ${PROJECT_SOURCE_DIR}/src/ReadBits.cpp
             ${PROJECT_SOURCE_DIR}/src/ReadBits.hpp
             ${PROJECT_SOURCE_DIR}/src/Refine.cpp
             ${PROJECT_SOURCE_DIR}/src/Refine.hpp
             ${PROJECT_SOURCE_DIR}/src/ScreenOut.cpp
             ${PROJECT_SOURCE_DIR}/src/ScreenOut.hpp
             ${PROJECT_SOURCE_DIR}/src/Track.cpp
             ${PROJECT_SOURCE_DIR}/src/Track.hpp)
INCLUDE_DIRECTORIES(include src)
ADD_LIBRARY(${PROJECT_NAME} SHARED ${SOURCES})
TARGET_LINK_LIBRARIES(${PROJECT_NAME} ${OpenCV_LIBS})

##########################################
##           Modules                   ###
##########################################

#include("${CMAKE_SOURCE_DIR}/cmake/TargetDoc.cmake" OPTIONAL)

if (WITH_TOOLS)
    add_subdirectory(tools)
endif()

if (WITH_SAMPLES)
    add_subdirectory(samples)
endif()

if(WITH_TESTS)
    add_subdirectory(test)
endif()

if(WITH_JNI_BINDINGS)
    add_subdirectory(platforms/jni/src)
endif()

if(ANDROID_INSTALL_LIBRARIES)
    if(NOT ANDROID_PROJECT_ROOT)
        message(FATAL_ERROR "ANDROID_PROJECT_ROOT undefined, can't install libraries inside Android project.")
    endif()
endif()



################################################################################
# Create the chilitagsConfig.cmake file for other cmake projects.
GET_TARGET_PROPERTY( FULL_LIBRARY_NAME ${PROJECT_NAME} LOCATION )
SET(chilitags_LIBRARIES ${FULL_LIBRARY_NAME} )
SET(chilitags_LIBRARY_DIR ${PROJECT_BINARY_DIR} )
SET(chilitags_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/include")
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/chilitagsConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/chilitagsConfig.cmake @ONLY IMMEDIATE )
export( PACKAGE chilitags )

INSTALL(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_PREFIX}/include FILES_MATCHING PATTERN "*.hpp" )
INSTALL(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib )
