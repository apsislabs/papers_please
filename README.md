# papers_please

A roles and permissions gem from Apsis Labs.

**NOTE**: Still under heavy development, definitely not suitable for anything remotely resembling production usage. Very unlikely to even work.


## Example

```ruby
# app/policies/access_policy.rb
class AccessPolicy < PapersPlease::Policy
  def configure
    # Define your roles
    role :super, (proc { |u| u.super? })
    role :admin, (proc { |u| u.admin? })
    role :member, (proc { |u| u.member? })
    role :guest

    permit :super do |role|
      role.grant [:manage], User
    end

    permit :admin, :super do |role|
      role.grant [:manage, :archive], Post
    end

    permit :member do |role|
      role.grant [:create], Post
      role.grant [:update, :read], Post, query: (proc { |u| u.posts })
      role.grant [:archive], Post, query: (proc { |u| u.posts }), predicate: (proc { |u, post| !post.archived? })
    end

    permit :guest do |role|
      role.grant [:read], Post, predicate: (proc { |u, post| !post.archived? })
    end

    permit :member, :guest do |role|
      role.grant [:read], Attachment, granted_by: (proc { |u, attachment| attachment.post })
    end
  end
end

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  # GET /posts
  def index
    @posts = policy.query(:read, Post)
    render json: @posts
  end

  # GET /posts/:id
  def show
    @post = Post.find(params[:id])
    policy.authorize! :read, @post

    render json: @post
  end

  # POST /posts/:id/archive
  def archive
    @post = Post.find(params[:id])
    policy.authorize! :archive, @post

    @post.update!(archived: true)
    render json: @post
  end
end

class AttachmentsController < ApplicationController
  # GET /attachments/:id
  def show
    @attachment = Attachment.find([:id])
    policy.authorize! :read, @attachment # => proxied to Post permission check

    send_data @attachment.data, type: @attachment.content_type
  end
end
```

## A helpful CLI

```bash
$ rails papers_please:roles

# =>
# | role    | permission | object |
# | :------ | :--------- | :----- |
# | :admin  | :create    | Post   |
# |         | :read      | Post   |
# |         | :update    | Post   |
# |         | :destroy   | Post   |
# |         | :archive   | Post   |
# |         |            |        |
# | :member | :create    | Post   |
# |         | :read      | Post   |
# |         | :update    | Post   |
# |         | :archive   | Post   |
# |         |            |        |
# | :guest  | :read      | Post   |

$ rails papers_please:annotate [app/policies/access_policy.rb]

# => output roles table to top of AccessPolicy file
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'papers_please'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install papers_please

## Usage

TODO: Write usage instructions here

## Theory

The structure of `papers_please` is very simple. At its core, it is a mechanism for storing and retrieving `Procs`. In an authorization context, these `Procs` answer two questions:

1.  Given a specific user and a specific permission, which objects am I allowed to operate on?
2.  Given a specific user and a specific object, do I have a specific permission?

The machinery of `papers_please` tries to simplify the organization and subsequent access to these questions as much as possible.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wkirby/papers_please.

## Special Thanks

This owes its existence to [`AccessGranted`](https://github.com/chaps-io/access-granted). Thanks!

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

# Built by Apsis

[![apsis](https://s3-us-west-2.amazonaws.com/apsiscdn/apsis.png)](https://www.apsis.io)

`papers_please` was built by Apsis Labs. We love sharing what we build! Check out our [other libraries on Github](https://github.com/apsislabs), and if you like our work you can [hire us](https://www.apsis.io/work-with-us/) to build your vision.
