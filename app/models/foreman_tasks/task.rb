require 'uuidtools'

module ForemanTasks
  class Task < ActiveRecord::Base

    # TODO missing validation of states

    self.primary_key = :id
    before_create :generate_id

    has_many :locks

    # in fact, the task has only one owner but Rails don't let you to
    # specify has_one relation though has_many relation
    has_many :owners, :through => :locks, :source => :resource, :source_type => 'User'

    scoped_search :on => :id, :complete_value => false
    scoped_search :on => :label, :complete_value => true
    scoped_search :on => :state, :complete_value => true
    scoped_search :on => :result, :complete_value => true
    scoped_search :on => :started_at, :complete_value => false
    scoped_search :in => :locks,  :on => :resource_type, :complete_value => true, :rename => "resource_type", :ext_method => :search_by_generic_resource
    scoped_search :in => :locks,  :on => :resource_id, :complete_value => false, :rename => "resource_id", :ext_method => :search_by_generic_resource
    scoped_search :in => :owners,  :on => :login, :complete_value => true, :rename => "owner.login", :ext_method => :search_by_owner
    scoped_search :in => :owners,  :on => :firstname, :complete_value => true, :rename => "owner.firstname", :ext_method => :search_by_owner

    scope :active, -> {  where('state != ?', :stopped) }
    scope :for_resource,
        (lambda do |resource|
           joins(:locks).where(:"foreman_tasks_locks.resource_id" => resource.id,
                               :"foreman_tasks_locks.resource_type" => resource.class.name)
         end)

    def input
      {}
    end

    def output
      {}
    end

    def owner
      self.owners.first
    end

    def username
      self.owner.try(:login)
    end

    def humanized
      { action: label,
        input:  "",
        output: "" }
    end

    def cli_example
      ""
    end

    # returns true if the task is running or waiting to be run
    def pending
      self.state != 'stopped'
    end

    def self.search_by_generic_resource(key, operator, value)
      key_name = self.connection.quote_column_name(key.sub(/^.*\./,''))
      condition = sanitize_sql_for_conditions(["foreman_tasks_locks.#{key_name} #{operator} ?", value])

      return {:conditions => condition, :joins => :locks }
    end

    def self.search_by_owner(key, operator, value)
      key_name = self.connection.quote_column_name(key.sub(/^.*\./,''))
      joins = <<-JOINS
      INNER JOIN foreman_tasks_locks AS foreman_tasks_locks_owner
                 ON (foreman_tasks_locks_owner.task_id = foreman_tasks_tasks.id AND
                     foreman_tasks_locks_owner.resource_type = 'User' AND
                     foreman_tasks_locks_owner.name = '#{Lock::OWNER_LOCK_NAME}')
      INNER JOIN users
                 ON (users.id = foreman_tasks_locks_owner.resource_id)
      JOINS
      condition = sanitize_sql_for_conditions(["users.#{key_name} #{operator} ?", value])
      return {:conditions => condition, :joins => joins }
    end

    def progress
      case self.state.to_s
      when "running", "paused"
        0.5
      when "stopped"
        1
      else
        0
      end
    end

    protected

    def generate_id
      self.id ||= UUIDTools::UUID.random_create.to_s
    end
  end
end
