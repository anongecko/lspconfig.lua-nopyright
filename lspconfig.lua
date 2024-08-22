local lspconfig = require "lspconfig"
local nvlsp = require "nvchad.configs.lspconfig"

-- Function to find project root directory
local function find_root_dir(fname)
  return lspconfig.util.root_pattern("venv", "pyproject.toml", "setup.py", ".git", "main.py", "requirements.txt")(fname)
    or vim.fn.getcwd()
end

-- Function to terminate Pylyzer
local function terminate_pylyzer()
  local handle = io.popen "pgrep -f pylyzer"
  if handle then
    local result = handle:read "*a"
    handle:close()
    for pid in result:gmatch "%S+" do
      os.execute("kill -15 " .. pid) -- Use SIGTERM for cleaner shutdown
    end
  end
end

-- Common on_attach function
local function on_attach(client, bufnr)
  nvlsp.on_attach(client, bufnr)
  -- Add any additional on_attach functionality here
end

-- Configuration for Pylyzer
lspconfig.pylyzer.setup {
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = terminate_pylyzer,
    })
  end,
  capabilities = nvlsp.capabilities,
  filetypes = { "python" },
  root_dir = find_root_dir,
  single_file_support = false,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "strict",
        diagnostics = true,
        inlayHints = true,
        smartCompletion = true,
        useLibraryCodeForTypes = true,
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        reportUnknownMemberType = "error",
        reportUnknownVariableType = "error",
        reportUnknownArgumentType = "error",
        reportPrivateUsage = "error",
        reportUnusedImport = "error",
        reportGeneralTypeIssues = "error",
        reportOptionalMemberAccess = "error",
        reportOptionalSubscript = "error",
        reportOptionalCall = "error",
        reportOptionalIterable = "error",
        reportOptionalContextManager = "error",
        reportOptionalOperand = "error",
        reportTypedDictNotRequiredAccess = "error",
        reportUnnecessaryCast = "error",
        reportUnnecessaryComparison = "error",
        reportUnnecessaryContains = "error",
        reportCallInDefaultInitializer = "error",
        reportUnnecessaryIsInstance = "error",
        reportUnusedCallResult = "error",
      },
    },
  },
}

-- Configuration for Ruff LSP
lspconfig.ruff.setup {
  on_attach = on_attach,
  capabilities = nvlsp.capabilities,
  filetypes = { "python" },
  root_dir = find_root_dir,
  single_file_support = false,
  init_options = {
    settings = {
      run = "onType",
      args = {
        "--select=ALL",
        "--ignore=E501", -- Ignore line length errors (handled by formatter)
      },
      fixAll = true,
      organizeImports = true,
      codeAction = {
        disableRuleComment = {
          enable = true,
        },
        fixViolation = {
          enable = true,
        },
        convertCommentType = {
          enable = true,
        },
      },
    },
  },
}

-- Configuration for Python Language Server (Pylsp)
lspconfig.pylsp.setup {
  on_attach = on_attach,
  capabilities = nvlsp.capabilities,
  filetypes = { "python" },
  root_dir = find_root_dir,
  single_file_support = false,
  settings = {
    pylsp = {
      plugins = {
        -- Disable redundant linters (covered by Ruff)
        pycodestyle = { enabled = false },
        mccabe = { enabled = false },
        pyflakes = { enabled = true }, -- Re-enabled for import checking
        flake8 = { enabled = false },
        -- Enable Jedi for advanced code intelligence
        jedi_completion = { enabled = true, fuzzy = true },
        jedi_hover = { enabled = true },
        jedi_references = { enabled = true },
        jedi_signature_help = { enabled = true },
        jedi_symbols = { enabled = true, all_scopes = true },
        -- Enable Rope for refactoring support
        rope_completion = { enabled = true },
        rope_autoimport = { enabled = true },
        -- Disable formatters (we're using separate formatters)
        yapf = { enabled = false },
        autopep8 = { enabled = false },
        -- Configure Pylint to disable docstring warnings
        pylint = {
          enabled = true,
          args = { "--disable=C0114,C0115,C0116" },
          executable = "pylint",
        },
        -- Enable pydocstyle for docstring checks, but disable module and function docstring warnings
        pydocstyle = {
          enabled = true,
          ignore = { "D100", "D101", "D102", "D103" },
        },
        -- Enable preload for better performance
        preload = { enabled = true },
        -- Enable Mypy plugin for additional type checking
        pylsp_mypy = {
          enabled = true,
          live_mode = true,
          strict = true,
        },
      },
    },
  },
}
-- Configuration for Jedi Language Server
lspconfig.jedi_language_server.setup {
  on_attach = on_attach,
  capabilities = nvlsp.capabilities,
  filetypes = { "python" },
  root_dir = find_root_dir,
  single_file_support = false,
  init_options = {
    diagnostics = {
      enable = true,
      didOpen = true,
      didChange = true,
      didSave = true,
    },
    completion = {
      disableSnippets = false,
      resolveEagerly = true,
    },
    workspace = {
      extraPaths = {},
      symbols = {
        maxSymbols = 20,
      },
    },
    jediSettings = {
      autoImportModules = {},
      caseInsensitiveCompletion = true,
      debug = false,
    },
  },
}
