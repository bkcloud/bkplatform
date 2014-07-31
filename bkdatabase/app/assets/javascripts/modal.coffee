@Modal =

  $el: null

  createTableColumnTemplate: (data = {}) ->
    data.fieldNo ?= 0
    data_item = (id) ->
      return "
      <tr class=\"field-item\">
        <td class=\"field\">
          <input type=\"text\" class=\"form-control span1 input-sm field\" placeholder=\"Text input\">
        </td>
        <td class=\"type\">
          <select class=\"form-control span2 input-sm type\">
            <option value=\"INT\">INT</option>
            <option value=\"SMALLINT\">SMALLINT</option>
            <option value=\"DEC\">DEC</option>
            <option value=\"NUMERIC\">NUMERIC</option>
            <option value=\"DATETIME\">DATETIME</option>
            <option value=\"CHAR\">CHAR</option>
            <option value=\"VARCHAR\">VARCHAR</option>
            <option value=\"BINARY\">BINARY</option>
            <option value=\"BLOC\">BLOB</option>
            <option value=\"ENUM\">ENUM</option>
            <option value=\"SET\">SET</option>
          </select>
        </td>
        <td class=\"value\">
          <input type=\"text\" class=\"form-control span1 input-sm value\" placeholder=\"Text input\">
        </td>
        <td class=\"attributes\">
          <select class=\"form-control span2 input-sm attributes\">
            <option value=\"\">----</option>
            <option value=\"BINARY\">BINARY</option>
            <option value=\"UNSIGNED\">UNSIGNED</option>
          </select>
        </td>
        <td class=\"null\">
          <select class=\"form-control span2 input-sm null\">
            <option value=\"NOT NULL\">NOT NULL</option>
            <option value=\"DEFAULT NULL\">NULL</option>
          </select>
        </td>
        <td class=\"default\">
          <input type=\"text\" class=\"form-control span1 input-sm default\" placeholder=\"Text input\">
        </td>
        <td class=\"extra\">
          <select class=\"form-control span3 input-sm extra\">
            <option value=\"AUTO_INCREMENT\">AUTO_INCREMENT</option>
            <option value=\"\">None</option>
          </select>
        </td>
        <td class=\"primary\">
          <div class=\"radio input-sm\">
            <input type=\"radio\" name=\"optionRadio#{id}\" value=\"PRIMARY\">
          </div>
        </td>
        <td class=\"index\">
          <div class=\"radio input-sm\">
            <input type=\"radio\" name=\"optionRadio#{id}\" value=\"INDEX\">
          </div>
        </td>
        <td class=\"unique\">
          <div class=\"radio input-sm\">
            <input type=\"radio\" name=\"optionRadio#{id}\" value=\"UNIQUE\">
          </div>
        </td>
      </tr>
    "
    data.items += data_item(i) for i in [1..data.fieldNo]
    data.body ?= "
      <div class=\"table-responsive\">
        <table class=\"table table-condensed\">
          <tr>
            <th>Field</th>
            <th>Type</th>
            <th>Length/Value</th>
            <th>Attributes</th>
            <th>Null</th>
            <th>Default</th>
            <th>Extra</th>
            <th>Primary</th>
            <th>Index</th>
            <th>Unique</th>
          </tr>
          <tbody>
            #{data.items}
          </tbody>
        </table>
      </div>
    "
    """
    #{data.body}
    """

  createTablePromptTemplate: (data = {}) ->
    data.title ?= ""
    data.modalWith ?= ""
    data.body ?= ""

    """
    <div class="modal" id="modal" style="width: #{data.modalWidth}; margin-left: #{-280 - (parseInt(data.modalWidth) - 560)/2}px">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal">×</button>
          <h3>#{data.title}&nbsp;</h3>
        </div>
        <div class="modal-body">
          <div class="form-inline">
            <input type="text" class="form-control span6" id="table-name" placeholder="#{I18n.t("modals.create_table_placeholder")}">
            <input type="text" class="form-control span2" id="fieldno" placeholder="#{I18n.t("modals.no_of_field")}" data-action="render-field-template">
          </div>
           #{data.body}
        </div>
        <div class="modal-footer">
          <a href="#" class="btn" data-dismiss="modal" data-action="cancel">#{data.cancel.label}</a>
          <a href="#" class="btn btn-primary" data-action="ok">#{data.ok.label}</a>
        </div>
      </div>
    """


  promptTemplate: (data = {}) ->
    data.title ?= ""
    data.body ?= ""
    """
      <div class="modal" id="modal">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal">×</button>
          <h3>#{data.title}&nbsp;</h3>
        </div>
        <div class="modal-body">
          <p>#{data.body}</p>
        </div>
        <div class="modal-footer">
          <a href="#" class="btn" data-dismiss="modal" data-action="cancel">#{data.cancel.label}</a>
          <a href="#" class="btn btn-primary" data-action="ok">#{data.ok.label}</a>
        </div>
      </div>
    """


  alertTemplate: (data = {}) ->
    data.title ?= ""
    data.body ?= ""
    """
      <div class="modal" id="modal">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal">×</button>
          <h3>#{data.title}&nbsp;</h3>
        </div>
        <div class="modal-body">
          <p>#{data.body}</p>
        </div>
        <div class="modal-footer">
          <a href="#" class="btn btn-primary" data-action="ok">#{data.ok.label}</a>
        </div>
      </div>
    """


  # Close any modal and remove from DOM
  close: ->
    @$el?.remove()
    $("body").removeClass("modal-open")
    $("body > .modal-backdrop").remove()

  createTablePrompt: (options = {}) ->
    options.cancel ?= { label: I18n.t("modals.cancel") }
    options.ok ?= { label: I18n.t("modals.ok") }

    @close()
    @$el = $("<div/>").html(@createTablePromptTemplate(options)).modal(backdrop: false)
    $('body').append(@$el)
    @$el.find('[data-action=cancel]').on 'click', (e) =>
      options.cancel.onclick?()
    @$el.find('[data-action=ok]').on 'click', (e) =>
      selectedDatabase = app.database.attributes.path
      args = { columns: [], name: $('input#table-name').val(), dbName: selectedDatabase }
      $("tr.field-item").each (i, element) ->
        column = {
          field: $(element).find('input.field').val(), #
          type: $(element).find('select.type').val(), #
          length: $(element).find('input.value').val(), #
          default: $(element).find('input.default').val(),
          attributes: $(element).find('select.attributes').val(), #
          null: $(element).find('select.null').val(), #
          extra: $(element).find('select.extra').val(),
          index: $(element).find('input[name*=optionRadio]:checked').val(),
        }
        if column['field'] != "" and column['type'] != "" and column['length'] != ""  and column['null'] != ""
          args['columns'].push(column)
      if args['name'] == "" or args['columns'].length < $("tr.field-item").length or args['columns'].length == 0 or $("tr.field-item input[name*=optionRadio]:checked").length == 0
        alert("Missing value in the form")
        return
      $.ajax '/data/mysql/createtable',
        type: 'POST'
        dataType: 'json'
        data: args
        error: (jqXHR, textStatus, errorThrown) ->
          alert("error")
        success: (data, textStatus, jqXHR) ->
          if data["success"] == true
            location.reload()
          else
            alert(data["message"])
      options.ok.onclick?()
    @$el.find('[data-action=render-field-template]').on 'change', (e) =>
      $this = @$el.find('[data-action=render-field-template]')
      tableName = $this.siblings('#table-name').val()
      fieldNo = $this.val()
      @$el.find('.table-responsive')?.remove()
      @$el.find('.modal-body').append(@createTableColumnTemplate({fieldNo: fieldNo}))
    @$el.modal('show')

  # Show modal prompt with title, message and ok/cancel buttons
  #
  # options - The hash of options
  #   title - The String title
  #   body - The String body for modal body
  #   ok - A hash of options for the 'ok' button
  #     label - The string label for the button
  #     onclick - The callback to run when clicked
  #   cancel - A hash of options for the 'cancel' button
  #     label - the String label for the button
  #     onclick - The callback to run when clicked
  #
  prompt: (options = {}) ->
    options.cancel ?= { label: I18n.t("modals.cancel") }
    options.ok ?= { label: I18n.t("modals.ok") }

    @close()
    @$el = $("<div/>").html(@promptTemplate(options)).modal(backdrop: false)
    $('body').append(@$el)
    @$el.find('[data-action=cancel]').on 'click', (e) =>
      options.cancel.onclick?()
    @$el.find('[data-action=ok]').on 'click', (e) =>
      options.ok.onclick?()
    @$el.modal('show')


  # Show modal alert with title, message and ok button
  #
  # options - The hash of options
  #   title - The String title
  #   body - The String body for modal body
  #   ok - A hash of options for the 'ok' button
  #     label - The string label for the button
  #     onclick - The callback to run when clicked
  #
  alert: (options = {}) ->
    options.ok ?=
      label: I18n.t("modals.ok")
      onclick: => @close()

    @close()
    @$el = $("<div/>").html(@alertTemplate(options)).modal(backdrop: false)
    $('body').append(@$el)
    @$el.find('[data-action=cancel]').on 'click', (e) =>
      options.cancel.onclick?()
    @$el.find('[data-action=ok]').on 'click', (e) =>
      options.ok.onclick?()
    @$el.modal('show')


