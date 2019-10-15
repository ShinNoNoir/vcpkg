include(vcpkg_common_functions)

set(PROJ4_VERSION 6.2.0)

vcpkg_download_distfile(ARCHIVE
    URLS "http://download.osgeo.org/proj/proj-${PROJ4_VERSION}.zip"
    FILENAME "proj-${PROJ4_VERSION}.zip"
    SHA512 415f9ab8ceabfa4fca344e639f7a5518c1aa9a002a15ab38c94688e8df75ebcc4b101e43a457cc9b0211de6c2a66712584065b24d59001cdb095a169210560ac
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${PROJ4_VERSION}
    PATCHES
         0001-CMake-find-sqlite3-bin.patch
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
  set(VCPKG_BUILD_SHARED_LIBS ON)
else()
  set(VCPKG_BUILD_SHARED_LIBS OFF)
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
    -DBUILD_LIBPROJ_SHARED=${VCPKG_BUILD_SHARED_LIBS}
    -DPROJ_LIB_SUBDIR=lib
    -DPROJ_INCLUDE_SUBDIR=include
    -DPROJ_DATA_SUBDIR=share/proj4
    -DBUILD_CS2CS=NO
    -DBUILD_PROJ=NO
    -DBUILD_GEOD=NO
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets()


# Install tools:
file(GLOB PROJ_TOOLS "${CURRENT_PACKAGES_DIR}/bin/*.exe")
file(GLOB PROJ_TOOLS_DLL "${CURRENT_PACKAGES_DIR}/bin/*.dll")
file(GLOB DBG_PROJ_TOOLS "${CURRENT_PACKAGES_DIR}/debug/bin/*.exe")
file(INSTALL ${PROJ_TOOLS} DESTINATION ${CURRENT_PACKAGES_DIR}/tools/${PORT})
file(INSTALL ${PROJ_TOOLS_DLL} DESTINATION ${CURRENT_PACKAGES_DIR}/tools/${PORT})
file(REMOVE ${PROJ_TOOLS})
file(REMOVE ${DBG_PROJ_TOOLS})

# Rename output files
if(NOT VCPKG_CMAKE_SYSTEM_NAME OR VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
        file(RENAME ${CURRENT_PACKAGES_DIR}/lib/proj_6_2.lib  ${CURRENT_PACKAGES_DIR}/lib/proj.lib)
    endif()
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
        file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/proj_6_2_d.lib  ${CURRENT_PACKAGES_DIR}/debug/lib/projd.lib)
    endif()
endif()


# Can't get CMAKECONFIGDIR to actually output .cmake files in the desired location,
# so let's do this manually.
# First merge the two lib/cmake dirs:
file(GLOB CMAKE_DBG_FILES "${CURRENT_PACKAGES_DIR}/debug/lib/cmake/proj4/*-debug.cmake")
file(COPY ${CMAKE_DBG_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/lib/cmake/proj4/)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/lib/cmake)
# Then move everything over to /share/proj4
file(GLOB CMAKE_FILES "${CURRENT_PACKAGES_DIR}/lib/cmake/proj4/*.cmake")
file(COPY ${CMAKE_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/share/proj4/)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/lib/cmake)

# Finally, adapt cmake configuration:
# 1. It's calling get_filename_component one time too many in targets:
foreach(CMAKE_TARGET_FILE "proj4-targets" "proj4-namespace-targets")
    file(READ ${CURRENT_PACKAGES_DIR}/share/proj4/${CMAKE_TARGET_FILE}.cmake _contents)
    string(REPLACE 
        "get_filename_component(_IMPORT_PREFIX \"\${CMAKE_CURRENT_LIST_FILE}\" PATH)"
        "set(_IMPORT_PREFIX \"\${CMAKE_CURRENT_LIST_FILE}\")"
        _contents "${_contents}"
    )
    file(WRITE ${CURRENT_PACKAGES_DIR}/share/proj4/${CMAKE_TARGET_FILE}.cmake "${_contents}")
endforeach()
# 2. Fix location of debug lib/bin and rename lib file:
foreach(CMAKE_TARGET_FILE "proj4-targets-debug" "proj4-namespace-targets-debug")
    file(READ ${CURRENT_PACKAGES_DIR}/share/proj4/${CMAKE_TARGET_FILE}.cmake _contents)
    string(REPLACE "\${_IMPORT_PREFIX}/" "\${_IMPORT_PREFIX}/debug/" _contents "${_contents}")
    string(REPLACE "proj_6_2_d.lib" "projd.lib" _contents "${_contents}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/share/proj4/${CMAKE_TARGET_FILE}.cmake "${_contents}")
endforeach()
# 3. Also rename lib file for release mode:
foreach(CMAKE_TARGET_FILE "proj4-targets-release" "proj4-namespace-targets-release")
    file(READ ${CURRENT_PACKAGES_DIR}/share/proj4/${CMAKE_TARGET_FILE}.cmake _contents)
    string(REPLACE "proj_6_2.lib" "proj.lib" _contents "${_contents}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/share/proj4/${CMAKE_TARGET_FILE}.cmake "${_contents}")
endforeach()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/proj4 RENAME copyright)
