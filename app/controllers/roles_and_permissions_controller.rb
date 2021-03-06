class RolesAndPermissionsController < ApplicationController


  before_action :set_organization, only: [:new, :create, :edit, :load_permissions, :update]

  def new
    authorize! :access_owner_org, @organization

    # @rpermissions = Rpermission.all.map { |rpermission| {resource: rpermission.controller_resource, name: rpermission.name, id: rpermission.id, checked: false} }
    @rpermissions = [] #Rpermission.all.group_by{|g| g.controller_resource}.map{|k, v| {resource: k, value: v.map{|rpermission| {resource: rpermission.controller_resource, name: rpermission.name, id: rpermission.id, checked: false}}}}
    respond_to do |format|
      format.html
    end
  end

  def load_permissions
    @role = Role.find params[:role_id]
    # @rpermissions = Rpermission.all.map { |rpermission| {resource: rpermission.controller_resource, name: rpermission.name, id: rpermission.id, checked: "#{'checked' if @role.rpermissions.include?(rpermission)}"} }
    # @rpermissions = @role.rpermissions#.group_by{|g| g.controller_resource}.map{|k, v| {resource: k, value: v.map{|rpermission| {resource: rpermission.controller_resource, name: rpermission.name, id: rpermission.id, checked: "#{'checked' if @role.rpermissions.include?(rpermission)}"}}}}
    @rpermissions = Rpermission.all#.group_by{|g| g.controller_resource}.map{|k, v| {resource: k, value: v.map{|rpermission| {resource: rpermission.controller_resource, name: rpermission.name, id: rpermission.id, checked: "#{'checked' if @role.rpermissions.include?(rpermission)}"}}}}
    respond_to do |format|
      format.json
      format.html
    end
  end

  def create
    new_role_name = params[:role][:name]
    rpermission_ids = params[:rpermissions]
    @role = @organization.roles.build(name: new_role_name)
    authorize! :access_owner_org, @organization

    if @role.save
      @role.rpermission_ids = rpermission_ids
      @role.bpm_module_role_ids = params[:bpm_role]

      flash[:notice] = "Roles and Permissions are successfully assigned"
      redirect_to new_organization_roles_and_permission_url(@organization)
    else
      flash[:error] = "Roles and Permissions are not successfully assigned. Please correct those errors and try again"
      # redirect_to new_organization_roles_and_permission_url(@organization)
      render :new
    end
  end

  def edit
    @role = Role.find params[:id]
    # @rpermissions = Rpermission.all.map { |rpermission| {resource: rpermission.controller_resource, name: rpermission.name, id: rpermission.id, checked: "#{'checked' if @role.rpermissions.include?(rpermission)}"} }
    # @rpermissions = [] #Rpermission.all.group_by{|g| g.controller_resource}.map{|k, v| {resource: k, value: v.map{|rpermission| {resource: rpermission.controller_resource, name: rpermission.name, id: rpermission.id, checked: "#{'checked' if @role.rpermissions.include?(rpermission)}"}}}}
    @rpermissions = Rpermission.all.group_by{|g| g.rpermission_module.try(:name)}.map{|k,v| {system_module: k, value: v.map { |r| {id: r.id, name: r.name, checked: (@role.rpermission_ids.include?(r.id) ? 'checked' : '') } } } }
    
  end

  def update
    @role = Role.find params[:id]
    rpermission_ids = params[:rpermissions]
    authorize! :access_owner_org, @organization

    if @role.update_attribute(:name, params[:role][:name])
      @role.rpermission_ids = rpermission_ids.to_a
      @role.bpm_module_role_ids = params[:bpm_role].to_a

      redirect_to edit_organization_roles_and_permission_url(@organization, @role), notice: "Roles and Permissions are successfully updated."

    else
      redirect_to edit_organization_roles_and_permission_url(@organization, @role), error: "Roles and Permissions are unsuccessfully updated. Please try again."

    end
  end

  def assign_bpm_role
    organization = Organization.find params[:organization_id]
    authorize! :access_owner_org, organization

    @system_role = Role.find params[:system_role] if params[:system_role].present?
    @bpm_role = BpmModuleRole.find params[:bpm_role] if params[:bpm_role].present?

    respond_to do |format|
      if @system_role and @bpm_role and @system_role.bpm_module_roles.blank?
        @system_role.bpm_module_roles << @bpm_role
        flash[:notice] = "Bpm role is successfully assigned."
      else
        flash[:error] = "Bpm role is already assigned. or Please select both system role and bpm role and try again."
      end
      format.html { redirect_to new_organization_roles_and_permission_url(organization)}
    end
  end

  private
    def set_organization
      @organization = Organization.find params[:organization_id]
    end
end
