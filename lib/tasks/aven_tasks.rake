# desc "Explaining what the task does"
namespace :aven do
  desc "run tailwind"
  task :tailwind_engine_watch do
    require "tailwindcss-rails"

    command = [
      Tailwindcss::Commands.compile_command.first,
      "-i", Aven::Engine.root.join("app/assets/stylesheets/aven/application.tailwind.css").to_s,
      "-o", Aven::Engine.root.join("app/assets/stylesheets/aven/tailwind.css").to_s,
      "-w",
      "--content", [
        Aven::Engine.root.join("app/components/**/*.rb").to_s,
        Aven::Engine.root.join("app/components/**/*.erb").to_s
      ].join(",")
    ]

    p command
    system(*command)
  end
end
