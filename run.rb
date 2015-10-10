
$: << File::dirname(File::expand_path(__FILE__))
require "HDLBranch"
require "io/console"

bl = HDLBranch.new

puts "请选择："
puts "1:从上级master 下载跟新"
puts "2:提交代码到上级master"
puts "3:同步下一级slave 分支代码"
puts "4:退出"

while word = gets.chomp
    if word =~ /^[1234]$/
        break
    else
        puts "请输入1-4"
    end
end

case word
when "1"
    puts bl.download
when "2"
    puts bl.commit_up
when "3"
    puts bl.sync_fork
else
    puts "--@--Young--@--"
end

sleep(3)
#puts bl.sync_fork
#puts bl.zip_files_path
#bl.create_zip_bak

#p Dir::entries File::dirname(File::expand_path(__FILE__))
