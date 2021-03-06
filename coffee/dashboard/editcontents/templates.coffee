tc = require 'teacup'
marked = require 'marked'


{ navbar_collapse_button
  dropdown_toggle } = require 'bootstrap-teacup-templates/coffee/buttons'
  

{ frontdoor_url
  editor_url } = require 'common/templates/common'

{ workflow_dropdown } = require '../templates/editorbar'

{ form_group_input_div } = require 'bootstrap-teacup-templates/coffee/forms'
{ ace_editor_div } = require 'bootstrap-teacup-templates/coffee/misc'

{ capitalize } = require 'common/apputil'

MainChannel = Backbone.Radio.channel 'global'

########################################
# Templates
########################################
button_icons =
  paste: 'fa-paste'
  copy: 'fa-copy'
  cut: 'fa-cut'
  rename_nodes: 'fa-pencil-square-o'
  delete_nodes: 'fa-remove'
  change_state: 'fa-bicycle'
  up: 'fa-arrow-up'
  down: 'fa-arrow-down'
  show: 'fa-eye'
  hide: 'fa-eye-slash'

popover_image = tc.renderable (url) ->
  tc.img src:url

NotImplementedModal = tc.renderable (model) ->
  tc.div '.modal-dialog', ->
    tc.div '.modal-content', ->
      tc.h3 "#{model.name} is not implemented"
      tc.div '.modal-body', ->
        tc.div '#selected-children'
      tc.div '.modal-footer', ->
        btnclass = 'btn.btn-default.btn-sm'
        tc.div "#cancel-delete-button.#{btnclass}",
        'data-dismiss': 'modal', "Ok"
  
SelectChildFirstModal = tc.renderable () ->
  tc.div '.modal-dialog', ->
    tc.div '.modal-content', ->
      tc.h3 "Please select one or more children first."
      tc.div '.modal-body'
      tc.div '.modal-footer', ->
        btnclass = 'btn.btn-default.btn-sm'
        tc.div "#cancel-delete-button.#{btnclass}",
        'data-dismiss': 'modal', "Ok"
  
SelectedChild = tc.renderable (child) ->
  tc.div child.data.id
  
  

ConfirmDeleteTemplate = tc.renderable (children) ->
  tc.div '.modal-dialog', ->
    tc.div '.modal-content', ->
      tc.h3 'Delete these children?'
      tc.div '.modal-body', ->
        tc.div '#selected-children'
      tc.div '.modal-footer', ->
        btnclass = 'btn.btn-default.btn-sm'
        tc.div "#confirm-delete-button.#{btnclass}", "Confirm Delete"
        tc.div "#cancel-delete-button.#{btnclass}",
        'data-dismiss': 'modal', "Cancel"

ContentsTableHead = tc.renderable () ->
  tc.thead ->
    tc.tr ->
      tc.th ->
        tc.input '#toggle-all', type:'checkbox',
        title:'Select / deselect all'
      fields = ['Title', 'Type', 'State', 'Visibility',
      'Creation Date', 'Modification Date']
      tc.th field for field in fields

ContentsTableChildRow = tc.renderable (child) ->
  window.currentchild = child
  type_info = child.data.relationships.meta.type_info
  #tc.tr "##{child.position}.child-row", ->
  tc.td ->
    tc.input name:'children', type:'checkbox',
    value:child.data.attributes.oid,
    title:child.data.attributes.title
  tc.td ->
    tc.a href:editor_url('contents', child.meta.path), ->
      tc.text child.data.attributes.title
    if type_info.name == 'Image'
      imgtag = """<img src="#{type_info.image_span4_url}">"""
      tc.br()
      tc.img '.thumb', src:type_info.image_span1_url,
      'data-content':imgtag,
      title:child.data.attributes.title
  tc.td type_info.title
  tc.td ->
    lstyle = 'list-style-type: none; padding: 0; margin: 0;'
    tc.ul style:lstyle, ->
      workflow_dropdown child
  tc.td ->
    if child.meta.in_navigation
      tc.i '.fa.fa-eye'
      tc.span 'Visible'
    else
      tc.i '.fa.fa-eye-slash'
      tc.span 'Hidden'
  tc.td child.meta.creation_date
  tc.td child.meta.modification_date
  
  
ContentsViewTemplate = tc.renderable (doc) ->
  #window.ContentsViewDoc = doc
  atts = doc.data.attributes
  relmeta = doc.data.relationships.meta
  lineage = relmeta.lineage.slice()
  lineage.reverse()
  clipboard = MainChannel.request 'main:app:kotti-clipboard'
  tc.div '.document-view.content', ->
    tc.h1 atts.title
    tc.p '.lead', atts.description
    #tc.div tags
    # FIXME i18n
    tc.h2 'Contents'
    tc.div '.body', ->
      tc.div '#contents-path', ->
        [first, ..., last] = lineage
        for item in lineage
          tc.a '.btn.btn-default.btn-small', name:item.name,
          href:editor_url('contents', item.path), ->
            if item.id == first?.id
              tc.i '.fa.fa-home.fa-fw'
            if not (item.id == first?.id or item.id == last?.id)
              tc.i '.fa.fa-folder.fa-fw'
            if (item.id == last?.id and item.id != first?.id)
              tc.i '.fa.fa-folder-open-o.fa-fw'
            tc.text item.title
      # don't use a form, but use xhr post instead
      # <form action="${request.resource_url(context, '@@contents')}" method="post">
      #tc.div ->
      tc.form '#contents-form', ->
        # table only needed if length children
        if doc.data.links.children.length
          tclasses = "table.table-condensed.table-striped.table-hover"
          tc.table "#contents-table.#{tclasses}", ->
            ContentsTableHead()
            tc.tbody '#resource-children'
          tc.div ".btn-group", ->
            #if clipboard.length
            #  tc.div ".action-button.btn.btn-default.btn-small",
            #  name:'paste', ->
            #    tc.i ".fa.#{button_icons.paste}.fa-fw"
            #    tc.small ->
            #      tc.text 'Paste'
            for btn in relmeta.contents_buttons
              tc.div ".action-button.#{btn.css_classes.join('.')}",
              #name:btn.name, type:'submit', ->
              name:btn.name, title:btn.title, ->
                tc.i ".fa.#{button_icons[btn.name]}.fa-fw"
                #tc.small ->
                #  tc.text btn.title


_edit_form = tc.renderable (doc) ->
  window._edit_form_doc = doc
  for field in ['title', 'description']
    form_group_input_div
      input_id: "input_#{field}"
      label: capitalize field
      input_attributes:
        name: field
        placeholder: field
        value: doc.data?.attributes[field]
      value: doc.data?.attributes.title
  # FIXME implement tags
  #tc.input '#input_tags', name:'tags', title:'Tags', type:'text'

_form_button = tc.renderable (doc) ->
  buttonlbl = if doc.data then "Update #{doc.data.type}" else "Add Document"
  tc.input '.btn.btn-default', type:'submit', value:buttonlbl
  
EditNodeForm = tc.renderable (doc) ->
  _edit_form doc
  tc.div '#document-body', ->
    tc.raw doc.data.attributes.body
  _form_button doc

AceEditNodeForm = tc.renderable (doc) ->
  _edit_form doc
  ace_editor_div()
  _form_button doc

#editor {
#    position: relative;
#    width: 100%;
#    height: 40em;
#}



module.exports =
  NotImplementedModal: NotImplementedModal
  SelectChildFirstModal: SelectChildFirstModal
  SelectedChild: SelectedChild
  ConfirmDeleteTemplate: ConfirmDeleteTemplate
  ContentsTableChildRow: ContentsTableChildRow
  ContentsViewTemplate: ContentsViewTemplate
  EditNodeForm: EditNodeForm
  AceEditNodeForm: AceEditNodeForm

