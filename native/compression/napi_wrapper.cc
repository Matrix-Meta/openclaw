#include <node/node.h>
#include <cstring>
#include <cstdlib>

// External Zig functions
extern "C" {
    int extractArchive(const char* archive_path, const char* dest_dir);
    int getEntryCount(const char* archive_path);
    int validateArchive(const char* archive_path);
}

napi_value ExtractArchive(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    char archive_path[4096];
    char dest_dir[4096];
    size_t len1, len2;
    
    napi_get_value_string_utf8(env, argv[0], archive_path, sizeof(archive_path), &len1);
    napi_get_value_string_utf8(env, argv[1], dest_dir, sizeof(dest_dir), &len2);
    
    int result = extractArchive(archive_path, dest_dir);
    
    napi_value js_result;
    napi_create_int32(env, result, &js_result);
    return js_result;
}

napi_value GetEntryCount(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    char archive_path[4096];
    size_t len;
    napi_get_value_string_utf8(env, argv[0], archive_path, sizeof(archive_path), &len);
    
    int count = getEntryCount(archive_path);
    
    napi_value js_result;
    napi_create_int32(env, count, &js_result);
    return js_result;
}

napi_value ValidateArchive(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    char archive_path[4096];
    size_t len;
    napi_get_value_string_utf8(env, argv[0], archive_path, sizeof(archive_path), &len);
    
    int valid = validateArchive(archive_path);
    
    napi_value js_result;
    napi_get_boolean(env, valid == 0, &js_result);
    return js_result;
}

napi_value GetVersion(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "0.1.0-compression", NAPI_AUTO_LENGTH, &result);
    return result;
}

NAPI_MODULE_INIT() {
    napi_property_descriptor desc[] = {
        { "extractArchive", nullptr, ExtractArchive, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getEntryCount", nullptr, GetEntryCount, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "validateArchive", nullptr, ValidateArchive, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVersion", nullptr, GetVersion, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, 4, desc);
    return exports;
}
