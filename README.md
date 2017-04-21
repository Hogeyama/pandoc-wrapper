
# pandoc-wrapper

Simple wrapper for [pandoc](http://pandoc.org/).

## Usage

Write command-line options for pandoc in `pandoc_opts_` field in YAML data block:

```markdown:sample.md

---
title:       'sample'
author:      'Hogeyama'
pandoc_opts_:
  - -f markdown+lists_without_preceding_blankline+ignore_line_breaks
  - -t beamer
  - -o slide.tex
---

# 1st slide

+ foo
+ bar

# 2nd slide

...

```

Then simply run `pandoc-wrapper sample.md`.

