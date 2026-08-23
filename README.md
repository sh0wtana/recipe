# 🍳 Recipe Memo

A private recipe notebook.

## Features

- Write a recipe as ingredients and steps, adding and removing rows as you go
- One photo per recipe, HEIC included, resized on upload
- Tag recipes and manage the tag list on its own page
- Search across titles, ingredient names, and tags
- Japanese UI throughout
- Sign in and password reset, with every recipe scoped to its owner

## Tech Stack

- [Rails 8.1](https://rubyonrails.org) + SQLite
- [Hotwire](https://hotwired.dev) (Turbo + Stimulus) with importmap
- [Tailwind CSS v4](https://tailwindcss.com) + [daisyUI](https://daisyui.com)
- Active Storage + [libvips](https://www.libvips.org) for photo variants
- [Ransack](https://github.com/activerecord-hackery/ransack) for search, [Pagy](https://github.com/ddnexus/pagy) for pagination
- Deployed on [Fly.io](https://fly.io)
