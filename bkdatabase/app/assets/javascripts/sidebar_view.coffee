class @SidebarView extends Backbone.View

  el: '[data-view=sidebar]'

  events:
    'click [data-action=delete-database]'   : 'deleteDatabase'


  initialize: ->
    @cacheSelectors()
    @bind() if app.hasDatabase()


  cacheSelectors: ->
    @$deleteDatabase = @$("[data-aciton=delete-database]")

  bind: ->

  refreshAll: (e) ->
    window.location.href = '/'

  deleteDatabase: (e) ->
    e?.preventDefault()
    return unless app.hasDatabase()
    selectedDatabase = app.database.attributes.path
    Modal.prompt
      title: I18n.t("modals.database.confirm_delete.title")
      body: I18n.t("modals.database.confirm_delete.dropdb", database_name: selectedDatabase)
      ok:
        label: I18n.t("modals.database.confirm_delete.ok")
        onclick: =>
          Modal.close()
          @model.dropdb selectedDatabase, => @refreshAll()
      cancel:
        label: I18n.t("modals.database.confirm_delete.cancel")


