#2014_10_28
window.Users =
  setup: ->
    @username_edit()
    @useremail_edit()
    @userpassword_edit()
    @useraddress_edit()
    @user_profile_upload()
    return

  username_edit: ->
    $("#edit_name_link").mouseover ->
      $.ajax
        type: "GET"
        url: "/users/getusername/1"
        dataType: "json"
        success: (data, textStatus, xhr) ->
          content = {uname : data.user_name}
          Addresses.handlebar_template_render("#username_edit_modal_template", content, "#user_edit_popup_content")
          return
        error: ( xhr, textStatus, errorThrown ) ->
          $("#" + id + " .contentarea").html textStatus
          return

  useremail_edit: ->
    $("#edit_email_link").mouseover ->
      $.ajax
        type: "GET"
        url: "/users/getusername/1"
        dataType: "json"
        success: (data, textStatus, xhr) ->
          source = $("#useremail_edit_modal_template").html()
          template = Handlebars.compile(source)
          content =
            uemail : data.email
          html = template(content)
          $("#user_edit_popup_content").html html
          return
        error: ( xhr, textStatus, errorThrown ) ->
          $("#" + id + " .contentarea").html textStatus
          return 

  userpassword_edit: ->
    $("#edit_password_link").mouseover ->
      $.ajax
        type: "GET"
        url: "/users/getusername/1"
        dataType: "json"
        success: (data, textStatus, xhr) ->
          source = $("#userpw_edit_modal_template").html()
          template = Handlebars.compile(source)
          content =
            uemail : data.email
          html = template(content)
          $("#user_edit_popup_content").html html
          return
        error: ( xhr, textStatus, errorThrown ) ->
          $("#" + id + " .contentarea").html textStatus
          return

  useraddress_edit: ->
      $("#edit_address_link").mouseover ->
        $.ajax
          type: "GET"
          url: "/users/getusername/1"
          dataType: "json"
          success: (data, textStatus, xhr) ->
            source = $("#useraddress_edit_modal_template").html()
            template = Handlebars.compile(source)
            content =
              uemail : data.email
            html = template(content)
            $("#user_edit_popup_content").html html
            return
          error: ( xhr, textStatus, errorThrown ) ->
            $("#" + id + " .contentarea").html textStatus
            return

  initiate_tooltip: ->
    $("a[rel~=tooltip], .has-tooltip").tooltip()


  user_profile_upload: ->
    $("#user_avatar").fileupload
      # url: '/users/profile/temp_save_user_profile_image'
      # type: "POST"
      maxFileSize: 1000000
      dataType: "script"
      autoUpload: false
      add: (e, data) ->
        types = /(\.|\/)(gif|jpe?g|png)$/i
        maxsize = 1024*1024
        file = data.files[0]
        if types.test(file.type) || types.test(file.name)
          if maxsize > file.size
            data.context = $(tmpl('profile_image_upload', file))
            $(".profile_image_wrapper").html(data.context)
            data.submit()
          else
            alert "Your image file is with #{file.size}KB is exceeding than limited size of #{maxsize}KB. Please select other image file not exceeding 1MB"
        else
          alert("#{file.name} is not a gif, jpg, jpeg, or png image file")
        # alert data.files[0]
      progress: (e, data) ->
        if data.context
          progress = parseInt(data.loaded/data.total*100, 10)
          data.context.find(".progress-bar").css("width", progress+"%").html(progress+"%")
          if progress==100
            $("#ajax-loader").addClass("hide");
            # $(".profile_image_wrapper").empty();