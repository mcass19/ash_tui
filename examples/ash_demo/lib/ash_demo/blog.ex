defmodule AshDemo.Blog do
  use Ash.Domain

  resources do
    resource AshDemo.Blog.Post
    resource AshDemo.Blog.Comment
    resource AshDemo.Blog.Tag
    resource AshDemo.Blog.PostTag
  end
end
