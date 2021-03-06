App = Ember.Application.create
  rootElement: "#ember-app"

App.Router = Ember.Router.extend
  rootURL: "/tickets/assign-ticket/"

App.Router.map ->
  @route "groups", {path: "/groups/:ticket_id"}, ->
    @route "new"
  return

# ******** Index *************
# App.ApplicationRoute = Ember.Route.extend
#   showGroupFormBool: false

#   model: ->
#     Ember.$.getJSON('/tickets/load_sbu', {type: "sbu"}).then( (data)-> data.sbus )

# App.ApplicationController = Ember.Controller.extend

#   assignToObserver: Ember.observer "newObj.sbu_id", ->

#     if Ember.isPresent(@get("newObj.sbu_id"))
#       Ember.$.getJSON("/tickets/load_sbu", {type: "sbu", filter_sbu: @get("newObj.sbu_id")}).then (data)=>
#         @set("assignTo", data.sbus)
#         @set "newObj.assign_to", null
#         @set "newObj.subEng", []

#   actions:
#     showGroupForm: ->
#       @toggleProperty "showGroupFormBool"

#       if @get("showGroupFormBool")
#         obj = App.Engineer.create()

#         @set "newObj", obj

#       return

#     saveNewObj: ->
#       Ember.$.post("/tickets/update_assign_engineer_ticket", {assign_eng_params: JSON.stringify(@get("newObj")) }).then (response)=>
#         console.log response

# ******** Index *************

App.Engineer = Ember.Object.extend()
App.SubEngineer = Ember.Object.extend()

App.GroupsRoute = Ember.Route.extend
  queryParams:
    re_assigned:
      refreshModel: true

  model: (params)-> Ember.$.getJSON('/tickets/load_sbu', {type: "ticket", ticket_id: params.ticket_id, re_assigned: params.re_assigned}).then( (data)-> data.ticketEngs )

  actions:
    removeTicketEng: (obj)->
      Ember.$.post("/tickets/remove_eng", { ticket_engineer_id: obj.id }).then( (data)=> @refresh())

  # afterModel: ->
  #   @refresh()
  #   return

App.GroupsController = Ember.Controller.extend
  actions:
    getLatest: ->
      @send("refreshModel")

App.GroupsNewRoute = Ember.Route.extend

  model: ->
    Ember.RSVP.hash
      newObj: App.Engineer.create()
      sbus: Ember.$.getJSON('/tickets/load_sbu', {type: "sbu"}).then( (data)-> data.sbus )

  afterModel: (model, transition)->
    model.newObj.set("channel_no", transition.queryParams.channel_no)
    model.newObj.set("order_no", transition.queryParams.order_no)

App.GroupsNewController = Ember.Controller.extend
  queryParams: ['channel_no', 'order_no', 'ticket_id']

  channel_no: null
  order_no: null
  ticket_id: null
  process_id: null

  assignToObserver: Ember.observer "model.newObj.sbu_id", ->
    if Ember.isPresent(@get("model.newObj.sbu_id"))
      Ember.$.getJSON("/tickets/load_sbu", {type: "sbu", filter_sbu: @get("model.newObj.sbu_id")}).then (data)=>
        @set("assignTo", data.sbus)
        @set "model.newObj.assign_to", null
        @set "model.newObj.subEng", []

  observeOrderNo: Ember.observer "order_no", ->
    if Ember.isPresent(@get("model"))
      @set "model.newObj.order_no", @get("order_no")

  observeGroupNo: Ember.observer "channel_no", ->
    if Ember.isPresent(@get("model"))
      @set "model.newObj.channel_no", @get("channel_no")

  observeTicketId: Ember.observer "ticket_id", ->
    if Ember.isPresent(@get("model"))
      @set "model.newObj.ticket_id", @get("ticket_id")

  observeProcessId: Ember.observer "process_id", ->
    if Ember.isPresent(@get("model"))
      @set "model.newObj.process_id", @get("process_id")

  actions:
    saveNewObj: ->
      Ember.$.post("/tickets/update_assign_engineer_ticket", {assign_eng_params: JSON.stringify(@get("model.newObj")) }).then (response)=>
        @transitionToRoute("groups").router.refresh()


App.NewGroupComponent = Ember.Component.extend
  init: ->
    @_super()
    @set "obj.ticket_id", @get("ticketId")
    @set "obj.process_id", @get("processId")

  actions:
    addSubEng: ->
      parentObj = @get("obj")
      newSubEng = App.SubEngineer.create()

      if Ember.isPresent(parentObj.subEng)
        parentObj.subEng.addObject(newSubEng)

      else
        parentObj.set "subEng", [].addObject(newSubEng)

    removeSubEng: (remObj)->
      @get("obj.subEng").removeObject(remObj)

  disableSaveBtn: Ember.computed "obj.sbu_id", "obj.assign_to", ->
    !Ember.isPresent(@get("obj.sbu_id")) or !Ember.isPresent(@get("obj.assign_to"))

App.GroupListComponent = Ember.Component.extend
  imageNotAvailable: Ember.computed.equal("ticketEng.image", null)

App.SelectBoxComponent = Ember.Component.extend
  tagName: "select"
  classNames: ["form-control"]

  actions:
    selectedValue: (value)->
      console.log "clicked"