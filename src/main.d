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
import std.string : strip;

void main() {}

/// Returns the substring of 'str' between 'a' and 'b'.
/// Returns the first match found, or null if no match found.
/// If 'a' or 'b' is null, it matches the beginning or end of 'str'.
string findBetween(string str, string a, string b)
{
	auto aStart = a? str.countUntil(a) : 0;
	if(aStart == -1)
		return null;

	auto aEnd = aStart + a.length;
	auto bStart = b? str[aEnd..$].countUntil(b) + aStart : str.length;
	if(bStart == -1)
		return null;

	return str[aEnd..bStart];
}

// Detect D Compiler //////////////////////////////////////////

struct DCompiler
{
	DCompilerType type;
	string typeRaw;

	string versionHeader   = "unknown";
	string compilerVersion = "unknown";
	string frontEndVersion = "unknown";
	string llvmVersion     = "unknown";
	string gccVersion      = "unknown";

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
			llvmVersion = "none";
			gccVersion = "none";

			// Get compiler help screen
			auto result = execute(["dmd", "--help"]);
			this.fullCompilerOutput = result.output;
			this.fullCompilerStatus = result.status;
			if(result.status != 0) break; // Bail

			// Get versions
			this.versionHeader = this.fullCompilerOutput.findBetween(null, "\n");
			
			this.compilerVersion = this.versionHeader.findBetween("D Compiler v", null);
			this.frontEndVersion = this.compilerVersion;
			break;

		case DCompilerType.ldc2:
			gccVersion = "none";

			// Get compiler help screen
			auto result = execute(["ldc2", "--version"]);
			this.fullCompilerOutput = result.output;
			this.fullCompilerStatus = result.status;
			if(result.status != 0) break; // Bail

			// Get versions
			this.versionHeader = this.fullCompilerOutput.findBetween(null, "Default target");

			this.compilerVersion = this.versionHeader.findBetween("LLVM D compiler (", ")");
			this.frontEndVersion = this.versionHeader.findBetween("DMD v", " ");
			this.llvmVersion     = this.versionHeader.findBetween("and LLVM", null);
			break;

		case DCompilerType.gdc:
			llvmVersion = "none";

			// Get compiler version string
			auto result = execute(["gdc", "--version"]);
			this.fullCompilerOutput = result.output;
			this.fullCompilerStatus = result.status;
			if(result.status != 0) break; // Bail

			// Get versions header
			this.versionHeader = this.fullCompilerOutput.findBetween(null, "\n");

			// Get version number
			result = execute(["gdc", "-dumpversion"]);
			if(result.status == 0)
				this.compilerVersion = result.output.strip();

			// Get front end version
			result = execute(["gdc", "-o", "helper/print_dmdfe", "helper/print_dmdfe.d"]);
			if(result.status != 0) break; // Bail
			result = execute(["helper/print_dmdfe"]);
			if(result.status != 0) break; // Bail
			this.frontEndVersion = result.output ~ ".x";
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
	writeln("dc.versionHeader:   ", dc.versionHeader);
	writeln("dc.compilerVersion: ", dc.compilerVersion);
	writeln("dc.frontEndVersion: ", dc.frontEndVersion);
	writeln("dc.llvmVersion:     ", dc.llvmVersion);
	writeln("dc.gccVersion:      ", dc.gccVersion);
	writeln("---------------------------");
	writeln("dc.fullCompilerStatus: ",  dc.fullCompilerStatus);
	write  ("dc.fullCompilerOutput:\n", dc.fullCompilerOutput);
	writeln("===========================");
}
