require 'Date'
require 'rexml/document'
include REXML

## Project configuration
## use attributes to configure your release

class Project
    def initialize(name, version)
        @name = name
        @version = version
        @basename = name.downcase + "-" + version
        @settings = "INSTALL_PATH=\"/\" COPY_PHASE_STRIP=YES"
    end
    
    attr_accessor :name, :version, :basename, :settings, :svnroot, :uploaddest, :uploadcmd
end


## Environment configuration
## use attributes to configure manager for your environment

class Environment
    def initialize()
        @svn = "/usr/bin/svn"
        @tmpdir = "/tmp/makerelease.#{Process.pid}"
        @sourcedir = tmpdir + "/Source"
        @productdir = tmpdir + "/Products"
        @packagedir = tmpdir
    end
    
    attr_accessor :svn, :tmpdir, :sourcedir, :productdir, :packagedir
end


## Logger (Worker)
## used to print commands that would be run

class Logger
    def chdir(dir)
        puts "** chdir #{dir}"
    end
    
    def write(filename, content)
        content = content[0, 40] + "..." if content.length > 40
        puts "** writing to file #{filename}: #{content}"
    end

    def run(cmd)
        puts "** #{cmd}"
    end

    def makedmg(contentdir, volumename, imagename)
        puts "** creating disk image #{imagename} with contents of #{contentdir}"
    end
end


## Executer (Worker)
## used to actually run commands

class Executer
    def chdir(dir)
        Dir.chdir(dir)
    end

    def write(filename, content)
        f = File.new(filename, "w")
        f.write(content)
        f.close
    end

    def run(cmd)
        system(cmd)
    end
    
    def makedmg(contentdir, volumename, imagename)
        system("hdiutil create -size 4m temp.dmg -layout NONE") 

        disk_id = nil
        IO.popen("hdid -nomount temp.dmg") { |hdid| disk_id = hdid.readline.split[0] }
        system("newfs_hfs -v '#{volumename}' #{disk_id}")
        system("hdiutil eject #{disk_id}")

        IO.popen("hdid temp.dmg") { |hdid| disk_id = hdid.readline.split[0] }
        system("cp -R #{contentdir}/* '/Volumes/#{volumename}'")
        system("hdiutil eject #{disk_id}")

        system("hdiutil convert -format UDZO temp.dmg -o #{imagename} -imagekey zlib-level=9")
        system("hdiutil internet-enable -yes #{imagename}")
        
        system("rm temp.dmg")
    end    
end


## Composite Worker (Worker)
## used to send commands to multiple workers

class CompositeWorker
    def initialize(workers)
        @workers = workers
    end
    
    def chdir(dir)
        @workers.each { |w| w.chdir(dir) }
    end

    def write(filename, content)
        @workers.each { |w| w.write(filename, content) }
    end
    
    def run(cmd)
        @workers.each { |w| w.run(cmd) }
    end

    def makedmg(contentdir, volumename, imagename)
        @workers.each { |w| w.makedmg(contentdir, volumename, imagename) }
    end
end    


## The ReleaseManager class

class ReleaseManager

    def initialize(proj, env, doit)
        @proj = proj
        @env = env
        if(doit)
            @worker = CompositeWorker.new([Logger.new(), Executer.new()])
        else
            @worker = Logger.new()
        end
    end
    
    def createWorkingDirectories
        @worker.run("mkdir #{@env.tmpdir}")
        @worker.run("mkdir #{@env.sourcedir}")
        @worker.run("mkdir #{@env.productdir}")
    end
    
    def checkOutSource
        @worker.chdir(@env.sourcedir)
        @worker.run("#{@env.svn} export #{@proj.svnroot} #{@proj.basename}")
        @worker.run("cp -R #{@env.sourcedir} #{@env.productdir}")
    end

    def buildModules
        @worker.chdir("#{@env.sourcedir}/#{@proj.basename}")
        @worker.run("xcodebuild -project #{@proj.name}.xcodeproj -target #{@proj.name} DSTROOT=#{@env.productdir} #{@proj.settings} install")                                                 
        # need to mv because we're building embedded which doesn't install to DSTROOT
        @worker.run("cp -R build/UninstalledProducts/* #{@env.productdir}")    
    end

    def createPackage
        @worker.chdir(@env.packagedir)  
        @worker.makedmg(@env.productdir, "#{@proj.name} #{@proj.version}", "#{@env.packagedir}/#{@proj.basename}.dmg")
    end
    
    def upload
        @worker.chdir(@env.packagedir)       
        @worker.run("#{@proj.uploadcmd} #{@proj.basename}.dmg #{@proj.uploaddest}")
    end
    
    def cleanup
        @worker.run("chmod -R u+w #{@env.tmpdir}")
        @worker.run("rm -rf #{@env.tmpdir}");
    end
    
end

