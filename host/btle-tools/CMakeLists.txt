# Copyright 2012 Jared Boone
# Copyright 2013 Benjamin Vernoux
#
# This file is part of HackRF and bladeRF
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.
#

# Based heavily upon the libftdi cmake setup.

cmake_minimum_required(VERSION 2.8)
project(btle-tools C)
set(MAJOR_VERSION 0)
set(MINOR_VERSION 5)
set(PACKAGE btle-tools)
set(VERSION_STRING ${MAJOR_VERSION}.${MINOR_VERSION})
set(VERSION ${VERSION_STRING})
set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/../cmake/modules)

if(MSVC)
# include_directories(getopt)
add_definitions(/D _CRT_SECURE_NO_WARNINGS)
else()
add_definitions(-Wall)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu90")
endif()

MESSAGE(STATUS "Checking BLADERF lib ...")
find_package(LIBBLADERF)
IF (LIBBLADERF_FOUND)
  include_directories(${LIBBLADERF_INCLUDE_DIR})
  set(LIBBLADERF_FOUND_RESULT "1")
  MESSAGE(STATUS "LIBBLADERF_FOUND_RESULT 1")
ELSE (LIBBLADERF_FOUND)
  set(LIBBLADERF_FOUND_RESULT "0")
  MESSAGE(STATUS "LIBBLADERF_FOUND_RESULT 0")
ENDIF (LIBBLADERF_FOUND)

MESSAGE(STATUS "Checking HACKRF lib ...")
find_package(LIBHACKRF)
IF (LIBHACKRF_FOUND)
  include_directories(${LIBHACKRF_INCLUDE_DIR})
  set(LIBHACKRF_FOUND_RESULT "1")
  MESSAGE(STATUS "LIBHACKRF_FOUND_RESULT 1")
ELSE (LIBHACKRF_FOUND)
  set(LIBHACKRF_FOUND_RESULT "0")
  MESSAGE(STATUS "LIBHACKRF_FOUND_RESULT 0")
ENDIF (LIBHACKRF_FOUND)

MESSAGE(STATUS "Checking UHD lib ...")
find_package(UHD)
IF (LIBUHD_FOUND)
  include_directories(${UHD_INCLUDE_DIRS})
  set(LIBUHD_FOUND_RESULT "1")
  MESSAGE(STATUS "LIBUHD_FOUND_RESULT 1")
ELSE (LIBUHD_FOUND)
  set(LIBUHD_FOUND_RESULT "0")
  MESSAGE(STATUS "LIBUHD_FOUND_RESULT 0")
ENDIF (LIBUHD_FOUND)

CONFIGURE_FILE (
  "${PROJECT_SOURCE_DIR}/rf_driver/rf_driver_cfg.h.in"
  "${PROJECT_SOURCE_DIR}/rf_driver/rf_driver_cfg.h"
)

include_directories(rf_driver)
include_directories(btle_lib)
########################################################################
# compile setup
########################################################################
set(INSTALL_DEFAULT_BINDIR "bin" CACHE STRING "Appended to CMAKE_INSTALL_PREFIX")

if(MSVC)
add_library(libgetopt_static STATIC
    ../getopt/getopt.c
)
endif()

add_executable(btle_tx btle_tx.c)
install(TARGETS btle_tx RUNTIME DESTINATION ${INSTALL_DEFAULT_BINDIR})

add_executable(btle_rx btle_rx.c common_misc.c rf_driver/rf_driver_bladerf.c rf_driver/rf_driver_hackrf.c rf_driver/rf_driver_usrp.c rf_driver/rf_driver_top.c btle_lib/btle_lib.c)
install(TARGETS btle_rx RUNTIME DESTINATION ${INSTALL_DEFAULT_BINDIR})

IF (LIBBLADERF_FOUND)
    include_directories(${LIBBLADERF_INCLUDE_DIR})
    LIST(APPEND TOOLS_LINK_LIBS ${LIBBLADERF_LIBRARIES})
ENDIF (LIBBLADERF_FOUND)

IF (LIBHACKRF_FOUND)
    include_directories(${LIBHACKRF_INCLUDE_DIR})
    LIST(APPEND TOOLS_LINK_LIBS ${LIBHACKRF_LIBRARIES})
ENDIF (LIBHACKRF_FOUND)

IF (LIBUHD_FOUND)
    include_directories(${UHD_INCLUDE_DIRS})
    LIST(APPEND TOOLS_LINK_LIBS ${UHD_LIBRARIES})
ENDIF (LIBUHD_FOUND)

IF(NOT DEFINED C_INLINE)
   ADD_DEFINITIONS("-Dinline=")
ENDIF(NOT DEFINED C_INLINE)

if(MSVC)
LIST(APPEND TOOLS_LINK_LIBS libgetopt_static)
endif()

target_link_libraries(btle_tx ${TOOLS_LINK_LIBS} m -lpthread)

target_link_libraries(btle_rx ${TOOLS_LINK_LIBS} m -lpthread)

########################################################################
# Create uninstall target
########################################################################

if(NOT btle_all_SOURCE_DIR)
configure_file(
    ${PROJECT_SOURCE_DIR}/../cmake/cmake_uninstall.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake
@ONLY)


add_custom_target(uninstall
    ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake
)
endif()

########################################################################
# Install udev rules
########################################################################
option(INSTALL_UDEV_RULES "Install udev rules for HackRF" OFF)
if (INSTALL_UDEV_RULES)
    install (
        FILES 52-hackrf.rules
        DESTINATION "/etc/udev/rules.d"
        COMPONENT "udev"
        )
else (INSTALL_UDEV_RULES)
    message (STATUS "Udev rules not being installed, install them with -DINSTALL_UDEV_RULES=ON")
endif (INSTALL_UDEV_RULES)
