local meta = require("levee.meta")


local function capitalize(s)
	return s:sub(1,1):upper()..s:sub(2)
end


return {
	usage = function()
		return ([[Usage: %s version

Options:
  -b, --build  # print the build version
  -d, --date   # print the date
]]):format(meta.name)
	end,

	parse = function(argv)
		local options = {}
		while argv:more() do
			local opt = argv:option()
			if opt == "build" or opt == "b" then
				options.build = true
			elseif opt == "date" or opt == "d" then
				options.date = true
			else
				argv:exit("version command failed")
			end
		end
		return options
	end,

	run = function(options)
		local version = meta.version
		if options.build then
			print(string.format("%d.%d.%d%s",
				version.major, version.minor, version.patch, version.pre_release))
		end
		if options.date then
			print(version.date.string)
		end
		if not options.build and not options.date then
			print(string.format("%s version %d.%d.%d%s %s",
				capitalize(meta.name),
				version.major,
				version.minor,
				version.patch,
				version.pre_release,
				version.date.string))
			print(string.format("Copyright (c) %d Imgix",
				version.date.year))
		end
	end
}

