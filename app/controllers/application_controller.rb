# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  filter_parameter_logging :password
  protect_from_forgery
  layout proc{ |c| c.request.xhr? ? false : 'application' } # skip layout for ajax

  ##
  ## COMMON CONTROLLER EXTENSIONS
  ## 

  Dir.entries("app/controllers/controller_extension/").each do |file|   
    include("controller_extension/#{$1}".camelize.constantize) if file =~ /(.*)\.rb$/
  end

  permissions :application

  ##
  ## COMMON HELPERS
  ##

  helper :application
  [:utility, :ui, :page].each do |helper_namespace|
    Dir.entries("app/helpers/common/#{helper_namespace}/").each do |file|
      helper("common/#{helper_namespace}/#{$1}") if file =~ /(.*)_helper\.rb$/
    end
  end

  protected

  # this is used by the code that is included for both controllers and helpers.
  # this way, they don't need to know if they are in a view or a controller, 
  # they can always just reference controller().
  def controller(); self; end

  def current_theme
    @current_theme ||= Crabgrass::Theme[current_site.theme]
  end
  helper_method :current_theme

  # view() method lets controllers have access to the view helpers.
  def view
    self.class.helpers
  end

  # proxy for view's content_tag
  def content_tag(*args, &block)
    view.content_tag(*args,&block)
  end

  #
  # returns a hash of options to be given to the mailers. These can be
  # overridden, but these defaults are pretty good. See models/mailer.rb.
  #
  def mailer_options
    from_address = current_site.email_sender.
      sub('$current_host',request.host)
    from_name    = current_site.email_sender_name.
      sub('$user_name', current_user.display_name).
      sub('$site_title', current_site.title)
    opts = {
     :site => current_site,   :current_user => current_user,
     :host => request.host,   :protocol => request.protocol,
     :page => @page,          :from_address => from_address,
     :from_name => from_name }
    opts[:port] = request.port_string.sub(':','') if request.port_string.any?
    return opts
  end

  ##
  ## CLASS METHODS
  ##

  # rather than include every stylesheet in every request, some stylesheets are
  # only included "as needed". A controller can set a custom stylesheet
  # using 'stylesheet' in the class definition:
  #
  # for example:
  #
  #   stylesheet 'gallery', 'images'
  #   stylesheet 'page_creation', :action => :create
  #
  # as needed stylesheets are kept in public/stylesheets/as_needed
  #
  def self.stylesheet(*css_files)
    if css_files.any?
      options = css_files.last.is_a?(Hash) ? css_files.pop : {}
      sheets  = read_inheritable_attribute("stylesheet") || {}
      index   = options[:action] || :all
      sheets[index] ||= []
      sheets[index] << css_files
      write_inheritable_attribute "stylesheet", sheets
    else
      read_inheritable_attribute "stylesheet"
    end
  end

  # let controllers require extra javascript
  # for example:
  #
  #   javascript 'wiki_edit', :action => :edit
  #
  def self.javascript(*js_files)
    if js_files.any?
      options = js_files.last.is_a?(Hash) ? js_files.pop : {}
      scripts  = read_inheritable_attribute("javascript") || {}
      index   = options[:action] || :all
      scripts[index] ||= []
      scripts[index] << js_files
      write_inheritable_attribute "javascript", scripts
    else
      read_inheritable_attribute "javascript"
    end
  end

end
