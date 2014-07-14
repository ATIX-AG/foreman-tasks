module ForemanTasks
  class Task::DynflowTask < ForemanTasks::Task

    include Algebrick::TypeCheck

    scope :for_action, ->(action_class) { where(label: action_class.name) }

    def update_from_dynflow(data)
      self.external_id = data[:id]
      self.started_at  = data[:started_at]
      self.ended_at    = data[:ended_at]
      self.state       = data[:state].to_s
      self.result      = data[:result].to_s
      self.label       ||= main_action.class.name
      self.save!
    end

    def resumable?
      execution_plan.state == :paused
    end

    def cancellable_action?(action)
      action.is_a?(::Dynflow::Action::Cancellable)
    end

    def progress
      execution_plan.progress
    end

    def execution_plan
      @execution_plan ||= ForemanTasks.dynflow.world.persistence.load_execution_plan(external_id)
    end

    def input
      main_action.respond_to?(:task_input) && main_action.task_input
    end

    def output
      main_action.respond_to?(:task_output) && main_action.task_output
    end

    def failed_steps
      execution_plan.steps_in_state(:skipped, :skipping, :error)
    end

    def running_steps
      execution_plan.steps_in_state(:running, :suspended)
    end

    def humanized
      { action: get_humanized(:humanized_name),
        input:  get_humanized(:humanized_input),
        output: get_humanized(:humanized_output),
        errors: get_humanized(:humanized_errors) }
    end

    def cli_example
      if main_action.respond_to?(:cli_example)
        main_action.cli_example
      end
    end

    def main_action
      return @main_action if @main_action
      execution_plan.root_plan_step.action execution_plan
    end

    def get_humanized(method)
      Match! method, :humanized_name, :humanized_input, :humanized_output, :humanized_errors
      if main_action.respond_to? method
        begin
          main_action.send method
        rescue => error
          "#{error.message} (#{error.class})\n#{error.backtrace.join "\n"}"
        end
      end
    end
  end
end
