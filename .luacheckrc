max_line_length = 200

stds.lua = {
    read_globals = {"unpack", "math"}
}

stds.yfrit = {
    read_globals = {"async", "makeAsync", "optionalRequire", "mockRequire", "unmockRequire"}
}

stds.love = {
    read_globals = {"love"}
}

std = "min+lua+yfrit+love"

ignore = {
    "self"
}
