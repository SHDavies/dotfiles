-- Session persistence - saves/restores tabpages, working directories, and window layouts
return {
  'rmagatti/auto-session',
  opts = {
    auto_restore_enabled = true,
    auto_save_enabled = true,
    auto_session_use_git_branch = true,

    session_lens = {
      load_on_setup = false,
    },

    pre_save_cmds = {},
    post_restore_cmds = {},
  },
}
