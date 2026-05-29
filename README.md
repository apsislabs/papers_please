# papers_please

A roles and permissions gem from Apsis Labs.

## How It Works

Authorization boils down to a relationship between three things: a **user**, an **action**, and a **target**. `papers_please` lets you define these relationships in a single policy file using two primitives:

- **`scope:`** — Given a user and an action, which records can they act on? Returns a collection (typically an ActiveRecord relation).
- **`if:`** — Given a user and a specific record, is this action allowed? Returns a boolean.

When you provide a `scope:` without an `if:`, `papers_please` auto-generates the predicate for you. For **instance-level** permissions (e.g. `:show`, `:edit`), it checks whether the record is included in the scope. For **collection-level** permissions (e.g. `:index`, `:create`), you pass `collection: true` and the predicate becomes unconditionally `true` — the user can access the collection, and the scope controls what they see.

## Example

```ruby
# app/policies/access_policy.rb
class AccessPolicy < PapersPlease::Policy
  def configure
    role :admin, proc { |u| u.admin? }
    role :member, proc { |u| u.member? }
    role :guest

    permit :admin do |role|
      role.grant %i[index new create], Post, collection: true
      role.grant %i[show edit update destroy], Post
    end

    permit :member do |role|
      # Collection actions: member can see the index and create posts
      role.grant :index, Post, collection: true, scope: proc { |u| u.posts }
      role.grant :create, Post, collection: true

      # Instance actions: member can view/edit their own posts
      role.grant %i[show edit update], Post, scope: proc { |u| u.posts }

      # Scope + condition: can archive own posts, but only if not already archived
      role.grant :archive, Post,
        scope: proc { |u| u.posts },
        if: proc { |u, post| !post.archived? }
    end

    permit :guest do |role|
      role.grant :index, Post, collection: true
      role.grant :show, Post, if: proc { |_u, post| !post.archived? }
    end

    # Delegated permissions: attachment access is determined by its post
    permit :member, :guest do |role|
      role.grant :show, Attachment, through: [Post, proc { |_u, attachment| attachment.post }]
    end
  end
end
```

### Controller Usage

```ruby
class PostsController < ApplicationController
  # GET /posts
  def index
    @posts = policy.scope_for(:index, Post)
    render json: @posts
  end

  # GET /posts/:id
  def show
    @post = Post.find(params[:id])
    policy.authorize! :show, @post
    render json: @post
  end

  # POST /posts
  def create
    policy.authorize! :create, Post
    @post = Post.create!(post_params)
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
```

### Checking Permissions

```ruby
policy = AccessPolicy.new(current_user)

# Can this user perform this action on this record?
policy.can?(:edit, @post)       # => true/false
policy.cannot?(:destroy, @post) # => true/false

# Raise if not allowed
policy.authorize!(:edit, @post) # => raises PapersPlease::AccessDenied

# What records can this user access for this action?
policy.scope_for(:index, Post)  # => ActiveRecord::Relation

# What actions can this user perform on this record?
policy.permitted_actions(@post) # => [:show, :edit, :update]
```

## Collection vs Instance Permissions

This is the most important concept to understand. Actions fall into two categories:

**Collection-level** actions operate on the resource as a whole, not a specific record. Think `:index`, `:new`, `:create`. The question is "can this user access this resource?" not "can this user access this specific record?"

**Instance-level** actions operate on a specific record. Think `:show`, `:edit`, `:update`, `:destroy`. The question is "can this user act on this particular record?"

When you provide a `scope:` and let `papers_please` auto-generate the `if:` predicate:

```ruby
# Instance: auto-predicate checks record ∈ scope
role.grant :show, Post, scope: proc { |u| u.posts }
# policy.can?(:show, some_post) => u.posts.include?(some_post)

# Collection: auto-predicate is always true
role.grant :index, Post, collection: true, scope: proc { |u| u.posts }
# policy.can?(:index, Post) => true
# policy.scope_for(:index, Post) => u.posts
```

Without `collection: true`, checking `can?(:index, Post)` would try to check whether the `Post` *class* is included in the scoped collection — which is never what you want.

## Role Fallthrough

By default, `papers_please` checks roles in order and returns the result from the **first role that has a matching permission** — even if that result is `false`. This means a denial in an earlier role prevents later roles from granting access.

Calling `allow_fallthrough` in your policy changes this: when a role denies a permission, the check continues to the next applicable role. Access is granted if **any** role allows it, and denied only if **no** role does.

```ruby
class AccessPolicy < PapersPlease::Policy
  def configure
    allow_fallthrough

    role :admin, proc { |u| u.admin? }
    role :member, proc { |u| u.member? }

    # An admin who is also a member will match both roles.
    # Without fallthrough, if :admin denies :read, the check stops.
    # With fallthrough, :member still gets a chance to grant it.

    permit :admin do |role|
      role.grant :read, Post, scope: proc { |u| u.posts }
    end

    permit :member do |role|
      role.grant :read, Post, if: proc { |_u, post| post.published? }
    end
  end
end
```

Most real-world policies should use `allow_fallthrough`. Without it, role ordering becomes load-bearing and easy to get wrong.

## Delegated Permissions with `through:`

When a resource's access is determined by a parent, use `through:`:

```ruby
role.grant :show, Attachment, through: [Post, proc { |_u, attachment| attachment.post }]
```

This means: "to check if a user can `:show` an `Attachment`, find its `Post` and check whether the user can `:show` that `Post` instead."

## A Helpful CLI

```bash
$ rails papers_please:roles
```

Prints a table of all roles, subjects, and permissions in your policy.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'papers_please'
```

And then execute:

    $ bundle

## Upgrading

### Keyword Renames

The following keyword arguments have been renamed. The old names still work but may be deprecated in a future release:

| Old | New | Meaning |
|---|---|---|
| `query:` | `scope:` | Which records can this user access? |
| `predicate:` | `if:` | Is this specific action allowed? |
| `granted_by:` | `through:` | Delegate permission check to a parent |

You cannot pass both the old and new name for the same option.

### Removed: `:manage` expansion

`:manage` no longer expands to `[:create, :read, :update, :destroy]`. Define your action lists explicitly:

```ruby
# Before
role.grant :manage, Post

# After
role.grant %i[create read update destroy], Post
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Releasing

Create a release from `main`:

```sh
bin/release {major|minor|patch|pre}
git push --follow-tags
```

The release script validates the repository, bumps the version, creates a git tag.

Publishing to RubyGems and creating a GitHub Release are handled automatically by GitHub Actions.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/apsislabs/papers_please.

## Special Thanks

This owes its existence to [`AccessGranted`](https://github.com/chaps-io/access-granted). Thanks!

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

# Built by Apsis

[![apsis](https://s3-us-west-2.amazonaws.com/apsiscdn/apsis.png)](https://www.apsis.io)

`papers_please` was built by Apsis Labs. We love sharing what we build! Check out our [other libraries on Github](https://github.com/apsislabs), and if you like our work you can [hire us](https://www.apsis.io/work-with-us/) to build your vision.
