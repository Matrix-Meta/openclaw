// Direct test without building
import { createRequire } from "module";
const require = createRequire(import.meta.url);

// Try loading if it exists
try {
  const mod = require("./build/Release/zig_test.node");
  console.log("Module loaded:", mod);
  console.log("add(2,3):", mod.add(2, 3));
  console.log("multiply(2,3):", mod.multiply(2, 3));
  console.log("version:", mod.getVersion());
} catch (e) {
  console.log("Module not found - need to build first");
  console.log("Error:", e.message);
}
