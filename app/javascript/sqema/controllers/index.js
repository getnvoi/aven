import { application } from "sqema/controllers/application";

// Copied from @hotwired/stimulus-loading
function parseImportmapJson() {
  return JSON.parse(document.querySelector("script[type=importmap]").text)
    .imports;
}

function registerControllerFromPath(path, under, application) {
  // Build Stimulus identifier from import path
  // - For sqema/controllers/**/*_controller we want: sqema--(controllername)
  //   e.g. "sqema/controllers/hello_controller" -> "sqema--hello"
  // - For sqema/components/**/*_controller we want: sqema--(namespace)--(foldername)
  //   e.g. "sqema/components/ui/button/button_controller" -> "sqema--ui--button"
  //   e.g. "sqema/components/app/static/index/controller" -> "sqema--app--static--index"
  const withoutPrefix = path.replace(new RegExp(`^${under}/`), "");

  let base;
  if (under === "sqema/components") {
    // Components: drop the last path segment ("controller" or "*_controller")
    if (withoutPrefix.endsWith("/controller")) {
      base = "sqema/" + withoutPrefix.slice(0, -"/controller".length);
    } else if (/\/[^/]+_controller$/.test(withoutPrefix)) {
      base = "sqema/" + withoutPrefix.replace(/\/[^/]+_controller$/, "");
    } else if (/_controller$/.test(withoutPrefix)) {
      // Fallback for flat files
      base = "sqema/" + withoutPrefix.replace(/_controller$/, "");
    } else {
      // Not a controller path we recognize
      return;
    }
  } else if (under === "sqema/controllers") {
    // Standard controllers: sqema--(controllername)
    base = "sqema/" + withoutPrefix.replace(/_controller$/, "");
  } else {
    return;
  }

  const name = base.replace(/\//g, "--").replace(/_/g, "-");
  import(path)
    .then((module) => {
      if (module.default) {
        application.register(name, module.default);
      }
    })
    .catch((error) => {
      console.error(`Failed to register controller: ${name} (${path})`, error);
    });
}

function eagerLoadControllersFrom(under, application) {
  const paths = Object.keys(parseImportmapJson()).filter((path) =>
    path.match(new RegExp(`^${under}/.+`)),
  );
  paths.forEach((path) => {
    if (path.endsWith("_controller") || path.endsWith("/controller")) {
      registerControllerFromPath(path, under, application);
    }
  });
}

// Load controllers from the standard controllers directory
eagerLoadControllersFrom("sqema/controllers", application);

// Load component controllers
eagerLoadControllersFrom("sqema/components", application);
