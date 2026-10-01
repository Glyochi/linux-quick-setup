 return {
    "vinnymeller/swagger-preview.nvim",
    dependencies = {
      {
        "moon0326/swagger-ui-watcher",
        opts = { input = {}, picker = {}, terminal = {} },
      },
    },
    cmd = { "SwaggerPreview", "SwaggerPreviewStop", "SwaggerPreviewToggle" },
    build = "npm i",
    config = true,
  }
