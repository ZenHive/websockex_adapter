# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [Styler],
  import_deps: [:stream_data],
  locals_without_parens: [
    defrpc: 2,
    defrpc: 3
  ]
]
