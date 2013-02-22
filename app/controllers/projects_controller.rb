class ProjectsController < ApplicationController

  require File.expand_path("../../projects/models/database",__FILE__)
  before_filter :authenticate_user!
  load_and_authorize_resource

  def index

  end

  def new
    @project = Project.new

    # make temp directory and store its path in session
    create_tmp_dir
  end

  def create
    # create project if valid and schemas uploaded

    valid = create_project

    if valid

      @project.transaction do
        @project.save

        @project.create_project_from(session[:tmpdir])
        FileUtils.remove_entry_secure session[:tmpdir]
      end

      flash[:notice] = t 'projects.new.success'
      redirect_to :projects
    else
      flash.now[:error] = t 'projects.new.failure'
      render 'new'
    end
  end

  def show
    @project = Project.find(params[:id])
  end

  def list_arch_ent_records
    @project = Project.find(params[:id])
    @type = Database.get_arch_ent_types(@project.db_path)
    session[:values] = []
  end

  def list_typed_arch_ent_records
    @project = Project.find(params[:id])
    limit = 25
    type = params[:type]
    offset = params[:offset]
    session[:type] = type
    session[:cur_offset] = offset
    session[:prev_offset] = Integer(offset) - Integer(limit)
    session[:next_offset] = Integer(offset) + Integer(limit)
    @uuid = Database.load_arch_entity(@project.db_path,type,limit,offset)
  end

  def edit_arch_ent_records
    @project = Project.find(params[:id])
    uuid = params[:uuid]
    session[:uuid] = uuid
    @attributes = Database.get_arch_entity_attributes(@project.db_path,uuid)
    @vocab_name = {}
    for attribute in @attributes
      @vocab_name[attribute[1]] = Database.get_vocab(@project.db_path,attribute[1])
    end
    puts @vocab_name
  end

  def update_arch_ent_records
    @project = Project.find(params[:id])
    uuid = params[:uuid]
    vocab_id = !params[:project][:vocab_id].blank? ? params[:project][:vocab_id] : nil
    attribute_id = !params[:project][:attribute_id].blank? ? params[:project][:attribute_id] : nil
    measure = !params[:project][:measure].blank? ? params[:project][:measure] : nil
    freetext = !params[:project][:freetext].blank? ? params[:project][:freetext] : nil
    certainty = !params[:project][:certainty].blank? ? params[:project][:certainty] : nil

    Database.update_arch_entity_attribute(@project.db_path,uuid,vocab_id,attribute_id, measure, freetext, certainty)
    @attributes = Database.get_arch_entity_attributes(@project.db_path,uuid)
    @vocab_name = {}
    for attribute in @attributes
      @vocab_name[attribute[1]] = Database.get_vocab(@project.db_path,attribute[1])
    end
    render 'edit_arch_ent_records'
  end

  def delete_arch_ent_records
    @project = Project.find(params[:id])
    uuid = params[:uuid]
    Database.delete_arch_entity(@project.db_path,uuid)
    redirect_to(list_typed_arch_ent_records_path(@project) + "?type=" + session[:type] + "&offset=0")
  end

  def list_rel_records
    @project = Project.find(params[:id])
    @type = Database.get_rel_types(@project.db_path)
    session[:values] = []
  end

  def list_typed_rel_records
    @project = Project.find(params[:id])
    limit = 25
    type=params[:type]
    offset = params[:offset]
    session[:type] = type
    session[:cur_offset] = offset
    session[:prev_offset] = Integer(offset) - Integer(limit)
    session[:next_offset] = Integer(offset) + Integer(limit)
    @relationshipid = Database.load_rel(@project.db_path,type,limit,offset)
  end

  def edit_rel_records
    @project = Project.find(params[:id])
    relationshipid = params[:relationshipid]
    session[:relationshipid] = relationshipid
    @attributes = Database.get_rel_attributes(@project.db_path,relationshipid)
    @vocab_name = {}
    for attribute in @attributes
      @vocab_name[attribute[2]] = Database.get_vocab(@project.db_path,attribute[2])
    end
  end

  def update_rel_records
    @project = Project.find(params[:id])
    relationshipid = params[:relationshipid]
    vocab_id = !params[:project][:vocab_id].blank? ? params[:project][:vocab_id] : nil
    attribute_id = !params[:project][:attribute_id].blank? ? params[:project][:attribute_id] : nil
    freetext = !params[:project][:freetext].blank? ? params[:project][:freetext] : nil
    certainty = !params[:project][:certainty].blank? ? params[:project][:certainty] : nil

    Database.update_rel_attribute(@project.db_path,relationshipid,vocab_id,attribute_id, freetext, certainty)
    @attributes = Database.get_rel_attributes(@project.db_path,relationshipid)
    @vocab_name = {}
    for attribute in @attributes
      @vocab_name[attribute[2]] = Database.get_vocab(@project.db_path,attribute[2])
    end
    render 'edit_rel_records'
  end

  def delete_rel_records
    @project = Project.find(params[:id])
    relationshipid = params[:relationshipid]
    Database.delete_relationship(@project.db_path,relationshipid)
    redirect_to(list_typed_rel_records_path(@project) + "?type=" + session[:type] + "&offset=0")
  end

  def add_entity_to_compare
    puts params[:value]
    if !session[:values]
      session[:values] = []
    end
    if !session[:values].include?(params[:value])
      session[:values].push(params[:value])
    end

    render :nothing => true
  end

  def remove_entity_to_compare
    puts params[:value]
    if(session[:values])
      session[:values].delete(params[:value])
    end
    render :nothing => true
  end

  def compare_arch_ents
    @project = Project.find(params[:id])
    ids = params[:ids]
    session[:values] = []
    @first_arch_ent = Database.get_arch_entity_attributes(@project.db_path, ids[0])
    @second_arch_ent = Database.get_arch_entity_attributes(@project.db_path, ids[1])
  end

  def select_arch_ents
    deleted_id = params[:deleted_id]
    Database.delete_arch_entity(@project.db_path, deleted_id)
    redirect_to(list_typed_arch_ent_records_path(@project) + "?type=" + session[:type] + "&offset=0")
  end

  def compare_rel
    @project = Project.find(params[:id])
    ids = params[:ids]
    session[:values] = []
    @first_rel = Database.get_rel_attributes(@project.db_path, ids[0])
    @second_rel = Database.get_rel_attributes(@project.db_path, ids[1])
  end

  def select_rel
    deleted_id = params[:deleted_id]
    Database.delete_relationship(@project.db_path, deleted_id)
    redirect_to(list_typed_rel_records_path(@project) + "?type=" + session[:type] + "&offset=0")
  end

  def edit_project_setting
    @project = Project.find(params[:id])
    @project_setting = JSON.parse(@project.project_setting)
  end

  def update_project_setting
    if @project.update_attributes(:name => params[:project][:name])
        File.open(@project.dir_path + "/project.settings", 'w') do |file|
        file.write({:name => params[:project][:name], key:@project.key,
                    :season => params[:project][:season],
                    :description => params[:project][:description],
                    :permit_no => params[:project][:permit_no],
                    :permit_holder => params[:project][:permit_holder],
                    :contact_address => params[:project][:contact_address],
                    :participant => params[:project][:participant]
                   }.to_json)
      end
      @project.update_archives
      session[:name] = ""
      flash[:notice] = "Static data updated"
      redirect_to :project
    else
      @project_setting = JSON.parse(@project.project_setting)
      render 'edit_project_setting'
    end
  end

  def update

  end

  private

  def create_tmp_dir
    clear_tmp_dir
    tmpdir = Dir.mktmpdir
    session[:tmpdir] = tmpdir
    session[:data_schema] = false
    session[:ui_schema] = false
    session[:ui_logic] = false
    session[:arch16n] = false
  end

  def clear_tmp_dir
    FileUtils.remove_entry_secure session[:tmpdir] if !session[:tmpdir].blank? and File.directory? session[:tmpdir]
    session[:tmpdir] = nil
  end

  def create_project
    # check if project is valid

    valid = false
    if params[:project]
      @project = Project.new(:name => params[:project][:name], :key => SecureRandom.uuid) if params[:project]
      valid = @project.valid?
      tmpdir = session[:tmpdir]
      File.open(tmpdir + "/project.settings", 'w') do |file|
        file.write({:name => @project.name, key:@project.key,
                    :season => params[:project][:season],
                    :description => params[:project][:description],
                    :permit_no => params[:project][:permit_no],
                    :permit_holder => params[:project][:permit_holder],
                    :contact_address => params[:project][:contact_address],
                    :participant => params[:project][:participant]
                   }.to_json)
      end
    end

    # check if data schema is valid
    if !session[:data_schema]
      error = if params[:project].nil?
                "can't be blank."
              else
                Project.validate_data_schema(params[:project][:data_schema])
              end
      if error
        @project.errors.add(:data_schema, error)
        valid = false
      else
        create_temp_file("data_schema.xml", params[:project][:data_schema])
        session[:data_schema] = true
      end
    end

    # check if ui schema is valid
    if !session[:ui_schema]
      error = if params[:project].nil?
                "can't be blank."
              else
                Project.validate_ui_schema(params[:project][:ui_schema])
              end
      if error
        @project.errors.add(:ui_schema, error)
        valid = false
      else
        create_temp_file("ui_schema.xml", params[:project][:ui_schema])
        session[:ui_schema] = true
      end
    end

    # check if ui logic is valid
    if !session[:ui_logic]
      error = nil
      if params[:project].nil? ||
          params[:project][:ui_logic].nil?
        error = "can't be blank"
      end

      # TODO: what is the content type of the file? should it be checked?

      if error
        @project.errors.add(:ui_logic, error)
        valid = false
      else
        create_temp_file("ui_logic.bsh", params[:project][:ui_logic])
        session[:ui_logic] = true
      end
    end

    # check if arch16n is valid
    if !session[:arch16n]
      error = if !params[:project][:arch16n].nil?
                Project.validate_arch16n(params[:project][:arch16n],params[:project][:name])
              end

      if error
        @project.errors.add(:arch16n, error)
        valid = false
      else
        if !params[:project][:arch16n].nil?
          create_temp_file("faims_"+params[:project][:name].gsub(/\s+/, '_')+".properties", params[:project][:arch16n])
          session[:arch16n] = true
        end
      end
    end
    if !valid
      session[:season] = params[:project][:season]
      session[:description] = params[:project][:description]
      session[:permit_no] = params[:project][:permit_no]
      session[:permit_holder] = params[:project][:permit_holder]
      session[:contact_address] = params[:project][:contact_address]
      session[:participant] = params[:project][:participant]
    else
      session[:season] = ""
      session[:description] = ""
      session[:permit_no] = ""
      session[:permit_holder] = ""
      session[:contact_address] = ""
      session[:participant] = ""
    end
    valid
  end

  def create_temp_file(filename, upload)
    tmpdir = session[:tmpdir]
    #logger.debug tmpdir + "/" + filename
    File.open(upload.tempfile, 'r') do |upload_file|
      File.open(tmpdir + "/" + filename, 'w') do |temp_file|
        temp_file.write(upload_file.read)
      end
    end
  end

end
