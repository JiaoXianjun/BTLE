# Copyright 2012 Jared Boone
# Copyright 2013 Benjamin Vernoux
#
# This file is part of HackRF and BladeRF.
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

set(INSTALL_DEFAULT_BINDIR "bin" CACHE STRING "Appended to CMAKE_INSTALL_PREFIX")

if(MSVC)
add_library(libgetopt_static STATIC
    ../getopt/getopt.c
)
endif()

add_executable(btle_tx btle_tx.c)
install(TARGETS btle_tx RUNTIME DESTINATION ${INSTALL_DEFAULT_BINDIR})

add_executable(btle_rx btle_rx.c)
install(TARGETS btle_rx RUNTIME DESTINATION ${INSTALL_DEFAULT_BINDIR})

IF (USE_BLADERF MATCHES 1)
include_directories(${LIBBLADERF_INCLUDE_DIR})
LIST(APPEND TOOLS_LINK_LIBS ${LIBBLADERF_LIBRARIES})
ELSE (USE_BLADERF MATCHES 1)
include_directories(${LIBHACKRF_INCLUDE_DIR})
LIST(APPEND TOOLS_LINK_LIBS ${LIBHACKRF_LIBRARIES})
ENDIF (USE_BLADERF MATCHES 1)

IF(NOT DEFINED C_INLINE)
   ADD_DEFINITIONS("-Dinline=")
ENDIF(NOT DEFINED C_INLINE)

if(MSVC)
LIST(APPEND TOOLS_LINK_LIBS libgetopt_static)
endif()

target_link_libraries(btle_tx ${TOOLS_LINK_LIBS} m)

target_link_libraries(btle_rx ${TOOLS_LINK_LIBS} m)

# MESSAGE(STATUS "1")
# MESSAGE(STATUS ${LIBBLADERF_LIBRARIES})
# MESSAGE(STATUS "2")
