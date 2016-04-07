import std.array;
static import std.file;
import std.process;
import std.stdio;
import std.uri;

auto vars = [
	"DC_TYPE",
	"DC_VERSION_HEADER",
	"DC_COMPILER_VERSION",
	"DC_FRONT_END_VERSION",
	"DC_LLVM_VERSION",
	"DC_GCC_VERSION",
	"DC_HELP_OUTPUT",
	"DC_HELP_STATUS"
];

int main(string[] args)
{
	writeln("postToHTTPS:");
	foreach(var; vars)
		writeln(var, ": ",	environment[var]);
	writeln("===============================");

	// Build POST data string from envvars
	auto buf = appender!string();
	auto isFirst = true;
	foreach(var; vars ~ "REPORTING_SERVER_PASS")
	{
		if(isFirst)
			isFirst = false;
		else
			buf.put("&");
		
		buf.put(var);
		buf.put("=");
		buf.put(std.uri.encode(environment[var]));
	}
	auto postData = buf.data;
	writeln(postData);
	
	// Send POST
	auto filename = "reporting_post_data.txt";
	std.file.write(filename, postData);
	auto cmd = "curl -f -d @"~filename~" "~args[1];
	writeln("Running: ", cmd);
	//auto result = executeShell(cmd);
	//writeln(result.output);
	//return result.status;
	return spawnShell(cmd).wait();
}
