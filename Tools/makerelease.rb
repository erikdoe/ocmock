#!/usr/bin/env ruby

load "ReleaseManager.rb"

proj = Project.new("OCMock", "1.24")
proj.svnroot = "http://svn.mulle-kybernetik.com/OCMock/trunk/Source"
proj.uploaddest = "muller.mulle-kybernetik.com:/www/sites/www.mulle-kybernetik.com/htdocs/software/OCMock/Downloads"
proj.uploadcmd = "scp -P 23"           

env = Environment.new()

m = ReleaseManager.new(proj, env, ARGV.index("-d") == nil)
m.createWorkingDirectories
m.checkOutSource
m.buildModules
m.createPackage
m.upload
#m.cleanup


