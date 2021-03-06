window.Warranties =
  setup: ->
    @numbersonly()
    return

  warranty_select: (function_param)->
    $(".simple_form").remove()
    $.get "/warranties", {function_param: function_param}

  warranty_create: (function_param, product_id, ticket_time_now)->
    $.get "/warranties/new", {function_param: function_param, product_id: product_id, ticket_time_now: ticket_time_now}

  warranty_assign: (warranty_id)->
    $.post "warranties/create", {warranty_id: warranty_id}

  update_datepicker: ->
    $('#warranty_start_at').datepicker 'remove'
    $('#warranty_start_at').datepicker
      format: $(".selectpicker :selected").val()
      todayBtn: true
      todayHighlight: true

    $('.selectpicker').change ->
      format_value = $(this).val()
      $('#warranty_start_at').datepicker 'remove'
      $('#warranty_start_at').datepicker
        format: format_value
        todayBtn: true
        todayHighlight: true
      return

  disabled_datepicker: ->
    $("#warranty_end_at").prop('disabled', true);
    $('#warranty_start_at').blur ->
      _this = this
      if $(this).val() != ''
        $("#warranty_end_at").prop('disabled', false);
        $('#warranty_end_at').datepicker 'remove'
        $('#warranty_end_at').datepicker
          format: $('.selectpicker').val() 
          todayBtn: true
          todayHighlight: true
          startDate: $(_this).val()
      else
        $("#warranty_end_at").prop('disabled', true);
    return

  control_datetime_fsr: ->
    start_date = $("#ticket_fsr_work_started_at")
    start_date.data("DateTimePicker").minDate(new Date(start_date.data("mindate")))
    $("#ticket_fsr_work_finished_at").prop("disabled", true)
    $("#ticket_fsr_work_started_at").blur ->
      _this = this
      if $(this).val() != ''
        $("#ticket_fsr_work_finished_at").prop('disabled', false)
        console.log $(this).val()
        $('#ticket_fsr_work_finished_at').data("DateTimePicker").minDate($(this).val())#.maxDate(new Date())
      else
        $("#ticket_fsr_work_finished_at").prop('disabled', true).data("DateTimePicker").destroy();
    return


  update_end_at: (e)->
    this_value = $(e).val()
    end_at = $(e).parents().eq(2).siblings().find(".updateable_end_at")
    end_at.val("")
    end_at.datepicker 'remove'
    end_at.datepicker
      format: "yyyy-mm-dd"
      todayBtn: true
      todayHighlight: true
      startDate: this_value

  tab_trigger: ->
    $('#qa').trigger 'click'
    $("#save_next").click()

  numbersonly: ->
    $('.only_float').keydown (e) ->
      # if String.fromCharCode(e.keyCode).match(/[^0-9\.\b]/g)
      #   return false
      # $(@).regexMask(/^((1?[0-9])|([12][0-4]))(\.[05]?)?$/)
      $(@).regexMask('float-enus')
      return