import std.algorithm : countUntil;
import std.conv;
import std.process;
import std.stdio;
import std.string : strip;

/// Returns the substring of 'str' between 'a' and 'b'.
/// Returns the first match found, or null if no match found.
/// If 'a' or 'b' is null, it matches the beginning or end of 'str'.
string findBetween(string str, string a, string b)
{
	auto aStart = a? str.countUntil(a) : 0;
	if(aStart == -1)
		return null;

	auto aEnd = aStart + a.length;
	auto bStart = b? str[aEnd..$].countUntil(b) + aEnd : str.length;
	if(bStart == -1)
		return null;

	//if(aEnd < 0 || bStart > str.length || aEnd )
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

/+			this.fullCompilerOutput = "LDC - the LLVM D compiler (0.17.1):
  based on DMD v2.068.2 and LLVM 3.7.1
  Default target: x86_64-unknown-linux-gnu
  Host CPU: ivybridge
  http://dlang.org - http://wiki.dlang.org/LDC
  Registered Targets:
    x86 - 32-bit X86: Pentium-Pro and above
    x86-64 - 64-bit X86: EM64T and AMD64
";+/

			// Get versions
			this.versionHeader = this.fullCompilerOutput.findBetween(null, "Default target").strip();

			this.compilerVersion = this.versionHeader.findBetween("LLVM D compiler (", ")");
			this.frontEndVersion = this.versionHeader.findBetween("DMD v", " ");
			this.llvmVersion     = this.versionHeader.findBetween("and LLVM ", null);
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

int main()
{
	import sdlang;

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

	// Get command for reporting
	auto sdlConfig = parseFile("config.sdl");
	auto reporterCommand = sdlConfig.tags["reporter-command"][0].values[0].get!string;

	// Setup environment vars
	environment["DC_TYPE"]              = dc.type.to!string();
	environment["DC_TYPE_RAW"]          = dc.typeRaw;
	environment["DC_VERSION_HEADER"]    = dc.versionHeader;
	environment["DC_COMPILER_VERSION"]  = dc.compilerVersion;
	environment["DC_FRONT_END_VERSION"] = dc.frontEndVersion;
	environment["DC_LLVM_VERSION"]      = dc.llvmVersion;
	environment["DC_GCC_VERSION"]       = dc.gccVersion;
	environment["DC_HELP_OUTPUT"]       = dc.fullCompilerOutput;
	environment["DC_HELP_STATUS"]       = dc.fullCompilerStatus.to!string();

	// Report results
	writeln("Running: ", reporterCommand);
	auto status = spawnShell(reporterCommand).wait();
	return status;
}
