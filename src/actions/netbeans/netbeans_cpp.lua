--
-- netbeans_cpp.lua
-- Generate a C/C++ netbeans project.
-- Copyright (c) 2013 Santo Pfingsten
--

	premake.netbeans.makefile = {}
	premake.netbeans.projectfile = {}
	premake.netbeans.configfile = {}
	local netbeans = premake.netbeans
	local makefile = premake.netbeans.makefile
	local projectfile = premake.netbeans.projectfile
	local configfile = premake.netbeans.configfile
	
	local project = premake.project
	local config = premake.config
	local fileconfig = premake.fileconfig
	local tree = premake.tree

---------------------------------------------------------------------------
--
-- Makefile creation
--
---------------------------------------------------------------------------

	function makefile.createcommands(prj, key, text)
		for cfg in project.eachconfig(prj) do
			local commands = cfg[key]
			if #commands > 0 then
				_x('ifeq ($(CND_CONF),%s)', cfg.shortname)
					_p('\t@echo Running %s commands', text)
					_p('\t%s', table.implode(commands, "", "", "\n\t"))
				_p('endif')
			end
		end
	end
	
	function makefile.generate(prj)
		_p('# Environment')
		_p('MKDIR=mkdir')
		_p('CP=cp')
		_p('CCADMIN=CCadmin')
		_p('')
		
		_p('# build')
		_p('build: .build-post')
		_p('')
		_p('.build-pre:')
		makefile.createcommands(prj, 'prebuildcommands', 'pre-build')
		_p('')
		_p('.build-post: .build-impl')
		makefile.createcommands(prj, 'postbuildcommands', 'post-build')
		_p('')

	--fixme: prelink doesn't seem possible ?
	--	makefile.createcommands(prj, 'prelinkcommands', 'pre-link')

		_p('# clean')
		_p('clean: .clean-post')
		_p('')
		_p('.clean-pre:')
		_p('')
		_p('.clean-post: .clean-impl')
		_p('')

		_p('# clobber')
		_p('clobber: .clobber-post')
		_p('')
		_p('.clobber-pre:')
		_p('')
		_p('.clobber-post: .clobber-impl')
		_p('')

		_p('# all')
		_p('all: .all-post')
		_p('')
		_p('.all-pre:')
		_p('')
		_p('.all-post: .all-impl')
		_p('')

		_p('# build tests')
		_p('build-tests: .build-tests-post')
		_p('')
		_p('.build-tests-pre:')
		_p('')
		_p('.build-tests-post: .build-tests-impl')
		_p('')

		_p('# run tests')
		_p('test: .test-post')
		_p('')
		_p('.test-pre: build-tests')
		_p('')
		_p('.test-post: .test-impl')
		_p('')

		_p('# help')
		_p('help: .help-post')
		_p('')
		_p('.help-pre:')
		_p('')
		_p('.help-post: .help-impl')
		_p('')
		
		_p('# include project implementation makefile')
		_p('include nbproject/Makefile-impl.mk')
		_p('')

		_p('# include project make variables')
		_p('include nbproject/Makefile-variables.mk')
	end

---------------------------------------------------------------------------
--
-- Some shared methods
--
---------------------------------------------------------------------------

	function netbeans.rootElements(prj, d, tagname)
		-- Build a source tree without removing the root
		local tr = tree.new(prj.name)
		table.foreachi(prj._.files, function(fcfg)
			local flags
			if fcfg.vpath ~= fcfg.relpath then
				flags = { trim = false }
			end
			local parent = tree.add(tr, path.getdirectory(fcfg.vpath), flags)
			local node = tree.insert(parent, tree.new(path.getname(fcfg.vpath)))
			setmetatable(node, { __index = fcfg })
		end)
		tree.sort(tr)
		
		-- Need more than one child
		while #tr.children == 1 do
			tr = tr.children[1]
			if tr.trim == false then
				break
			end
		end

        -- If there are files inside this folder, use the parent folder
		local numChildren = #tr.children
		for i = 1, numChildren do
            -- Only files have relpath set
			if tr.children[i].relpath then
                tr = tr.parent
                numChildren = 1
                break
			end
		end
		
		for i = 1, numChildren do
			local child = 
			_p(d, '<%s>%s</%s>', tagname, netbeans.escapepath(prj, tr.children[i].path), tagname)
		end
	end
	
	function netbeans.kindToType(kind)
		if kind == "WindowedApp" or kind == "ConsoleApp" then
			return 1
		elseif kind == "StaticLib" then
			return 3
		elseif kind == "SharedLib" then
			return 2
		end
	end

---------------------------------------------------------------------------
--
-- Project file creation
--
---------------------------------------------------------------------------

	function projectfile.generate(prj)
		_p('<?xml version="1.0" encoding="UTF-8"?>')
		_p('<!-- %s projectfile autogenerated by Premake -->', premake.action.current().shortname)
		_p('<project xmlns="http://www.netbeans.org/ns/project/1">')
		_p(1, '<type>org.netbeans.modules.cnd.makeproject</type>')
		_p(1, '<configuration>')
		_p(2, '<data xmlns="http://www.netbeans.org/ns/make-project/1">')
		_p(3, '<name>%s</name>', premake.esc(prj.name))
		_p(3, '<c-extensions>c</c-extensions>')
		_p(3, '<cpp-extensions>cpp</cpp-extensions>')
		_p(3, '<header-extensions>h</header-extensions>')
		_p(3, '<sourceEncoding>UTF-8</sourceEncoding>')
		_p(3, '<make-dep-projects/>')
		_p(3, '<sourceRootList>')
		netbeans.rootElements(prj, 4, 'sourceRootElem')
		_p(3, '</sourceRootList>')
		_p(3, '<confList>')
		for cfg in project.eachconfig(prj) do
			_p(4, '<confElem>')
			_p(5, '<name>%s</name>', premake.esc(cfg.shortname))
			_p(5, '<type>%d</type>', netbeans.kindToType(cfg.kind))
			_p(4, '</confElem>')
		end
		_p(3, '</confList>')
		_p(2, '</data>')
		_p(1, '</configuration>')
		_p('</project>')
	end

---------------------------------------------------------------------------
--
-- Configurations file creation
--
---------------------------------------------------------------------------

	function configfile.generate(prj)
		_p('<?xml version="1.0" encoding="UTF-8"?>')
		_p('<!-- %s project configurations autogenerated by Premake -->', premake.esc(premake.action.current().shortname))
		_p('<configurationDescriptor version="88">')
		_p(1, '<logicalFolder name="root" displayName="root" projectFiles="true" kind="ROOT">')
		_p(2, '<logicalFolder name="sourceFiles" displayName="Source Files" projectFiles="true">')
		
		local tr = project.getsourcetree(prj)
		tree.sort(tr)
		tree.traverse(tr, {
			onbranchenter = function(node, depth)
				if depth > 0 then
					_p(depth + 2, '<logicalFolder name="%s" displayName="%s" projectFiles="true">', premake.esc(node.name), premake.esc(node.name))
				end
			end,
			onbranchexit = function(node, depth)
				if depth > 0 then
					_p(depth + 2, '</logicalFolder>')
				end
			end,
			
			onleaf = function(node, depth)
				_p(depth + 2, '<itemPath>%s</itemPath>', netbeans.escapepath(prj, node.relpath))
			end
		}, true)
		
		_p(2, '</logicalFolder>')
		_p(2, '<logicalFolder name="ExternalFiles" displayName="Important Files" projectFiles="false" kind="IMPORTANT_FILES_FOLDER">')
		_p(3, '<itemPath>Makefile</itemPath>')
		_p(2, '</logicalFolder>')

		_p(1, '</logicalFolder>')
		_p(1, '<sourceRootList>')
		netbeans.rootElements(prj, 2, 'Elem')
		_p(1, '</sourceRootList>')
		_p(1, '<projectmakefile>Makefile</projectmakefile>')
		
		_p(1, '<confs>')
		for cfg in project.eachconfig(prj) do
			configfile.conf(prj, cfg)
		end
		_p(1, '</confs>')
		_p('</configurationDescriptor>')
	end

	function configfile.conf(prj, cfg)
		local toolset = netbeans.gettoolset(cfg)
	
		_p(2, '<conf name="%s" type="%d">', premake.esc(cfg.shortname), netbeans.kindToType(cfg.kind))
		_p(3, '<toolsSet>')
		_p(4, '<remote-sources-mode>LOCAL_SOURCES</remote-sources-mode>')
		_p(4, '<compilerSet>default</compilerSet>')
		_p(4, '<dependencyChecking>true</dependencyChecking>')
		_p(4, '<rebuildPropChanged>false</rebuildPropChanged>')
		_p(3, '</toolsSet>')
		_p(3, '<compileType>')
		
		configfile.confTool(cfg, 'cTool', table.join(toolset.getcppflags(cfg), toolset.getcflags(cfg), cfg.buildoptions))
		configfile.confTool(cfg, 'ccTool', table.join(toolset.getcppflags(cfg), toolset.getcflags(cfg), cfg.buildoptions))
		
		local output = netbeans.escapepath(prj, path.join(cfg.buildtarget.directory, cfg.buildtarget.name))
		if cfg.kind == "StaticLib" then
			_p(4, '<archiverTool>')
			_p(5, '<output>%s</output>', output)
			_p(4, '</archiverTool>')
		else
			_p(4, '<linkerTool>')
			_p(5, '<linkerAddLib>')
			for _, libdir in ipairs(config.getlinks(cfg, "siblings", "directory")) do
				_p(6, '<pElem>%s</pElem>', netbeans.escapepath(prj, libdir))
			end
			_p(5, '</linkerAddLib>')
			_p(5, '<linkerLibItems>')
			local scope = iif(explicit, "all", "system")
			for _, libname in ipairs(config.getlinks(cfg, scope, "fullpath")) do
				_p(6, '<linkerLibLibItem>%s</linkerLibLibItem>', premake.esc(path.getbasename(libname)))
			end
			_p(5, '</linkerLibItems>')
			_p(5, '<commandLine>%s</commandLine>', premake.esc(table.concat(table.join(toolset.getldflags(cfg), cfg.linkoptions), " ")))
			_p(5, '<output>%s</output>', output)
			_p(4, '</linkerTool>')
		end
		_p(3, '</compileType>')

		for _, file in ipairs(prj.files) do
			local tool = 3;
			if path.iscfile(file) then tool = 0
			elseif path.iscppfile(file) then tool = 1
			else tool = 3
			end
			_p(3, '<item path="%s" ex="false" tool="%d" flavor2="0"></item>', netbeans.escapepath(prj, file), tool)
		end
		_p(2, '</conf>')
	end

	function configfile.confTool(cfg, toolName, flags)
		_p(4, '<%s>', toolName)
		if not config.isDebugBuild(cfg) and cfg.flags.ReleaseRuntime then
			_p(5, '<developmentMode>5</developmentMode>')
		end
		_p(5, '<incDir>')
		for _, incdir in ipairs(cfg.includedirs) do
			_p(6, '<pElem>%s</pElem>', netbeans.escapepath(cfg.project, incdir))
		end
		_p(5, '</incDir>')
		_p(5, '<preprocessorList>')
		for _, definename in ipairs(cfg.defines) do
			_p(6, '<Elem>%s</Elem>', premake.esc(definename))
		end
		_p(5, '</preprocessorList>')
		_p(5, '<commandLine>%s</commandLine>', premake.esc(table.concat(flags, " ")))
		_p(4, '</%s>', toolName)
	end
