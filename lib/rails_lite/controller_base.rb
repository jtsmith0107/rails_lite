require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'


class ControllerBase
  attr_reader :params, :req, :res

  # setup the controller
  def initialize(req, res, route_params = {})
    @params = Params.new(req, route_params)
    @req = req
    @res = res
    @already_built_response = false
    session
    #flash would be initialized here
  end

  # populate the response with content
  # set the responses content type to the given type
  # later raise an error if the developer tries to double render
  def render_content(content, type)
    raise "Double Render" if already_built_response?
    @res.content_type = type
    @res.body = content  
    @already_built_response = true  
    @session.store_session(@res)
  end

  # helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # set the response status code and header
  def redirect_to(url)
    raise "Double Render" if already_built_response?
    @res.header["location"] = url
    @res.status = 302
    @already_built_response = true
    @session.store_session(@res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    raise "Double Render" if already_built_response?
    file = File.read("views/#{self.class.to_s.underscore}/#{template_name}.html.erb")
    template = ERB.new(file)
    fbind = binding()  
    content = template.result(fbind)
    render_content(content, "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    unless already_built_response?
      render(name)
    end
  end
end
