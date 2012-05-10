require 'rubygems'
require 'bundler/setup'
require 'digest/sha1'

require 'dalli'

require 'active_record'
require 'action_dispatch'
require 'foreigner'

require 'redcarpet'
require 'pygments'

require 'diffy'

require 'sinatra'
require 'logger'

require 'haml'
require 'erb'
include ERB::Util

require './db.rb'


@config = YAML::load(File.open('config/config.yml'))


#set :protection, :except => :frame_options
disable :protection
set :static_cache_control, [:public, :max_age => 43200] # 12 hours


if defined? @config['optimized'] and @config['optimized']
  #puts "Using optimized static files"
  #set :public, File.dirname(__FILE__) + '/public_opt'
  set :public_folder, File.dirname(__FILE__) + '/public_opt'
end


if defined? @config['silent'] and @config['silent']
  set :logging, false
# Disable useless rack logger completely! Yay, yay!
  module Rack
    class CommonLogger
      def call(env)
        # do nothing
        @app.call(env)
      end
    end
  end

  disable :logging
end


configure do
  ActiveRecord::Base.include_root_in_json = false
end


post '/comments/site/:site_name/article/:article_hash' do
  @site = Site.find_by_name!(params[:site_name])
  @article = nil

  begin
    @article = @site.articles.find_by_name!(params[:article_hash])
  rescue ActiveRecord::RecordNotFound => n
    @article = @site.articles.create!(:name => params[:article_hash])
  end

  @comment = @article.comments.create!(:new_mail => params[:email], :request => request, :name => params[:name], :comment => params[:comment])

  redirect request.referrer unless request.referrer.nil?
  "Comment posted. Thank you!"
end


get '/comments/site/:site_name/article/:article_hash' do
  content_type :html
  @site = Site.find_by_name!(params[:site_name])
  @article = @site.articles.find_by_name!(params[:article_hash])
  @comments = @article.comments.where(:spam => false)

  haml :comments, :format => :html5, :locals => { :comments => @comments }
end


post '/comments/api/site/:site_name/article/:article_hash' do
  content_type :json

  data = JSON.parse(request.body.read)
  @site = Site.find_by_name!(params[:site_name])
  @article = nil

  begin
    @article = Site.articles.find_by_name!(params[:article_hash])
  rescue ActiveRecord::RecordNotFound => n
    @article = Article.create!(:name => params[:article_hash])
  end

  @comment = @article.comments.create!(:new_mail => data['email'], :request => request, :name => data['name'], :comment => data['comment'])
  @comment.to_json
end



get '/comments/api/site/:site_name/article/:article_hash' do
  content_type :json

  @site = Site.find_by_name!(params[:site_name])
  @article = @site.articles.find_by_name!(params[:article_hash])

  @article.comments.to_json
end








before '/comments/api/id/*' do
  begin
    @user = User.find(session[:user])
  rescue ActiveRecord::RecordNotFound
    halt 403
  end
end


before '/comments/api/id/site/:site_id*' do
  @site = @user.sites.find(params[:site_id])
  halt 404 unless @site != nil # not reached normally, as above raises RecordNotFound
end


get '/comments/api/id/site' do
  content_type :json

  @user.sites.to_json
end


get '/comments/api/id/site/:site_id' do
  content_type :json

  @site.to_json
end


get '/comments/api/id/site/:site_id/article' do
  content_type :json

  @site.articles.to_json
end


get '/comments/api/id/site/:site_id/article/:article_id' do
  content_type :json

  @article = @site.articles.find(params[:article_id])

  @article.to_json
end


get '/comments/api/id/site/:site_id/article/:article_id/comments' do
  content_type :json

  @article = @site.articles.find(params[:article_id])

  @article.comments.to_json
end


before '/comments/:site_name/:article_hash' do
  @api = false
end


before '/comments/api/*' do
  @api = true
end



set :raise_errors, false
set :show_exceptions, false


error do
  env['sinatra.error'].backtrace
end


error ActiveRecord::RecordInvalid do
  if @api
    env['sinatra.error'].errors_to_json
  else
    errors = env['sinatra.error'].errors_to_a
    haml :record_invalid, :format => :html5, :locals => { :errors => errors }
  end
end


error ActiveRecord::RecordNotUnique do
  if @api
    { "errors" => [env['sinatra.error'].to_s] }.to_json
  else
    env['sinatra.error'].to_s
  end
end


error ActiveRecord::RecordNotFound do
  if @api
    { "errors" => ["Resource not found"] }.to_json
  else
    "Resource not found"
  end
  status 404
end
