# desc "Explaining what the task does"
namespace :sqema do
  desc "run tailwind"
  task :tailwind_engine_watch do
    require "tailwindcss-rails"

    command = [
      Tailwindcss::Commands.compile_command.first,
      "-i", Sqema::Engine.root.join("app/assets/stylesheets/sqema/application.tailwind.css").to_s,
      "-o", Sqema::Engine.root.join("app/assets/stylesheets/sqema/tailwind.css").to_s,
      "-w",
      "--content", [
        Sqema::Engine.root.join("app/components/**/*.rb").to_s,
        Sqema::Engine.root.join("app/components/**/*.erb").to_s
      ].join(",")
    ]

    p command
    system(*command)
  end
end
