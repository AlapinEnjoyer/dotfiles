hl.config({
    dwindle = {
        preserve_split = true,
    },
})

-- `dwindle.pseudotile` was removed in 0.55. The bind now relies on the
-- window pseudo dispatcher directly.

-- Example master layout override:
-- hl.config({
--     master = {
--         new_status = "master",
--     },
-- })
