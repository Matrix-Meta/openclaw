#include <node/node.h>
#include <cstring>
#include <cstdlib>

// External Zig functions
extern "C" {
    int isPathSafe(const char* resolved_path, const char* root_with_sep);
    int openFile(const char* path, int no_follow);
    int closeFile(int fd);
    void freeMem(void* ptr);
}

napi_value IsPathSafe(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    char resolved[4096], root[4096];
    size_t len1, len2;
    napi_get_value_string_utf8(env, argv[0], resolved, sizeof(resolved), &len1);
    napi_get_value_string_utf8(env, argv[1], root, sizeof(root), &len2);
    
    int safe = isPathSafe(resolved, root);
    
    napi_value js_result;
    napi_get_boolean(env, safe, &js_result);
    return js_result;
}

napi_value OpenFile(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    char path[4096];
    size_t path_len;
    napi_get_value_string_utf8(env, argv[0], path, sizeof(path), &path_len);
    
    bool no_follow;
    napi_get_value_bool(env, argv[1], &no_follow);
    
    int fd = openFile(path, no_follow ? 1 : 0);
    
    napi_value js_result;
    napi_create_int32(env, fd, &js_result);
    return js_result;
}

napi_value CloseFile(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    int32_t fd;
    napi_get_value_int32(env, argv[0], &fd);
    
    int result = closeFile(fd);
    
    napi_value js_result;
    napi_create_int32(env, result, &js_result);
    return js_result;
}

napi_value GetVersion(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "0.1.0-fs-safe", NAPI_AUTO_LENGTH, &result);
    return result;
}

NAPI_MODULE_INIT() {
    napi_property_descriptor desc[] = {
        { "isPathSafe", nullptr, IsPathSafe, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "openFile", nullptr, OpenFile, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "closeFile", nullptr, CloseFile, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVersion", nullptr, GetVersion, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, 4, desc);
    return exports;
}
