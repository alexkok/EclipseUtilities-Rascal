module ProjectsUtil

// Project imports
import javamethods::IDE;

// Rascal imports
import String;
import IO;
import List;
import Set;
import Relation;
import analysis::graphs::Graph;

alias ModData = tuple[str modName, loc location];

private set[loc] updatedModules = {}; // Holds already updated modules, to prevent updating it more than once

private list[loc] projectsToBuild = [	
	|project://rebel-smt/src|
,	|project://rebel-core/src|
,	|project://rebel-web/src|
,	|project://rebel-eclipse/src|
,	|project://ing-rebel-generators/src|
,	|project://TestGenerator/src|
];

public void main() {
	//loc location = |project://rebel-smt/src|;
	//loc location = |project://rebel-core/src|;
	//buildProject(location);
	buildProjects(projectsToBuild);
}

public void buildProject(loc projectLocation) {
	buildProjects([projectLocation]);
}

public void buildProjects(list[loc] projects) {
	updatedModules = {}; // Reset to empty

	list[ModData] moduleDataList = [<getModuleName(l), l> | project <- projects, l <- retrieveRascalFilesRecursive(project)];

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

	println("Done!");
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
	
	//rel[ModData, ModData] relations = {};
	//for (ModData modData <- moduleDataList) {
	//	//println("Module: <modData.modName>");
	//	for (ModData dependency <- getDependencies(modData.location, moduleDataList)) {
	//		relations += <modData, dependency>;
	//		//println(" DP: <dependency.modName>");
	//	}
	//}
	//return relations;
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

private list[loc] retrieveRascalFilesRecursive(loc path) {
	list[loc] files = [];
	for (loc file <- path.ls) {
		if (isDirectory(file)) {
			files += retrieveRascalFilesRecursive(file);
		} else if (endsWith(file.file, ".rsc")) {
			files += file;
		}
	}
	return files;
}

// Unfortunately we need a specific order, thus we cannot use the projects() method from the util::Resources package
// Old implementation 

public void updateAndCompileProjects() {
	for (loc project <- projectsToBuild) {
		updateFiles(project);	
	}
	saveAllEditors(false);
}

// Only update Rascal files
private void updateFiles(loc prLoc) {
	for (loc file <- prLoc.ls) {
		if (isDirectory(file)) {
			updateFiles(file);
		} else if (endsWith(file.file, ".rsc")) {
			updateFile(file);
		}
	}
}

private void updateFile(loc fileLoc) {
	//println("Updating file <fileLoc>");
	str content = readFile(fileLoc);
	// Updating it with the same content works fine
	writeFile(fileLoc, content);
	//touch(fileLoc); // Doesn't work for this purpose
}