# Common Ambient Variables:
#   CURRENT_BUILDTREES_DIR    = ${VCPKG_ROOT_DIR}\buildtrees\${PORT}
#   CURRENT_PACKAGES_DIR      = ${VCPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
#   CURRENT_PORT_DIR          = ${VCPKG_ROOT_DIR}\ports\${PORT}
#   PORT                      = current port name (zlib, etc)
#   TARGET_TRIPLET            = current triplet (x86-windows, x64-windows-static, etc)
#   VCPKG_CRT_LINKAGE         = C runtime linkage type (static, dynamic)
#   VCPKG_LIBRARY_LINKAGE     = target library linkage type (static, dynamic)
#   VCPKG_ROOT_DIR            = <C:\path\to\current\vcpkg>
#   VCPKG_TARGET_ARCHITECTURE = target architecture (x64, x86, arm)
#

include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/liblas-1.8.1)
vcpkg_download_distfile(ARCHIVE
    URLS "https://github.com/libLAS/libLAS/archive/1.8.1.zip"
    FILENAME "liblas-1.8.1.zip"
    SHA512 ab66a1e972898e6cb017111cf92518c58b35a61cc28e6932031867df84abc81d65d8965bede49f99fc7941b1917107e1cba5d1c45af26720765407ee55a05c51
)
vcpkg_extract_source_archive(${ARCHIVE})

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA # Disable this option if project cannot be built with Ninja
    OPTIONS
        -DBUILD_OSGEO4W=OFF
)

vcpkg_install_cmake()

# Remove debug includes
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

# Move executables
file(GLOB BINARY_TOOLS "${CURRENT_PACKAGES_DIR}/bin/*.exe")
file(COPY ${BINARY_TOOLS} DESTINATION ${CURRENT_PACKAGES_DIR}/tools/liblas)
vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/liblas)
file(REMOVE ${BINARY_TOOLS})
file(GLOB BINARY_TOOLS "${CURRENT_PACKAGES_DIR}/debug/bin/*.exe")
file(REMOVE ${BINARY_TOOLS})

# Fix capitalization of cmake files: liblas -> libLAS
foreach(BUILD_TYPE "/debug" "")
    file(GLOB CMAKE_FILES "${CURRENT_PACKAGES_DIR}${BUILD_TYPE}/cmake/*.cmake")
    foreach(CMAKE_FILE IN LISTS CMAKE_FILES)
        string(REPLACE "liblas" "libLAS" CMAKE_FILE_PROPERLY_CASED "${CMAKE_FILE}")
        file(RENAME ${CMAKE_FILE} ${CMAKE_FILE_PROPERLY_CASED})
    endforeach()
endforeach()

# Install cmake files
file(GLOB CMAKE_FILES "${CURRENT_PACKAGES_DIR}/debug/cmake/*.cmake")
file(INSTALL ${CMAKE_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/share/liblas)
file(GLOB CMAKE_FILES "${CURRENT_PACKAGES_DIR}/cmake/*.cmake")
file(INSTALL ${CMAKE_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/share/liblas)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/cmake ${CURRENT_PACKAGES_DIR}/debug/cmake)

# Fix cmake relative path
file(READ ${CURRENT_PACKAGES_DIR}/share/liblas/libLAS-depends.cmake _contents)
string(REPLACE
    "get_filename_component(_IMPORT_PREFIX \"\${_IMPORT_PREFIX}\" PATH)"
    "get_filename_component(_IMPORT_PREFIX \"\${_IMPORT_PREFIX}\" PATH)\nget_filename_component(_IMPORT_PREFIX \"\${_IMPORT_PREFIX}\" PATH)"
    _contents
    "${_contents}"
)
file(WRITE ${CURRENT_PACKAGES_DIR}/share/liblas/libLAS-depends.cmake "${_contents}")


# Move and cleanup doc files
file(RENAME ${CURRENT_PACKAGES_DIR}/doc ${CURRENT_PACKAGES_DIR}/share/liblas/doc)  
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/doc)  

# Handle copyright
configure_file(${SOURCE_PATH}/LICENSE.txt ${CURRENT_PACKAGES_DIR}/share/liblas/copyright COPYONLY) 

# Post-build test for cmake libraries (note the capitalization of libLAS!)
vcpkg_test_cmake(PACKAGE_NAME libLAS)
