#include <node/node.h>
#include <stdint.h>

// External Zig functions
extern "C" {
    void* createByteBudget(uint64_t max_entry_bytes, uint64_t max_extracted_bytes);
    void startEntry(void* budget);
    int addBytes(void* budget, uint64_t bytes);
    int addEntrySize(void* budget, uint64_t size);
    void freeBudget(void* budget);
    int validateEntryPath(const char* path);
}

napi_value CreateBudget(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    uint64_t max_entry, max_extract;
    
    // Get as regular int64 and convert
    int64_t val1, val2;
    napi_get_value_int64(env, argv[0], &val1);
    napi_get_value_int64(env, argv[1], &val2);
    max_entry = (uint64_t)(val1 > 0 ? val1 : 0);
    max_extract = (uint64_t)(val2 > 0 ? val2 : 0);
    
    void* budget = createByteBudget(max_entry, max_extract);
    
    napi_value js_result;
    napi_create_bigint_uint64(env, (uint64_t)budget, &js_result);
    return js_result;
}

napi_value StartEntry(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    uint64_t ptr;
    napi_status status = napi_get_value_bigint_uint64(env, argv[0], &ptr, nullptr);
    if (status != napi_ok) {
        // Try as regular number
        int64_t val;
        napi_get_value_int64(env, argv[0], &val);
        ptr = (uint64_t)val;
    }
    
    startEntry((void*)ptr);
    
    napi_value js_result;
    napi_get_undefined(env, &js_result);
    return js_result;
}

napi_value AddBytes(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    uint64_t ptr, bytes;
    
    int64_t val1, val2;
    napi_get_value_int64(env, argv[0], &val1);
    napi_get_value_int64(env, argv[1], &val2);
    ptr = (uint64_t)val1;
    bytes = (uint64_t)(val2 > 0 ? val2 : 0);
    
    int result = addBytes((void*)ptr, bytes);
    
    napi_value js_result;
    napi_create_int32(env, result, &js_result);
    return js_result;
}

napi_value AddEntrySize(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    uint64_t ptr, size;
    
    int64_t val1, val2;
    napi_get_value_int64(env, argv[0], &val1);
    napi_get_value_int64(env, argv[1], &val2);
    ptr = (uint64_t)val1;
    size = (uint64_t)(val2 > 0 ? val2 : 0);
    
    int result = addEntrySize((void*)ptr, size);
    
    napi_value js_result;
    napi_create_int32(env, result, &js_result);
    return js_result;
}

napi_value FreeBudget(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    uint64_t ptr;
    int64_t val;
    napi_get_value_int64(env, argv[0], &val);
    ptr = (uint64_t)val;
    
    freeBudget((void*)ptr);
    
    napi_value js_result;
    napi_get_undefined(env, &js_result);
    return js_result;
}

napi_value ValidatePath(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    char path[4096];
    size_t len;
    napi_get_value_string_utf8(env, argv[0], path, sizeof(path), &len);
    
    int valid = validateEntryPath(path);
    
    napi_value js_result;
    napi_get_boolean(env, valid, &js_result);
    return js_result;
}

napi_value GetVersion(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "0.1.0-archive", NAPI_AUTO_LENGTH, &result);
    return result;
}

NAPI_MODULE_INIT() {
    napi_property_descriptor desc[] = {
        { "createBudget", nullptr, CreateBudget, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "startEntry", nullptr, StartEntry, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "addBytes", nullptr, AddBytes, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "addEntrySize", nullptr, AddEntrySize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "freeBudget", nullptr, FreeBudget, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "validatePath", nullptr, ValidatePath, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVersion", nullptr, GetVersion, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, 7, desc);
    return exports;
}
