$ = require 'jquery'
Backbone = require 'backbone'
Marionette = require 'backbone.marionette'
marked = require 'marked'


Util = require 'apputil'
MainViews = require '../views'
{ MainController } = require '../controllers'

Views = require './views'
Models = require 'models'

MainChannel = Backbone.Radio.channel 'global'
ResourceChannel = Backbone.Radio.channel 'resources'
MessageChannel = Backbone.Radio.channel 'messages'



class Controller extends MainController
  _get_doc_and_render_view: (viewclass) ->
    response = @root_doc.fetch()
    response.done =>
      @_make_editbar()
      @_make_breadcrumbs()
      view = new viewclass
        model: @root_doc
      @_show_content view

  _get_contents_and_render_view: (resource) ->
    @_set_resource resource
    res_response = @root_doc.fetch()
    ## FIXME wrap this in scoping functions
    res_response.done =>
      collection = ResourceChannel.request 'get-document-contents', resource
      cresponse = collection.fetch()
      cresponse.done =>
        @_make_editbar()
        @_make_breadcrumbs()
        view = new Views.ContentsView
          model: @root_doc
          collection: collection
        @_show_content view
        #window.ccview = view
        
  manage_contents: (resource) ->
    @_get_contents_and_render_view resource


  _add_document: ->
    model = new Models.BaseKottiModel
    view = new Views.NewDocumentView
      model: model
    window.newdocview = view
    @_show_content view
    
    

  add_node: (content_type, resource) ->
    console.log "Add #{content_type} node to this resource #{resource}"
    @_set_resource resource
    if content_type == 'document'
      @_add_document()
    else
      msg = "Unable to add type #{content_type}"
      MessageChannel.request 'display-message', msg, "error"

  edit_node: (resource) ->
    #console.log "EDIT RESOURCE", resource
    @_set_resource resource
    @_get_doc_and_render_view Views.EditorView

  ace_edit_node: (resource) ->
    #console.log "ACE EDIT RESOURCE", resource
    @_set_resource resource
    @_get_doc_and_render_view Views.AceEditorView

    
module.exports = Controller

