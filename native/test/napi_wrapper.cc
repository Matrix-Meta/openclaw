#include <node/node.h>

// External Zig functions
extern "C" {
    int32_t add(int32_t a, int32_t b);
    int32_t multiply(int32_t a, int32_t b);
}

napi_value Add(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    int32_t a, b;
    napi_get_value_int32(env, argv[0], &a);
    napi_get_value_int32(env, argv[1], &b);
    
    int32_t result = add(a, b);
    
    napi_value result_val;
    napi_create_int32(env, result, &result_val);
    return result_val;
}

napi_value Multiply(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    int32_t a, b;
    napi_get_value_int32(env, argv[0], &a);
    napi_get_value_int32(env, argv[1], &b);
    
    int32_t result = multiply(a, b);
    
    napi_value result_val;
    napi_create_int32(env, result, &result_val);
    return result_val;
}

napi_value GetVersion(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "0.1.0", NAPI_AUTO_LENGTH, &result);
    return result;
}

NAPI_MODULE_INIT() {
    napi_property_descriptor desc[] = {
        { "add", nullptr, Add, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "multiply", nullptr, Multiply, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVersion", nullptr, GetVersion, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, 3, desc);
    return exports;
}
