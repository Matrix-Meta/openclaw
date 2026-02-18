{
  "targets": [
    {
      "target_name": "zig_test",
      "sources": [
        "napi_wrapper.cc"
      ],
      "include_dirs": [
        "<!(node -p \"process.config.variables.node_include_dir\")",
        "/usr/include/c++/15.2.1",
        "/usr/include/c++/15.2.1/x86_64-pc-linux-gnu"
      ],
      "libraries": [
        "-L. -lzig_add"
      ],
      "cflags_cc": [
        "-std=c++17"
      ],
      "defines": [
        "NAPI_DISABLE_CPP_EXCEPTIONS"
      ]
    }
  ]
}
