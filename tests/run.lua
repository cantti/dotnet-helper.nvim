package.path = "./tests/?.lua;./tests/?/init.lua;./lua/?.lua;./lua/?/init.lua;" .. package.path

local harness = require("harness")

require("utils_dotnet10_spec")
require("utils_filter_output_spec")

harness.finish()
