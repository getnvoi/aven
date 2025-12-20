import { application } from "aven/controllers/application";
import { eagerLoadEngineControllersFrom } from "aeno/controllers/loader";

// Load controllers from the standard controllers directory
eagerLoadEngineControllersFrom("aven/controllers", application);

// Load component controllers
eagerLoadEngineControllersFrom("aven/components", application);

// Load UI gem component controllers
eagerLoadEngineControllersFrom("aeno/components", application);
