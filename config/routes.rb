Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :users, only: [:index, :create] do
  	collection do
  		post 'confirm'
  		post 'login'
  	end
  end
  # resource :basket, only: [:show, :update, :destroy]
  resource :basket
  resolve("Basket") { route_for(:basket) }

  #namespace

  namespace :admin do
    resources :articles
  end

  #If you want to route /articles (without the prefix /admin) to
  #Admin::ArticlesController, you could use:
  # ****
  scope module: 'admin' do
    resources :articles, :comments
    get 'admin/foo', to: 'foo#index'
  end

  # Or

  resources :articles, module: 'admin'

  #*****

  #If you want to route /admin/articles to ArticlesController
  #(without the Admin:: module prefix), you could use
  #****

  scope '/admin' do
    resources :articles, :comments
  end

  #Or
  resources :articles, path: '/admin/articles'
  #****

  # Nested resources
  # Noted:  Resources should never be nested more than 1 level deep
  resources :magazines do
    resources :ads
  end

  #shallow nesting
  #One way to avoid deep nesting
  resources :articles do
    resources :comments, only: [:index, :new, :create]
  end
  resources :comments, only: [:show, :edit, :update, :destroy]

  # There exists shorthand syntax to achieve just that, via the :shallow option:
  resources :articles do
    resources :comments, shallow: true
  end

  # follow ways mean all nested resources will be shallowed

  resources :articles, shallow: true do
    resources :comments
    resources :quotes
    resources :drafts
  end

  #OR

  shallow do
    resources :articles do
      resources :comments
      resources :quotes
      resources :drafts
    end
  end

  # Use scope options to custom shallow
  # Example custom shallow path
  # GET    /sekret/comments/:id(.:format)                 comments#show
  scope shallow_path: 'sekret' do
    resources :articles do
      resources :comments, shallow: true
    end
  end

  # Example custom shallow helpers
  # edit_sekret_comment GET    /comments/:id/edit(.:format)       comments#edit
  scope shallow_prefix: 'sekret' do
    resources :articles do
      resources :comments, shallow: true
    end
  end

  # *** end shallow

  # Routing Concern
  # allow you to declare common routes that can be reused
  # inside other resources and routes.

  # Define concerns

  concern :commentable do
    resources :comments
  end

  concern :image_attachable do
    resources :images, only: :index
  end

  # These concerns can be used in resources to avoid code duplication
  # and share behavior across routes
  resources :messages, concerns: :commentable
  resources :articles, concerns: [:commentable, :image_attachable]

  # equivalent to
  # resources :messages do
  #   resources :comments
  # end

  # resources :articles do
  #   resources :comments
  #   resources :images, only: :index
  # end

  # Also you can use them in any place that you want inside the routes,
  # for example in a scope or namespace call:

  namespace :articles do
    concerns :commentable
  end
  # equivalent to:
  # namespace :articles do
  #   resources :comments
  # end

  # *** end concern

  # Add more resful actions with member, collection , new

  resources :photos do
    member do
      get 'preview'
    end
  end
  # Or

  resources :photos do
    get 'preview', on: :member
  end
  #=> preview_photo GET    /photos/:id/preview(.:format)    photos#preview

  resources :photos do
    collection do
      get 'search'
    end
  end
  # Or

  resources :photos do
    get 'search', on: :collection
  end
  # => search_photos GET    /photos/search(.:format)   photos#search

  resources :comments do
    get 'preview', on: :new
  end
  # => preview_new_comment GET    /comments/new/preview(.:format) comments#preview

  # Non Resourceful routes

  # get 'photos(/:id)', to: :display
  get 'profile', to: :show, controller: 'users'
  # => /photos/1, /photos routes to display action of photos_controller params[:id] = 1, nil

  get 'photos/:id/:user_id', to: 'photos#show'
  # => /photos/1/2 will be dispatched to the show action of the
  # PhotosController. params[:id] will be "1", and params[:user_id] will be "2".

  get 'photos/:id/with_user/:user_id', to: 'photos#show'
  # /photos/1/with_user/2. In this case, params would be
  # { controller: 'photos', action: 'show', id: '1', user_id: '2' }

  # Query String
  get 'photos/:id', to: 'photos#show'
  # /photos/1?user_id=2 will be dispatched to the show action of
  #the Photos controller. params will be { controller: 'photos', action: 'show', id: '1', user_id: '2' }.

  # Defining Defaults
  # This even applies to parameters that you do not specify as dynamic segments
  get 'photos/:id', to: 'photos#show', defaults: {format: 'jpg'}
  defaults format: :json do
    resources :photos
  end

  # Naming Routes
  get 'exit', to: 'sessions#destroy', as: :logout
  # This will create logout_path and logout_url as named helpers

  get ':username', to: 'users#show', as: :user
  # /bob will be routes to show action of users_controller, user_path('bob') => ...params[:username]

  #  HTTP Verb Constraints use match
  match 'photos', to: 'photos#show', via: [:get, :post]
  # => GET|POST /photos(.:format)    photos#show
  match 'photos', to: 'photos#show', via: :all
  # all verbs for route


  # ******  Segment Constraints

  #You can use the :constraints option to enforce a format for a dynamic segment:

  get 'photos/:id', to: 'photos#show', constraints: {id: /[A-Z]\d{5}/}
  # => would match paths such as /photos/A12345, but not /photos/893
  # Same as:
  get 'photos/:id', to: 'photos#show', id: /[A-Z]\d{5}/

  # ****** End Segment Constraints

  # Request-Based Constraints
  # You can also constrain a route based on any method on the Request
  #object that returns a String https://guides.rubyonrails.org/action_controller_overview.html#the-request-object
  get 'photos', to: 'photos#index', constraints: {subdomain: 'admin'}
  # => match with http://admin.eng-learn.com/photos
  # Same as:

  namespace :admin do
    constraints subdomain: 'admin' do
      resources :photos
    end
  end
  # => match with http://admin.eng-learn.com/admin/photos/1

  get 'foo', to: 'photos#foo', constraints: {format: 'json'}
  # => will match GET  /foo because the format is optional by default

  get 'foo', to: 'photos#foo', constraints: lambda{|req| req.format == :json}
  # => will match only with explicit JSON requests

  # Advanced Constraints
  # If you have a more advanced constraint, you can provide an
  # object that responds to matches? that Rails should use
  # below to route all users on a blacklist to the BlacklistController

  get '*path', to: 'blacklist#index', constraints: BlackListConstraint.new
  # => /xxx/abc from remote_ip include black list => blacklist_controller params[:path] = xxx/abc

  # same as:

  get '*other_path', to: 'otherblacklist#index',
    constraints: lambda{|request| BlackList.retrieve_ips.include?(request.remote_ip)}

  # end Advanced Constraints

  # Pretty Url with constraint

  get '/articles/:year/:month/:day' => 'articles#find_by_id', constraints: {
    year:       /\d{4}/,
    month:      /\d{1,2}/,
    day:        /\d{1,2}/
  }

  #=> localhost:3000/articles/2005/11/06 map to params = {year: '2005', month: '11', day: '06'}

  # Route Globbing and Wildcard Segments

  get 'photos/*other', to: 'photos#unknown'
  # =>  would match photos/12 or /photos/long/path/to/12
  # with params[:other] to "12" or "long/path/to/12"

  get 'books/*section/:title', to: 'books#show'
  # match books/some/section/last-words-a-memoir with params[:section]
  # equals 'some/section', and params[:title] equals 'last-words-a-memoir'

  get '*a/foo/*b', to: 'test#index'
  # => match zoo/woo/foo/bar/baz with params[:a] equals 'zoo/woo',
  # and params[:b] equals 'bar/baz'.

  # end wildcard

  # Redirection

  get '/stories', to: redirect('/articles')
  get '/stories/:name', to: redirect('/articles/%{name}')

  # redirect with block of params and request

  get '/stories/:name', to: redirect {|path_params, req|
    "/articles/#{path_params[:name].pluralize}"}

  get '/stories', to: redirect {|path_params, req|
    "/articles/#{req.subdomain}"}

  # end redirect

  # Root

  root to: 'pages#main'
  # or
  root 'pages#main'

  # use root inside namespaces and scopes

  namespace :admin do
    root to: 'admin#index'
  end

  # end root

  # Unicode character routes

  get 'こんにちは', to: 'welcome#index'

  # Direct routes (route to other domain)
  # You can create custom URL helpers directly. For example:

  direct :homepage do
    "http://www.rubyonrails.org"
  end
  #=> homepage_url: => "http://www.rubyonrails.org"


  direct :commentable do |model|
    [ model, anchor: model.dom_id ]
  end

  #=> commentable_url(@article) => http://learn-eng/articles/1

  direct :main do
    { controller: 'pages', action: 'index', subdomain: 'www' }
  end
  #=> main_url => http://www.learn-eng/page

  # Using resolve
  # resolve method allows customizing polymorphic mapping of models. For example:

  resource :basket
  resolve('Basket'){[:basket]}
  # => <%= form_for @basket do |form| %> will generate the
  #singular URL /basket instead of the usual /baskets/:id

  # Customizing Resourceful Routes
  # Specifying a Controller to Use

  resources :posts, controller: 'articles'
  resources :user_permissions, controller: 'admin/user_permissions'

  #  Specifying Constraints

  resources :students, constraints: {id: /[A-Z][A-Z][0-9]+/}
  # =>  /photos/RR27 would match

  constraints(id: /[A-Z][A-Z][0-9]+/) do
    resources :photos
    resources :accounts
  end

  # Overriding the Named Helpers

  resources :photos, as: 'images'

  # Overriding the new and edit Segments

  resources :photos, path_names: {new: 'make', edit: 'change'}
  # => GET      /photos/make(.:format)    photos#new
  # => GET      /photos/:id/change(.:format)     photos#edit

  scope path_names: { new: 'make' } do
    resources :songs
    resources :singers
  end

  # Prefixing the Named Route Helpers
  # to prevent name collisions between routes using a path scope

  scope 'admin' do
    resources :photos, as: 'admin_photos'
  end
  resources :photos
  # => admin_photos_path, new_admin_photo_path

  scope 'admin', as: 'admin' do
    resources :books
    resources :pens
  end

  # you can prefix routes with a named parameter

  scope ':username' do
    resources :phones
  end
  # => /bob/articles/1 and will allow you to reference the username part
  # of the path as params[:username] in controllers, helpers and views

  # Restricting the Routes Created with only, except options

  resources :boxes, only: [:index, :show]
  resources :tables, except: :destroy

  # Translated Paths


  scope(path_names: { new: 'neu', edit: 'bearbeiten' }) do
    resources :mixes, path: 'kategorien'
  end

  # Using :as in Nested Resources

  resources :magazines do
    resources :ads, as: 'periodical_ads'
  end

  # => This will create routing helpers such as magazine_periodical_ads_url
  # and edit_magazine_periodical_ad_path.

  # Overriding Named Route Parameters
  # The :param option overrides the default resource identifier :id

  resources :videos, param: :identifier
  #edit_video GET      /videos/:identifier/edit(.:format)   videos#edit

end
