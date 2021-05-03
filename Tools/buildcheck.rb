#!/usr/bin/env ruby

def run(cmd, &block)
  puts "> #{cmd}"
  if block == nil
    abort "** command failed with error" if !system(cmd)
  else
    IO.popen(cmd, &block)
  end
end

def checkArchs(path, expected)
  archs = nil
  run("lipo -info \"#{path}\"") { |lipo| archs = /re: (.*)/.match(lipo.readline)[1].strip() }
  if (expected.split(" ") - archs.split(" ")).count > 0
    puts "Warning: missing architecture; expected \"#{expected}\", found \"#{archs}\""
  end
  if (archs.split(" ") - expected.split(" ")).count > 0
    puts "Warning: unexpected architecture; expected \"#{expected}\", found \"#{archs}\""
  end
end

def checkAuthority(path, expected)
  authorities = []
  run("codesign -dvv #{path} 2>&1") { |codesign| codesign.readlines
      .map { |line| /Authority=(.*)/.match(line) }
      .select { |match| match != nil }
      .each { |match| authorities.push(match[1])}
  }
  if ! authorities.include? expected
    puts "Warning: missing signing authority; expected \"#{expected}\", found #{authorities}"
  end
end

productdir = ARGV[0]
abort "Error: no product directory specified" if productdir == nil

macosproduct = "#{productdir}/macOS/OCMock.framework"
ioslibproduct = "#{productdir}/iOS library/libocmock.a"
iosproduct = "#{productdir}/iOS/OCMock.framework"
tvosproduct = "#{productdir}/tvOS/OCMock.framework"
watchosproduct = "#{productdir}/watchOS/OCMock.framework"

checkArchs "#{macosproduct}/OCMock", "x86_64 arm64"
checkArchs "#{ioslibproduct}", "x86_64 arm64"
checkArchs "#{iosproduct}/OCMock", "x86_64 arm64"
checkArchs "#{tvosproduct}/OCMock", "x86_64 arm64"
checkArchs "#{watchosproduct}/OCMock", "x86_64 arm64"

authority = "Apple Development: erik@doernenburg.com (FJTF47J852)"

checkAuthority macosproduct, authority
checkAuthority iosproduct, authority
checkAuthority tvosproduct, authority
checkAuthority watchosproduct, authority
