return {
  "neovim/nvim-lspconfig",
  opts = {
    -- Inline diagnostics are drawn by tiny-inline-diagnostic.nvim
    -- (plugins/tiny-inline-diagnostic.lua), which wraps long messages.
    diagnostics = {
      virtual_text = false,
    },
    servers = {
      -- Use the qt6-declarative-provided qmlls (qmlls6 on Arch), not mason's:
      -- mason ships a statically-linked "standalone" nightly build whose
      -- bundled qmltypes parser doesn't understand the metadata format the
      -- installed Qt (6.11.2) tooling emits, spamming bogus import/type
      -- errors. qmlls6 is built against the exact same Qt libs that generate
      -- /usr/lib/qt6/qml's .qmltypes files, so there's no version skew, and
      -- it already knows the default import path (which is also where
      -- Quickshell's custom modules — Quickshell, Quickshell.Io, ... — live,
      -- since Quickshell installs alongside Qt).
      qmlls = {
        cmd = { "qmlls6" },
      },
    },
  },
}
