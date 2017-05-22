module VisualizeUtil

// Rebel/Dependency imports
import lang::ExtendedSyntax;

// Rascal imports
import ParseTree;
import vis::ParseTree;
import vis::Render;

public loc simpleAccountLoc = |project://TestGenerator/specifications/simple_account/Account.ebl|;

public void main() {
	visualiseSpecification(simpleAccountLoc);
}

public void visualiseSpecification(loc location) {
 	Tree t = getParseTree(location);
	render(visParsetree(t));
}

private Tree getParseTree(loc location) {
	Tree t = parse(#Module, simpleAccountLoc);
	//visit (t) {
	//	case "": ;
	//}
	return t;
}