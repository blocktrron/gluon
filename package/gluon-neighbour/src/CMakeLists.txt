cmake_minimum_required(VERSION 3.5)

PROJECT(utils C)
INCLUDE(GNUInstallDirs)
ADD_DEFINITIONS(-Os -Wall -Werror --std=gnu99)

SET(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")

ADD_LIBRARY(neighbour-info SHARED neighbour-info.c)
SET_TARGET_PROPERTIES(neighbour-info PROPERTIES PREFIX "")
TARGET_LINK_LIBRARIES(neighbour-info ubox)


INSTALL(TARGETS neighbour-info LIBRARY DESTINATION lib)