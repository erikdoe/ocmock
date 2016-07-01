#!/usr/bin/env ruby
   
class Builder

    def initialize
        @env = Environment.new()
        @worker = CompositeWorker.new([Logger.new(), Executer.new()])
    end              
    
    def makeRelease
      createWorkingDirectories
      downloadSource
      copySource
      buildModules
      signFrameworks "erik@doernenburg.com"
      createPackage "ocmock-3.3.1.dmg", "OCMock 3.3.1" 
      sanityCheck
      openPackageDir
    end
    
    def justBuild
      createWorkingDirectories
      downloadSource
      buildModules
      openPackageDir
    end
    
    def createWorkingDirectories
        @worker.run("mkdir -p #{@env.sourcedir}")
        @worker.run("mkdir -p #{@env.productdir}")
        @worker.run("mkdir -p #{@env.packagedir}")
    end
    
    def downloadSource
        @worker.run("git archive master | tar -x -v -C #{@env.sourcedir}")
    end

    def copySource
        @worker.run("cp -R #{@env.sourcedir}/Source #{@env.productdir}")
    end

    def buildModules
        @worker.chdir("#{@env.sourcedir}/Source")
        
        @worker.run("xcodebuild -project OCMock.xcodeproj -target OCMock OBJROOT=#{@env.objroot} SYMROOT=#{@env.symroot}")
        osxproductdir = "#{@env.productdir}/OSX"                                        
        @worker.run("mkdir -p #{osxproductdir}")
        @worker.run("cp -R #{@env.symroot}/Release/OCMock.framework #{osxproductdir}")
        
        @worker.run("xcodebuild -project OCMock.xcodeproj -target OCMockLib -sdk iphoneos9.2 OBJROOT=#{@env.objroot} SYMROOT=#{@env.symroot}")
        @worker.run("xcodebuild -project OCMock.xcodeproj -target OCMockLib -sdk iphonesimulator9.2 OBJROOT=#{@env.objroot} SYMROOT=#{@env.symroot}")
        ioslibproductdir = "#{@env.productdir}/iOS\\ library"                                           
        @worker.run("mkdir -p #{ioslibproductdir}")
        @worker.run("cp -R #{@env.symroot}/Release-iphoneos/OCMock #{ioslibproductdir}")
        @worker.run("lipo -create -output #{ioslibproductdir}/libOCMock.a #{@env.symroot}/Release-iphoneos/libOCMock.a #{@env.symroot}/Release-iphonesimulator/libOCMock.a")
        
        @worker.run("xcodebuild -project OCMock.xcodeproj -target 'OCMock iOS' -sdk iphoneos9.2 OBJROOT=#{@env.objroot} SYMROOT=#{@env.symroot}")
        @worker.run("xcodebuild -project OCMock.xcodeproj -target 'OCMock iOS' -sdk iphonesimulator9.2 OBJROOT=#{@env.objroot} SYMROOT=#{@env.symroot}")
        iosproductdir = "#{@env.productdir}/iOS\\ framework"                                           
        @worker.run("mkdir -p #{iosproductdir}")
        @worker.run("cp -R #{@env.symroot}/Release-iphoneos/OCMock.framework #{iosproductdir}")
        @worker.run("lipo -create -output #{iosproductdir}/OCMock.framework/OCMock #{@env.symroot}/Release-iphoneos/OCMock.framework/OCMock #{@env.symroot}/Release-iphonesimulator/OCMock.framework/OCMock")
 
        @worker.run("xcodebuild -project OCMock.xcodeproj -target 'OCMock tvOS' -sdk appletvos9.1 OBJROOT=#{@env.objroot} SYMROOT=#{@env.symroot}")
        @worker.run("xcodebuild -project OCMock.xcodeproj -target 'OCMock tvOS' -sdk appletvsimulator9.1 OBJROOT=#{@env.objroot} SYMROOT=#{@env.symroot}")
        tvosproductdir = "#{@env.productdir}/tvOS"                                           
        @worker.run("mkdir -p #{tvosproductdir}")
        @worker.run("cp -R #{@env.symroot}/Release-appletvos/OCMock.framework #{tvosproductdir}")
        @worker.run("lipo -create -output #{tvosproductdir}/OCMock.framework/OCMock #{@env.symroot}/Release-appletvos/OCMock.framework/OCMock #{@env.symroot}/Release-appletvsimulator/OCMock.framework/OCMock")
    end
    
    def signFrameworks(identity)
        osxproductdir = "#{@env.productdir}/OSX"                                        
        iosproductdir = "#{@env.productdir}/iOS\\ framework"                                           
        tvosproductdir = "#{@env.productdir}/tvOS"                                           

        @worker.run("codesign -s 'Mac Developer: #{identity}' #{osxproductdir}/OCMock.framework")
        @worker.run("codesign -s 'iPhone Developer: #{identity}' #{iosproductdir}/OCMock.framework")
        @worker.run("codesign -s 'iPhone Developer: #{identity}' #{tvosproductdir}/OCMock.framework")
    end

    def createPackage(packagename, volumename)    
        @worker.chdir(@env.packagedir)  
        @worker.run("hdiutil create -size 5m temp.dmg -layout NONE") 
        disk_id = nil
        @worker.run("hdid -nomount temp.dmg") { |hdid| disk_id = hdid.readline.split[0] }
        @worker.run("newfs_hfs -v '#{volumename}' #{disk_id}")
        @worker.run("hdiutil eject #{disk_id}")
        @worker.run("hdid temp.dmg") { |hdid| disk_id = hdid.readline.split[0] }
        @worker.run("cp -R #{@env.productdir}/* '/Volumes/#{volumename}'")
        @worker.run("hdiutil eject #{disk_id}")
        @worker.run("hdiutil convert -format UDZO temp.dmg -o #{@env.packagedir}/#{packagename} -imagekey zlib-level=9")
        @worker.run("hdiutil internet-enable -yes #{@env.packagedir}/#{packagename}")
        @worker.run("rm temp.dmg")
    end           
    
    def openPackageDir
        @worker.run("open #{@env.packagedir}") 
    end
    
    def sanityCheck
        osxproductdir = "#{@env.productdir}/OSX"                                        
        ioslibproductdir = "#{@env.productdir}/iOS\\ library"                                           
        iosproductdir = "#{@env.productdir}/iOS\\ framework"                                           
        tvosproductdir = "#{@env.productdir}/tvOS"                                           

        @worker.run("lipo -info #{osxproductdir}/OCMock.framework/OCMock")
        @worker.run("lipo -info #{ioslibproductdir}/libOCMock.a")
        @worker.run("lipo -info #{iosproductdir}/OCMock.framework/OCMock")
        @worker.run("lipo -info #{tvosproductdir}/OCMock.framework/OCMock")

        @worker.run("codesign -dvv #{osxproductdir}/OCMock.framework")
        @worker.run("codesign -dvv #{iosproductdir}/OCMock.framework")       
        @worker.run("codesign -dvv #{tvosproductdir}/OCMock.framework")
    end
    
    def upload(packagename, dest)
        @worker.run("scp #{@env.packagedir}/#{packagename} #{dest}")
    end
    
    def cleanup
        @worker.run("chmod -R u+w #{@env.tmpdir}")
        @worker.run("rm -rf #{@env.tmpdir}");
    end
    
end


## Environment
## use attributes to configure manager for your environment

class Environment
    def initialize()
        @tmpdir = "/tmp/ocmock.#{Process.pid}"
        @sourcedir = tmpdir + "/Source"
        @productdir = tmpdir + "/Products"
        @packagedir = tmpdir
        @objroot = tmpdir + '/Build/Intermediates'
        @symroot = tmpdir + '/Build'
    end
    
    attr_accessor :tmpdir, :sourcedir, :productdir, :packagedir, :objroot, :symroot
end


## Logger (Worker)
## prints commands

class Logger
    def chdir(dir)
        puts "## chdir #{dir}"
    end
    
    def run(cmd)
        puts "## #{cmd}"
    end
end


## Executer (Worker)
## actually runs commands

class Executer
    def chdir(dir)
        Dir.chdir(dir)
    end

    def run(cmd, &block)     
        if block == nil
          system(cmd)
        else
          IO.popen(cmd, &block)
        end
    end
end


## Composite Worker (Worker)
## sends commands to multiple workers

class CompositeWorker
    def initialize(workers)
        @workers = workers
    end
    
    def chdir(dir)
        @workers.each { |w| w.chdir(dir) }
    end

    def run(cmd)
         @workers.each { |w| w.run(cmd) }
    end
 
    def run(cmd, &block)
         @workers.each { |w| w.run(cmd, &block) }
    end
end    


if /Tools$/.match(Dir.pwd)
  Dir.chdir("..")
end

if ARGV[0] == '-r' 
  Builder.new.makeRelease
else
  Builder.new.justBuild
end


