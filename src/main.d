/+
Deliberately keep all the code in here simple to
minimize chance compiler changes breaking this.
Otherwise, the compiler used will fail to get reported.

In the future, this project should be adjusted to always
run using a single pre-determined compiler, regardless
of the travis-ci environment. That would prevent compiler
changes from breaking this tool, and would improve the
ability of this tool itself to be tested.
+/

import std.stdio;
import std.process;
import std.algorithm : countUntil;

void main() {}

// Detect D Compiler //////////////////////////////////////////

struct DCompiler
{
	DCompilerType type;
	string typeRaw;

	string versionHeader      = "unknown";
	string compilerVersion    = "unknown";
	string dmdFrontEndVersion = "unknown";

	string fullCompilerOutput = "unknown";
	int fullCompilerStatus = -1;

	void detectType()
	{
		this.typeRaw = environment["DC"];
		switch(this.typeRaw)
		{
		case "dmd":  this.type = DCompilerType.dmd;     break;
		case "ldc2": this.type = DCompilerType.ldc2;    break;
		case "gdc":  this.type = DCompilerType.gdc;     break;
		default:     this.type = DCompilerType.unknown; break;
		}
	}

	void detectVersion()
	{
		final switch(this.type)
		{
		case DCompilerType.unknown:
			// Do nothing
			break;

		case DCompilerType.dmd:
			// Get compiler help screen
			auto result = execute(["dmd", "--help"]);
			this.fullCompilerOutput = result.output;
			this.fullCompilerStatus = result.status;
			if(result.status != 0) break; // Bail

			// Get version header
			auto firstNewlineIndex = this.fullCompilerOutput.countUntil("\n");
			if(firstNewlineIndex == -1) break; // Bail
			this.versionHeader = this.fullCompilerOutput[0..firstNewlineIndex];
			
			// Get version number
			auto searchStr = "D Compiler v";
			auto versionIndex = searchStr.length + this.versionHeader.countUntil(searchStr);
			this.compilerVersion = this.versionHeader[versionIndex..$];
			this.dmdFrontEndVersion = this.compilerVersion;
			break;

		case DCompilerType.ldc2:
			// Get compiler help screen
			auto result = execute(["ldc2", "--help"]);
			this.fullCompilerOutput = result.output;
			this.fullCompilerStatus = result.status;
			if(result.status != 0) break; // Bail

			// Get front end version
			result = execute(["ldc2", "-o", "helper/print_dmdfe", "helper/print_dmdfe.d"]);
			if(result.status != 0) break; // Bail
			result = execute(["helper/print_dmdfe"]);
			if(result.status != 0) break; // Bail
			this.dmdFrontEndVersion = result.output ~ ".x";
			break;

		case DCompilerType.gdc:
			// Get compiler version string
			auto result = execute(["gdc", "--version"]);
			this.fullCompilerOutput = result.output;
			this.fullCompilerStatus = result.status;
			if(result.status != 0) break; // Bail

			// Get version header
			auto firstNewlineIndex = this.fullCompilerOutput.countUntil("\n");
			if(firstNewlineIndex == -1) break; // Bail
			this.versionHeader = this.fullCompilerOutput[0..firstNewlineIndex];

			// Get version number
			auto searchStr = ") ";
			auto versionIndex = searchStr.length + this.versionHeader.countUntil(searchStr);
			this.compilerVersion = this.versionHeader[versionIndex..$];

			// Trim datestamp off version number
			auto versionEndIndex = this.compilerVersion.countUntil(" ");
			if(versionEndIndex == -1) break; // Bail
			this.compilerVersion = this.compilerVersion[0..versionEndIndex];

			// Get front end version
			result = execute(["gdc", "-o", "helper/print_dmdfe", "helper/print_dmdfe.d"]);
			if(result.status != 0) break; // Bail
			result = execute(["helper/print_dmdfe"]);
			if(result.status != 0) break; // Bail
			this.dmdFrontEndVersion = result.output ~ ".x";
			break;
		}
	}
}

enum DCompilerType
{
	unknown, dmd, ldc2, gdc
}


DCompiler detectDCompiler()
{
	DCompiler dc;
	dc.detectType();
	dc.detectVersion();
	return dc;
}

// Main //////////////////////////////////////////

unittest
{
	writeln("Running unittest");

	auto dc = detectDCompiler();
	
	writeln("===========================");
	writeln("dc.type:    ", dc.type);
	writeln("dc.typeRaw: ", dc.typeRaw);
	writeln();
	writeln("dc.versionHeader:      ", dc.versionHeader);
	writeln("dc.compilerVersion:    ", dc.compilerVersion);
	writeln("dc.dmdFrontEndVersion: ", dc.dmdFrontEndVersion);
	writeln("---------------------------");
	writeln("dc.fullCompilerStatus: ",  dc.fullCompilerStatus);
	write  ("dc.fullCompilerOutput:\n", dc.fullCompilerOutput);
	writeln("===========================");
}
