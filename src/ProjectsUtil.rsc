module ProjectsUtil

// Project imports
import javamethods::IDE;

// Rascal imports
import String;
import IO;
import List;
import Set;
import Relation;
import util::Resources;
import analysis::graphs::Graph;

alias ModData = tuple[str modName, loc location];

private set[loc] updatedModules = {}; // Holds already updated modules, to prevent updating it more than once

public void main() {
	//loc location = |project://rebel-smt/src|;
	//loc location = |project://rebel-core/src|;
	//buildProject(location);
	buildProjects(projects());
}

public void buildProject(loc projectLocation) {
	buildProjects({projectLocation});
}

public void buildProjects(set[loc] projects) {
	updatedModules = {}; // Reset to empty

	list[ModData] moduleDataList = [<getModuleName(l), l> | proj <- projects, l <- files(proj), endsWith(l.file, ".rsc")];

	// Just modify top ones, save all. Then modify the ons below it, save all.
	rel[ModData, ModData] moduleRelations = determineRelations(moduleDataList);

	//set[ModData] next = buildAndRetrieveNextOnes(top(moduleRelations));
	set[ModData] next = buildAndRetrieveNextOnes(bottom(moduleRelations), moduleRelations);
	
	int depth = 0;
	while (!isEmpty(next)) {
		depth += 1;
		println("Current depth: <depth>");
		next = buildAndRetrieveNextOnes(next, moduleRelations);
	}

	println("Done! Modified files and saved them. Workspace might need some time to build though.");
}

private set[ModData] buildAndRetrieveNextOnes(set[ModData] modsToUpdate, rel[ModData, ModData] moduleRelations) {
	set[ModData] nextToBuild = {};
	for (ModData modData <- modsToUpdate, modData.location notin updatedModules) {
		// Update
		println("Updating: <modData.location>");
		updateFile(modData.location);
		updatedModules += modData.location;
		// Next
		//nextToBuild += successors(moduleRelations, modData);
		nextToBuild += predecessors(moduleRelations, modData);
	}
	saveAllEditors(/* confirm: */ false);
	return nextToBuild;
}

private rel[ModData, ModData] determineRelations(list[ModData] moduleDataList) {
	return {<modData, dependency> | modData <- moduleDataList, dependency <- getDependencies(modData.location, moduleDataList)};
}

private str getModuleName(loc location) {
	for (str line <- readFileLines(location), startsWith(line, "module ")) {
		return substring(line, 7);
	}
}

private list[ModData] getDependencies(loc location, list[ModData] knownDependencies) {
	list[str] imports = [substring(d, 7, size(d)-1) | d <- readFileLines(location), startsWith(d, "import ")];
	return [modData | ModData modData <- knownDependencies, importModName <- imports, modData.modName == importModName];
}

private void updateFile(loc fileLoc) {
	str content = readFile(fileLoc);
	// Updating it with the same content works fine
	writeFile(fileLoc, content);
}