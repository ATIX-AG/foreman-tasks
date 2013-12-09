require 'dynflow/web_console'

Foreman::Application.routes.draw do
  namespace :foreman_tasks do
    resources :tasks, :only => :index

    if ForemanTasks.dynflow_initialized?
      dynflow_console = Dynflow::WebConsole.setup do
        before do
          # NG_TODO: propper authentication
          User.current = User.first
        end

        set(:world) { ForemanTasks.world }
      end

      mount dynflow_console => "/dynflow"
    end
  end
end
