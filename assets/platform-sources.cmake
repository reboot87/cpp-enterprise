# cpp-enterprise: pick exactly one platform backend.
#
# Usage (top-level CMakeLists.txt):
#   include(cmake/platform-sources.cmake)
#   engine_select_platform_sources(ENGINE_PLATFORM_SOURCES)
#   add_executable(app ${ENGINE_PLATFORM_SOURCES} ...)
#
# Assumed layout:
#   src/platform/common/*.cpp
#   src/platform/win32/*.cpp
#   src/platform/posix/*.cpp
#   src/platform/darwin/*.cpp   (optional; overrides same-named posix sources)
#
# GLOB CONFIGURE_DEPENDS keeps this template small. Replace the glob with an
# explicit source list once the platform source set must be auditable.

function(engine_select_platform_sources out_var)
  set(base "${CMAKE_CURRENT_SOURCE_DIR}/src/platform")

  if(WIN32)
    set(os_name win32)
  else()
    set(os_name posix)
  endif()

  set(os_dir "${base}/${os_name}")
  if(NOT EXISTS "${os_dir}")
    message(FATAL_ERROR
      "cpp-enterprise: no platform directory ${os_dir}. "
      "Create src/platform/${os_name} or adjust the layout.")
  endif()

  file(GLOB sources CONFIGURE_DEPENDS "${os_dir}/*.cpp")

  # darwin/ overrides a subset of posix/: keep posix sources, replace by basename.
  if(APPLE AND EXISTS "${base}/darwin")
    file(GLOB overlay_sources CONFIGURE_DEPENDS "${base}/darwin/*.cpp")
    foreach(overlay IN LISTS overlay_sources)
      get_filename_component(name "${overlay}" NAME)
      list(REMOVE_ITEM sources "${os_dir}/${name}")
      list(APPEND sources "${overlay}")
    endforeach()
  endif()

  if(EXISTS "${base}/common")
    file(GLOB common_sources CONFIGURE_DEPENDS "${base}/common/*.cpp")
    list(APPEND sources ${common_sources})
  endif()

  if(NOT sources)
    message(FATAL_ERROR "cpp-enterprise: ${os_dir} contains no .cpp files.")
  endif()

  set(${out_var} ${sources} PARENT_SCOPE)
endfunction()
